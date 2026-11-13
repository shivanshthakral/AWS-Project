import boto3
from botocore.exceptions import BotoCoreError, ClientError, NoCredentialsError
from flask import Blueprint, jsonify, render_template
from flask_login import login_required

from config import Config


dashboard_bp = Blueprint("dashboard", __name__)


@dashboard_bp.route("/dashboard")
@login_required
def dashboard():
    return render_template("dashboard.html")


@dashboard_bp.route("/api/resources")
@login_required
def get_resources():
    ec2 = boto3.client("ec2", region_name=Config.AWS_REGION)
    instances = []

    try:
        paginator = ec2.get_paginator("describe_instances")
        for page in paginator.paginate():
            for reservation in page.get("Reservations", []):
                for instance in reservation.get("Instances", []):
                    name = ""
                    for tag in instance.get("Tags", []):
                        if tag.get("Key") == "Name":
                            name = tag.get("Value", "")
                            break

                    instances.append(
                        {
                            "id": instance.get("InstanceId"),
                            "name": name,
                            "state": instance.get("State", {}).get("Name", "unknown"),
                            "type": instance.get("InstanceType", "unknown"),
                            "region": Config.AWS_REGION,
                            "public_ip": instance.get("PublicIpAddress", "N/A"),
                        }
                    )
    except (NoCredentialsError, BotoCoreError, ClientError):
        return jsonify([]), 200

    return jsonify(instances), 200
