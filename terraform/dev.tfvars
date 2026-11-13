aws_region       = "us-east-1"
project_name     = "infra-monitor"
environment      = "dev"
owner            = "YOUR_NAME"
instance_type    = "t3.micro"
key_pair_name    = "REPLACE_WITH_KEYPAIR"
ssh_allowed_cidr = "203.0.113.10/32"
# Set TF_VAR_db_password in the environment; never commit the password.
alb_certificate_arn = ""
