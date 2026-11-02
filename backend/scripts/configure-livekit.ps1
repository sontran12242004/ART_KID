param(
    [Parameter(Mandatory = $true)][string]$Url
)
$ErrorActionPreference = 'Stop'
$liveUri = [Uri]$Url
if (-not $liveUri.IsAbsoluteUri -or $liveUri.Scheme -ne 'wss') {
    throw 'Use the wss:// Project URL from LiveKit Cloud.'
}
$liveApiKey = (Read-Host 'LiveKit API Key').Trim()
$liveSecret = Read-Host 'LiveKit API Secret' -AsSecureString
try {
    $liveApiSecret = [System.Net.NetworkCredential]::new('', $liveSecret).Password.Trim()
    if (-not $liveApiKey -or $liveApiSecret.Length -lt 16) {
        throw 'Enter valid LiveKit project credentials.'
    }
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $localPath = Join-Path $repoRoot 'backend/src/ArtKids.API/appsettings.Local.json'
    $settings = if (Test-Path -LiteralPath $localPath) {
        Get-Content -LiteralPath $localPath -Raw | ConvertFrom-Json
    } else { [PSCustomObject]@{} }
    $liveSettings = [ordered]@{ Url = $Url.TrimEnd('/'); ApiKey = $liveApiKey; ApiSecret = $liveApiSecret }
    $settings | Add-Member -MemberType NoteProperty -Name LiveKit -Value $liveSettings -Force
    [IO.File]::WriteAllText($localPath, ($settings | ConvertTo-Json -Depth 40), [Text.UTF8Encoding]::new($false))
    Write-Host 'LiveKit configuration saved locally. Restart the API to apply.'
    Write-Host 'On Render, configure LiveKit__Url, LiveKit__ApiKey and LiveKit__ApiSecret, then redeploy.'
} finally {
    $liveApiSecret = $null
    $liveSecret.Dispose()
}
