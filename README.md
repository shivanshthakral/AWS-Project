# AWS Infrastructure Monitor

A full-stack Flask application with MySQL authentication and a live AWS EC2 dashboard, provisioned and deployed through Terraform, Ansible, and Jenkins CI/CD.

For the complete configured local stack and Jenkins-driven AWS deployment, see [RUNNING.md](RUNNING.md). Start all local services with `./tools/start.ps1` from PowerShell.

## Repository Structure

- `backend/`: Flask app, models, routes, tests
- `frontend/`: templates and static assets
- `terraform/`: AWS infrastructure as code
- `ansible/`: server configuration and deployment
- `Jenkinsfile`: declarative pipeline
- `docker-compose.yml`: local Flask + MySQL development

## Local Setup

1. Create and activate a virtual environment.
2. Install dependencies:

```bash
cd backend
pip install -r requirements.txt
```

3. Run locally:

```bash
python app.py
```

4. Open http://localhost:5000

Use `backend/.env.example` as the template for `backend/.env`.

## Docker Local Setup

```bash
docker-compose up --build
```

For real EC2 data on the dashboard, make sure your host AWS CLI credentials exist at `~/.aws` and include access to `ec2:DescribeInstances`.

## Key Routes

- `GET /`: Home page
- `GET /login`: Login page
- `POST /login`: Login action
- `POST /logout`: Logout action
- `POST /api/register`: Register user
- `GET /dashboard`: Dashboard page (requires login)
- `GET /api/resources`: Live EC2 JSON data (requires login)

## Terraform Flow

```bash
cd terraform
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

Destroy resources when done:

```bash
terraform destroy
```

## Ansible Flow

1. Update `ansible/inventory/hosts.ini` with EC2 details.
2. Encrypt secrets:

```bash
ansible-vault encrypt ansible/vault.yml
```

3. Run playbook:

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/site.yml --ask-vault-pass
```

Vault workflow details are documented in `ansible/VAULT_WORKFLOW.md`.

## Jenkins Pipeline Stages

1. Checkout
2. Test
3. Terraform Plan
4. Approval
5. Terraform Apply
6. Ansible Deploy

## Screenshots

Add screenshots for home, login, dashboard, Jenkins pipeline, and AWS resources.
