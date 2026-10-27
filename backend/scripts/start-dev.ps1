$ErrorActionPreference = 'Stop'
$artBackendRoot = Split-Path -Parent $PSScriptRoot
Push-Location $artBackendRoot
try {
    dotnet restore ArtKids.slnx
    if ($LASTEXITCODE -ne 0) {
        throw 'Restore failed.'
    }
    dotnet run --project src/ArtKids.API --launch-profile ArtKids.API
}
finally {
    Pop-Location
}
