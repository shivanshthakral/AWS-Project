import os
from pathlib import Path

from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")


class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "infra-monitor-local-2026")
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL",
        "mysql+pymysql://infra_user:infra_pass@db:3306/infra_monitor",
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
    AWS_PROFILE = os.environ.get("AWS_PROFILE", "default")
