provider "aws" {
  region  = "${var.aws_region}"
  version = "~> 1.59"
}

# Create S3 bucket to store backups, etc
resource "aws_s3_bucket" "primary" {
  bucket = "${var.s3_bucket_name}"

  tags = {
    Application = "minecraft-server"
  }
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

# Create VPC with only 1 public subnet
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.55.0"

  name = "minecraft-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["${element(data.aws_availability_zones.available.names, 0)}"]
  public_subnets = ["10.0.1.0/24"]

  tags = {
    Application = "minecraft-server"
  }
}

# These parameters are used by the minecraft server for DNS config, s3, etc
resource "aws_ssm_parameter" "hosted_zone_id" {
  name        = "/minecraft-server/hosted-zone-id"
  description = "Hosted zone id that minecraft server should use"
  type        = "String"
  value       = "${var.hosted_zone_id}"

  tags = {
    Application = "minecraft-server"
  }
}

resource "aws_ssm_parameter" "server_fqdn" {
  name        = "/minecraft-server/server-fqdn"
  description = "FQDN of minecraft server"
  type        = "String"
  value       = "${var.server_fqdn}"

  tags = {
    Application = "minecraft-server"
  }
}

resource "aws_ssm_parameter" "s3_bucket_name" {
  name        = "/minecraft-server/s3-bucket-name"
  description = "S3 bucket that minecraft server should use for backups, etc"
  type        = "String"
  value       = "${var.s3_bucket_name}"

  tags = {
    Application = "minecraft-server"
  }
}

resource "aws_ssm_parameter" "launcher_fqdn" {
  name        = "/minecraft-server/launcher-fqdn"
  description = "FQDN of server launch API"
  type        = "String"
  value       = "${var.launcher_fqdn}"

  tags = {
    Application = "minecraft-server"
  }
}

resource "aws_ssm_parameter" "server_instance_id" {
  name        = "/minecraft-server/server-instance-id"
  description = "Id of minecraft server ec2 instance"
  type        = "String"
  value       = "${aws_instance.server.id}"

  tags = {
    Application = "minecraft-server"
  }
}
