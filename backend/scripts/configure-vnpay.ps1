param(
    [Parameter(Mandatory = $true)][string]$PublicApiBaseUrl,
    [string]$FrontendBaseUrl = 'http://localhost:8080'
)
$ErrorActionPreference = 'Stop'
$apiUri = [Uri]$PublicApiBaseUrl
$frontendUri = [Uri]$FrontendBaseUrl
if (-not $apiUri.IsAbsoluteUri -or $apiUri.Scheme -ne 'https' -or $apiUri.Query -or $apiUri.Fragment) {
    throw 'PublicApiBaseUrl must be the public HTTPS backend base URL, without query or fragment.'
}
if (-not $frontendUri.IsAbsoluteUri -or $frontendUri.Scheme -notin @('http', 'https') -or $frontendUri.Query -or $frontendUri.Fragment) {
    throw 'FrontendBaseUrl must be an HTTP(S) base URL, without query or fragment.'
}
$tmnCode = (Read-Host 'VNPay Sandbox TmnCode').Trim()
$secureSecret = Read-Host 'VNPay Sandbox HashSecret' -AsSecureString
$hashSecret = [System.Net.NetworkCredential]::new('', $secureSecret).Password.Trim()
if (-not $tmnCode -or -not $hashSecret -or $tmnCode -match 'REPLACE' -or $hashSecret -match 'REPLACE') {
    throw 'Enter actual sandbox credentials from VNPay.'
}
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$localPath = Join-Path $repoRoot 'backend/src/ArtKids.API/appsettings.Local.json'
$settings = if (Test-Path -LiteralPath $localPath) {
    Get-Content -LiteralPath $localPath -Raw | ConvertFrom-Json
} else { [PSCustomObject]@{} }
$apiBase = $PublicApiBaseUrl.TrimEnd('/')
$vnpay = [ordered]@{
    Enabled = $true
    TmnCode = $tmnCode
    HashSecret = $hashSecret
    PaymentUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html'
    ReturnUrl = "$apiBase/api/v1/payments/vnpay/return"
    FrontendReturnUrl = $FrontendBaseUrl.TrimEnd('/') + '/#/parent/payments/vnpay/result'
}
$settings | Add-Member -MemberType NoteProperty -Name Vnpay -Value $vnpay -Force
[IO.File]::WriteAllText($localPath, ($settings | ConvertTo-Json -Depth 40), [Text.UTF8Encoding]::new($false))
$hashSecret = $null
$secureSecret.Dispose()
Write-Host 'VNPay Sandbox configuration saved to the ignored appsettings.Local.json.'
Write-Host "Register this IPN URL with VNPay: $apiBase/api/v1/payments/vnpay/ipn"
Write-Host "Return URL: $apiBase/api/v1/payments/vnpay/return"
Write-Host 'Restart the API: .\backend\scripts\restart-api.ps1'
