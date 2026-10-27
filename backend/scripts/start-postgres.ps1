$ErrorActionPreference = 'Stop'
$backendRoot = Split-Path -Parent $PSScriptRoot
$localRoot = Join-Path $backendRoot '.local'
$control = Join-Path $localRoot 'postgres/pgsql/bin/pg_ctl.exe'
$dataDirectory = Join-Path $localRoot 'postgres-data'
$serverLog = Join-Path $localRoot 'postgres-server.log'
if (-not (Test-Path -LiteralPath $control) -or -not (Test-Path -LiteralPath (Join-Path $dataDirectory 'PG_VERSION'))) {
    throw 'Local PostgreSQL runtime is missing. See docs/postgresql-local.md.'
}
& $control -D $dataDirectory status | Out-Null
if ($LASTEXITCODE -ne 0) {
    $options = @{
        FilePath = $control
        ArgumentList = @('-D', ('"' + $dataDirectory + '"'), '-l', ('"' + $serverLog + '"'), '-w', 'start')
        WindowStyle = 'Hidden'
        PassThru = $true
    }
    $serverProcess = Start-Process @options
    if (-not $serverProcess.WaitForExit(30000)) {
        throw "PostgreSQL startup timed out. See $serverLog"
    }
    $serverProcess.Refresh()
    if ($serverProcess.ExitCode -ne 0) {
        throw "PostgreSQL failed to start. See $serverLog"
    }
}
Write-Host 'PostgreSQL: 127.0.0.1:5432 / artkids'
