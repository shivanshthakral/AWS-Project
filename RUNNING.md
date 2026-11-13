# Running the complete stack

From PowerShell in this folder:

```powershell
./tools/start.ps1
```

Docker Desktop must be running. This starts MySQL with persistent data, the application with Gunicorn, and Jenkins with Python, Terraform, Ansible, and the required pipeline plugins.

| Service | Address | Sign in |
| --- | --- | --- |
| Application | http://localhost:5001 | Create an account on the login page |
| Jenkins | http://localhost:18080 | Username `admin`; password in `.runtime/jenkins-admin-password` |
| MySQL | localhost:3307 | Database `infra_monitor`, user `infra_user`; password in `.env` |

Local ports listen only on this computer. Application, database, and Jenkins restart automatically when Docker starts. Keep `.runtime` and `.env` private and backed up: they contain this installation's credentials and SSH key.

## Jenkins and real AWS deployment

The `infra-monitor` Jenkins job runs backend tests and validates Terraform. Before GitHub is connected it uses the source in this folder. Run a validation-only build with:

```powershell
./tools/run-pipeline.ps1
```

The real deployment uses your AWS CLI default profile in `~/.aws`:

```powershell
./tools/prepare-aws.ps1
./tools/run-pipeline.ps1 -DeployAws
```

## GitHub push to automatic AWS deployment

The configured repository is https://github.com/shivanshthakral/AWS-Project. Authenticate the GitHub CLI using an account with repository admin access, then connect it:

```powershell
gh auth login --hostname github.com --git-protocol https --web --scopes admin:repo_hook
./tools/connect-github.ps1
```

Push this project's source and `Jenkinsfile` to the repository's `main` branch. Jenkins then loads its pipeline from GitHub and checks out the exact commit being built. A signed push webhook travels through a persistent Smee channel to the local Jenkins controller. The relay is a background Docker service; Jenkins checks its HMAC-SHA256 signature. Jenkins and the relay require this computer and Docker to remain running.

Every push to `main` runs checkout, tests, Terraform validation, Terraform plan/apply, Ansible deployment, and an application health check. The AWS deployment parameter defaults to enabled for webhook builds. A failed test or validation stops subsequent deployment stages. Build history and test results are retained in Jenkins.

Verify deliveries under the repository's **Settings > Webhooks > Recent Deliveries** and builds at http://localhost:18080/job/infra-monitor/. The public relay carries webhook metadata; Jenkins's UI remains bound to localhost. After restarting Docker, `./tools/start.ps1` also restarts the configured relay.

The preparation command creates a private, versioned S3 state bucket and a dedicated SSH key, generates passwords, and restricts SSH to your current public IP. Run it again after your public IP changes. The AWS build creates a VPC with public and private subnets, an Ubuntu EC2 application server, an instance role, encrypted RDS MySQL storage, an application load balancer, and a CloudWatch CPU alarm. Ansible copies the tested source, configures Nginx and Gunicorn, and starts the CloudWatch log agent. Jenkins remains on your computer; a separate unused cloud Jenkins server is disabled.

The AWS application URL appears in the successful Jenkins build log. No ACM certificate or custom domain is configured, so this development deployment uses HTTP. AWS resources continue incurring charges until explicitly destroyed; stopping Docker does not stop or delete AWS resources.

Project deployment configuration is in `.runtime/deploy.tfvars.json`, state configuration in `.runtime/backend.tfbackend`, and recent build output in `.runtime/jenkins-build.log`. The old example `dev.tfvars`, original encrypted Ansible vault, and saved `terraform/tfplan` are not used by this setup.

## Status and stopping

```powershell
docker compose ps
docker compose logs --tail 100 web jenkins
docker compose stop
docker compose start
```

`stop` preserves data. Avoid `docker compose down -v` unless you intend to erase the local database and Jenkins configuration.

## Removing this AWS deployment

Review the destroy plan before confirming:

```powershell
$env:TF_VAR_db_password = (Get-Content .runtime/db-password -Raw).Trim()
terraform '-chdir=terraform' init '-backend-config=../.runtime/backend.tfbackend'
terraform '-chdir=terraform' destroy '-var-file=../.runtime/deploy.tfvars.json'
```

This removes the Terraform-managed application infrastructure and database. The preparation script's S3 state bucket and SSH key remain for recovery; remove them separately only when they are no longer needed. The database configuration currently skips a final snapshot on deletion.
