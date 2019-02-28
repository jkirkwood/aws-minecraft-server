# AWS Minecraft Server
Deploy a minecraft server on AWS. There are two components — an EC2 server which hosts the server, and a lambda function which, used in conjunction with AWS API Gateway, is used to start and stop the EC2 instance. The EC2 instance will shutdown automatically when no connections are detected for a while to save $.

## Build Steps

### Generate Server AMI

First build the minecraft server AMI using [Packer](https://www.packer.io). Go to the `ami` directory and run:

```
packer build packer.json
```

This AMI will be used to spawn the server EC2 instance.

### Build Lambda Function

Go the the `launcher` directory and execute the `build.sh` script. This will generate a zip archive of the lambda function that will be uploaded to AWS.

## Deploy the Infrastructure

The `terraform` directory contains [Terraform](https://www.terraform.io) code to deploy all the infrastructure necessary to run the Minecraft server system. Make sure you update the `.tfvars` file to suit your installation. Make sure you update the AMI id in this file to what was output by Packer.

Once the configuration variables are set run `terraform apply` to deploy infrastucture to AWS.

