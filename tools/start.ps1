$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
function New-LocalSecret {
    $buffer = New-Object byte[] 24
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $generator.GetBytes($buffer)
    $generator.Dispose()
    return ([BitConverter]::ToString($buffer)).Replace('-', '').ToLowerInvariant()
}
New-Item -ItemType Directory -Path .runtime -Force | Out-Null
if (!(Test-Path .env)) {
    $awsDirectory = (Join-Path $env:USERPROFILE '.aws').Replace('\', '/')
    @("MYSQL_ROOT_PASSWORD=$(New-LocalSecret)", "MYSQL_PASSWORD=$(New-LocalSecret)", "AWS_CONFIG_DIR=$awsDirectory") | Set-Content .env -Encoding ascii
}
if (!(Test-Path backend/.env)) {
    @("SECRET_KEY=$(New-LocalSecret)", 'AWS_REGION=us-east-1') | Set-Content backend/.env -Encoding ascii
}
if (!(Test-Path .runtime/jenkins-admin-password)) {
    New-LocalSecret | Set-Content .runtime/jenkins-admin-password -Encoding ascii
}
if (Test-Path .runtime/github-connection.json) {
    docker compose --profile github up -d --build --wait --wait-timeout 900
} else {
    docker compose up -d --build --wait --wait-timeout 900
}
if ($LASTEXITCODE -ne 0) { throw 'Docker Compose startup failed. Check docker compose logs.' }
Write-Host 'Application: http://localhost:5001'
Write-Host 'Jenkins: http://localhost:18080 (admin; password in .runtime/jenkins-admin-password)'
