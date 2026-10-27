$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$apiRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot 'backend/src/ArtKids.API'))
$listeners = @(Get-NetTCPConnection -LocalPort 5080 -State Listen -ErrorAction SilentlyContinue)
foreach ($listenerId in @($listeners.OwningProcess | Select-Object -Unique)) {
    $apiProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$listenerId"
    $ownsExecutable = $apiProcess.ExecutablePath -and $apiProcess.ExecutablePath.StartsWith($apiRoot, [StringComparison]::OrdinalIgnoreCase)
    $ownsCommand = $apiProcess.CommandLine -and $apiProcess.CommandLine.IndexOf($apiRoot, [StringComparison]::OrdinalIgnoreCase) -ge 0
    if (-not ($ownsExecutable -or $ownsCommand)) {
        throw 'Port 5080 belongs to a different application. That process was left running.'
    }
    Stop-Process -Id $listenerId
}
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    if (-not (Get-NetTCPConnection -LocalPort 5080 -State Listen -ErrorAction SilentlyContinue)) {
        break
    }
    Start-Sleep -Milliseconds 250
}
& (Join-Path $repoRoot 'run-local.ps1') -SkipBuild
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    try {
        $response = Invoke-WebRequest -Uri 'http://localhost:5080/health' -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            Write-Host 'ART KID API is ready.'
            return
        }
    }
    catch {
        Start-Sleep -Milliseconds 500
    }
}
throw 'The API did not become healthy. Check backend/.test-data/local-logs/api.err.log.'
