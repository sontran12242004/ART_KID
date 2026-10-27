$ErrorActionPreference = 'Stop'
$backendRoot = Split-Path -Parent $PSScriptRoot
$configurationPath = Join-Path $backendRoot 'src/ArtKids.API/appsettings.Local.json'
$cloudName = (Read-Host 'Cloudinary Cloud name').Trim()
$apiKey = (Read-Host 'Cloudinary API Key').Trim()
$secureSecret = Read-Host 'Cloudinary API Secret (hidden)' -AsSecureString
$secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSecret)
try {
    $apiSecret = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)
    if ($cloudName -notmatch '^[a-zA-Z0-9_-]+$' -or [string]::IsNullOrWhiteSpace($apiKey) -or [string]::IsNullOrWhiteSpace($apiSecret)) {
        throw 'Cloud name, API Key and API Secret are required.'
    }
    if ($apiSecret -match '^[*\s\u2022]+$') {
        throw 'Copy the actual API Secret from Cloudinary, not the masked asterisks.'
    }
    $authentication = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($apiKey + ':' + $apiSecret))
    try {
        $check = Invoke-RestMethod -Method Get -Uri "https://api.cloudinary.com/v1_1/$cloudName/ping" -Headers @{ Authorization = 'Basic ' + $authentication } -TimeoutSec 30
    }
    catch {
        throw 'Cloudinary could not validate these credentials. Check the connection and copy Cloud name, API Key and the actual API Secret from the same product environment. Existing configuration was preserved.'
    }
    if ($check.status -ne 'ok') {
        throw 'Cloudinary did not confirm these credentials. Existing configuration was preserved.'
    }
    Write-Host 'Cloudinary credentials verified.'
    if (Test-Path -LiteralPath $configurationPath) {
        $configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json
    }
    else {
        $configuration = [PSCustomObject]@{}
    }
    $cloudinary = [PSCustomObject]@{
        CloudName = $cloudName
        ApiKey = $apiKey
        ApiSecret = $apiSecret
        MaxVideoBytes = 100000000
        PlaybackSeconds = 7200
    }
    $configuration | Add-Member -NotePropertyName Cloudinary -NotePropertyValue $cloudinary -Force
    $json = $configuration | ConvertTo-Json -Depth 20
    [IO.File]::WriteAllText($configurationPath, $json, [Text.UTF8Encoding]::new($false))
    Write-Host 'Saved Cloudinary settings in the ignored backend appsettings.Local.json. Existing database settings were preserved.'
    & (Join-Path $PSScriptRoot 'restart-api.ps1')
    Write-Host 'API restarted. Reload the frontend and use Tai video & them bai hoc in the instructor workspace.'
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
    $apiSecret = $null
    $authentication = $null
}
