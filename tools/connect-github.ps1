param([string]$Repository = 'shivanshthakral/AWS-Project')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$repoData = gh repo view $Repository --json viewerPermission,defaultBranchRef | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Sign in with gh auth login first.' }
if ($repoData.viewerPermission -ne 'ADMIN') { throw 'Repository admin access is required to create the webhook.' }
New-Item -ItemType Directory -Path .runtime -Force | Out-Null
if (!(Test-Path .runtime/webhook-secret)) {
    $buffer = New-Object byte[] 32
    $generator = [Security.Cryptography.RandomNumberGenerator]::Create()
    $generator.GetBytes($buffer)
    $generator.Dispose()
    ([BitConverter]::ToString($buffer)).Replace('-', '').ToLowerInvariant() | Set-Content .runtime/webhook-secret -Encoding ascii
}
if (!(Test-Path .runtime/webhook-url)) {
    $channel = Invoke-WebRequest 'https://smee.io/new' -UseBasicParsing
    $channelUrl = $channel.BaseResponse.ResponseUri.AbsoluteUri
    if ($channelUrl -notmatch '^https://smee\.io/[A-Za-z0-9]+$') { throw 'Could not create the webhook relay channel.' }
    $channelUrl | Set-Content .runtime/webhook-url -Encoding ascii
}
$token = gh auth token
if ($LASTEXITCODE -ne 0) { throw 'Could not read the GitHub authentication token.' }
$token.Trim() | Set-Content .runtime/github-token -Encoding ascii
"https://github.com/$Repository.git" | Set-Content .runtime/github-repository-url -Encoding ascii
$hookUrl = (Get-Content .runtime/webhook-url -Raw).Trim()
$payload = @{
    name = 'web'
    active = $true
    events = @('push')
    config = @{
        url = $hookUrl
        content_type = 'json'
        secret = (Get-Content .runtime/webhook-secret -Raw).Trim()
        insecure_ssl = '0'
    }
} | ConvertTo-Json -Depth 5
$payload | Set-Content .runtime/webhook-request.json -Encoding ascii
$existingHooks = gh api "repos/$Repository/hooks" | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect repository webhooks.' }
$existing = $existingHooks | Where-Object { $_.config.url -eq $hookUrl } | Select-Object -First 1
if ($existing) {
    $hookJson = gh api --method PATCH "repos/$Repository/hooks/$($existing.id)" --input .runtime/webhook-request.json
} else {
    $hookJson = gh api --method POST "repos/$Repository/hooks" --input .runtime/webhook-request.json
}
if ($LASTEXITCODE -ne 0) { throw 'Could not configure the GitHub webhook.' }
$hook = $hookJson | ConvertFrom-Json
@{ repository = $Repository; hook_id = $hook.id; url = $hookUrl } | ConvertTo-Json | Set-Content .runtime/github-connection.json -Encoding ascii
docker compose up -d --build jenkins
if ($LASTEXITCODE -ne 0) { throw 'Jenkins startup failed.' }
docker compose restart jenkins
if ($LASTEXITCODE -ne 0) { throw 'Jenkins restart failed.' }
docker compose --profile github up -d --build --wait --wait-timeout 600 webhook-relay
if ($LASTEXITCODE -ne 0) { throw 'Webhook relay startup failed.' }
Write-Host "Connected https://github.com/$Repository to Jenkins through $hookUrl"
Write-Host "Webhook ID: $($hook.id)"
