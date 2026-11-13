param([string]$Region = 'us-east-1', [string]$ProjectName = 'infra-monitor-tomar')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Path .runtime -Force | Out-Null
function Invoke-AwsJson {
    param([string[]]$Arguments)
    $result = & aws @Arguments --region $Region --output json
    if ($LASTEXITCODE -ne 0) { throw "AWS command failed: $($Arguments[0]) $($Arguments[1])" }
    if ($result) { return ($result | ConvertFrom-Json) }
}
function New-DeploymentSecret {
    $buffer = New-Object byte[] 16
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $generator.GetBytes($buffer)
    $generator.Dispose()
    return ([BitConverter]::ToString($buffer)).Replace('-', '').ToLowerInvariant()
}
$identity = Invoke-AwsJson -Arguments @('sts', 'get-caller-identity')
$bucket = "$ProjectName-state-$($identity.Account)"
$buckets = Invoke-AwsJson -Arguments @('s3api', 'list-buckets')
if ($bucket -notin $buckets.Buckets.Name) {
    $createArguments = @('s3api', 'create-bucket', '--bucket', $bucket)
    if ($Region -ne 'us-east-1') { $createArguments += @('--create-bucket-configuration', "LocationConstraint=$Region") }
    Invoke-AwsJson -Arguments $createArguments | Out-Null
}
Invoke-AwsJson -Arguments @('s3api', 'put-bucket-versioning', '--bucket', $bucket, '--versioning-configuration', 'Status=Enabled') | Out-Null
Invoke-AwsJson -Arguments @('s3api', 'put-public-access-block', '--bucket', $bucket, '--public-access-block-configuration', 'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true') | Out-Null
$keyName = "$ProjectName-deploy"
if (!(Test-Path .runtime/deploy-key)) {
    $key = Invoke-AwsJson -Arguments @('ec2', 'create-key-pair', '--key-name', $keyName, '--key-type', 'rsa')
    [IO.File]::WriteAllText((Join-Path $PWD '.runtime/deploy-key'), $key.KeyMaterial.Trim() + "`n", [Text.Encoding]::ASCII)
}
foreach ($secret in @('db-password', 'flask-secret')) {
    if (!(Test-Path ".runtime/$secret")) { New-DeploymentSecret | Set-Content ".runtime/$secret" -Encoding ascii }
}
$publicIp = (Invoke-RestMethod 'https://checkip.amazonaws.com').Trim()
if ($publicIp -notmatch '^\d{1,3}(\.\d{1,3}){3}$') { throw 'Could not determine the SSH source IP.' }
@{
    aws_region = $Region
    project_name = $ProjectName
    environment = 'dev'
    owner = $env:USERNAME
    instance_type = 't3.micro'
    key_pair_name = $keyName
    ssh_allowed_cidr = "$publicIp/32"
    alb_certificate_arn = ''
    create_jenkins_server = $false
} | ConvertTo-Json | Set-Content .runtime/deploy.tfvars.json -Encoding ascii
@("bucket = `"$bucket`"", 'key = "infra-monitor/dev/terraform.tfstate"', "region = `"$Region`"", 'encrypt = true', 'use_lockfile = true') | Set-Content .runtime/backend.tfbackend -Encoding ascii
$dbPassword = (Get-Content .runtime/db-password -Raw).Trim()
[IO.File]::WriteAllText((Join-Path $PWD '.runtime/cloud.env'), "export TF_VAR_db_password='$dbPassword'`n", [Text.Encoding]::ASCII)
Write-Host "Prepared AWS deployment for account $($identity.Account), region $Region, state bucket $bucket."
Write-Host 'In Jenkins, run infra-monitor with DEPLOY_AWS checked.'
