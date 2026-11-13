param([switch]$DeployAws)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$password = (Get-Content .runtime/jenkins-admin-password -Raw).Trim()
$authorization = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$password"))
$headers = @{ Authorization = "Basic $authorization" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$crumb = Invoke-RestMethod 'http://localhost:18080/crumbIssuer/api/json' -Headers $headers -WebSession $session
$headers[$crumb.crumbRequestField] = $crumb.crumb
$deploy = $DeployAws.IsPresent.ToString().ToLowerInvariant()
$response = Invoke-WebRequest "http://localhost:18080/job/infra-monitor/buildWithParameters?DEPLOY_AWS=$deploy" -Method Post -Headers $headers -WebSession $session -UseBasicParsing
$queueUrl = $response.Headers.Location
Write-Host "Queued Jenkins pipeline: $queueUrl"
do {
    Start-Sleep -Seconds 5
    $queue = Invoke-RestMethod ($queueUrl + 'api/json') -Headers $headers -WebSession $session
    if ($queue.cancelled) { throw 'Jenkins build was cancelled.' }
} until ($queue.executable)
$buildUrl = $queue.executable.url
Write-Host "Running $buildUrl"
do {
    Start-Sleep -Seconds 15
    $build = Invoke-RestMethod ($buildUrl + 'api/json') -Headers $headers -WebSession $session
    $console = Invoke-WebRequest ($buildUrl + 'consoleText') -Headers $headers -WebSession $session -UseBasicParsing
    [IO.File]::WriteAllText((Join-Path $PWD '.runtime/jenkins-build.log'), $console.Content)
    Write-Host "Build $($build.number): $(if ($build.building) { 'running' } else { $build.result })"
} while ($build.building)
Write-Host "Jenkins result: $($build.result) ($buildUrl)"
if ($build.result -ne 'SUCCESS') { throw 'Jenkins pipeline failed; see .runtime/jenkins-build.log.' }
