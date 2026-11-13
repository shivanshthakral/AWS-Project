"""Build temporary Ansible inputs from this deployment's Terraform outputs."""
import json
import os
from pathlib import Path
import sys
from urllib.parse import quote


def main():
    outputs_path, runtime_path, destination_path = map(Path, sys.argv[1:])
    outputs = json.loads(outputs_path.read_text())
    runtime = json.loads((runtime_path / "deploy.tfvars.json").read_text())
    destination_path.mkdir(parents=True, exist_ok=True)
    address = outputs["ec2_public_ip"]["value"]
    endpoint = outputs["rds_endpoint"]["value"]
    password = quote((runtime_path / "db-password").read_text().strip(), safe="")
    variables = {
        "flask_secret_key": (runtime_path / "flask-secret").read_text().strip(),
        "database_url": f"mysql+pymysql://admin:{password}@{endpoint}/infra_monitor",
        "cloudwatch_log_group": f"/{runtime['project_name']}/application",
        "aws_region": runtime["aws_region"],
        "application_archive": str(destination_path.resolve() / "application.tar.gz"),
    }
    variables_path = destination_path / "vars.json"
    variables_path.write_text(json.dumps(variables))
    os.chmod(variables_path, 0o600)
    (destination_path / "hosts.ini").write_text(
        f"[app_servers]\napp1 ansible_host={address} ansible_user=ubuntu\n"
    )


if __name__ == "__main__":
    main()
