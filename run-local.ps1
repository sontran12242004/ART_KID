param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$app = Join-Path $repo 'apps/artkids_app'
$api = Join-Path $repo 'backend/src/ArtKids.API'
$logs = Join-Path $repo 'backend/.test-data/local-logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$localPostgres = Join-Path $repo 'backend/.local/postgres-connection.json'
if (Test-Path -LiteralPath $localPostgres) {
    & (Join-Path $repo 'backend/scripts/start-postgres.ps1')
}
if (-not (Test-Path -LiteralPath (Join-Path $app 'env/dev.env'))) {
    Copy-Item -LiteralPath (Join-Path $app 'env/dev.env.example') -Destination (Join-Path $app 'env/dev.env')
}
if (-not $SkipBuild) {
    Push-Location $app
    try {
        & flutter pub get
        if ($LASTEXITCODE -ne 0) {
            throw 'Flutter package restore failed.'
        }
        & flutter build web --no-web-resources-cdn --no-wasm-dry-run --dart-define=FLAVOR=dev
        if ($LASTEXITCODE -ne 0) {
            throw 'Flutter web build failed.'
        }
    }
    finally {
        Pop-Location
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $app 'build/web/index.html'))) {
    throw 'Build web first, or run without -SkipBuild.'
}
if (-not (Get-NetTCPConnection -LocalPort 5080 -State Listen -ErrorAction SilentlyContinue)) {
    $previousEnvironment = $env:ASPNETCORE_ENVIRONMENT
    try {
        $env:ASPNETCORE_ENVIRONMENT = 'Development'
        $apiArguments = @('run', '--no-launch-profile', '--urls', 'http://localhost:5080')
        if ($SkipBuild) {
            $apiArguments += '--no-build'
        }
        $apiProcessOptions = @{
            FilePath = 'dotnet'
            ArgumentList = $apiArguments
            WorkingDirectory = $api
            WindowStyle = 'Hidden'
            RedirectStandardOutput = Join-Path $logs 'api.out.log'
            RedirectStandardError = Join-Path $logs 'api.err.log'
        }
        Start-Process @apiProcessOptions | Out-Null
    }
    finally {
        $env:ASPNETCORE_ENVIRONMENT = $previousEnvironment
    }
}
if (-not (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue)) {
    $webProcessOptions = @{
        FilePath = 'python'
        ArgumentList = @('-m', 'http.server', '8080', '--bind', '127.0.0.1', '--directory', 'build/web')
        WorkingDirectory = $app
        WindowStyle = 'Hidden'
        RedirectStandardOutput = Join-Path $logs 'web.out.log'
        RedirectStandardError = Join-Path $logs 'web.err.log'
    }
    Start-Process @webProcessOptions | Out-Null
}
Write-Host 'Frontend: http://localhost:8080/#/parent/login'
Write-Host 'API / Swagger: http://localhost:5080/swagger'
Write-Host 'The API uses the database provider in appsettings.Local.json (PostgreSQL locally).'
Write-Host "Logs: $logs"
