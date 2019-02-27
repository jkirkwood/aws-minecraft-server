variable "aws_region" {
  description = "AWS region to deploy in"
}

variable "server_instance_type" {
  description = "Type of instance to launch for server"
}

variable "server_ami" {
  description = "Id of AMI to use for server"
}

variable "hosted_zone_id" {
  description = "ID of hosted zone minecraft server DNS record should be created in"
}

variable "server_fqdn" {
  description = "Desired FQDN of minecraft server"
}

variable "launcher_fqdn" {
  description = "Desired FQDN of minecraft server launch API"
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket where server info (backups, etc) will be stored"
}

variable "launcher_lambda_filename" {
  description = "Path to launcher lambda function zip archive"
}
