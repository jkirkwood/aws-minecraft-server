# AWS Minecraft Server
Deploy a minecraft server on AWS. There are two components — an EC2 instance which hosts the server, and a lambda function which, used in conjunction with AWS API Gateway, is used to start and stop the EC2 instance.

### Features:
- The EC2 instance will shutdown automatically when no connections are detected for a while to save $.
- The EC2 instance will create a DNS A record in a specified Route 53 hosted zone that points to it's public IP address every time it boots up.
- The latest Minecraft server jar will be downloaded automatically when the server boots up.
- Your Minecraft world will be backed up to the specified S3 bucket every time the server instance shuts down.

## Build Steps

### Generate Server AMI

First build the minecraft server AMI using [Packer](https://www.packer.io). Go to the `ami` directory and run:

```
packer build packer.json
```

This AMI will be used to spawn the server EC2 instance.

**Note:** Before you build you probably want to update the ssh public keys that will be bundled in the AMI. These can be found in `ami/bundle/home/ubuntu/.ssh/authorized_keys`.

### Build Lambda Function

Go the the `launcher` directory and execute the `build.sh` script. This will generate a zip archive of the lambda code that will be uploaded to AWS.

## Deployment

The `terraform` directory contains [Terraform](https://www.terraform.io) code to deploy all the infrastructure necessary to run the Minecraft server system. Make sure you set the variables necessary to run this module. An easy way to do this is to create a `terraform.tfvars` file in the `terraform` directory that looks like this:

```
aws_region = "us-east-1"

s3_bucket_name = "mc-server-bucket"

server_ami = "<ami id output by packer>"

server_instance_type = "t2.micro"

hosted_zone_id = "<hosted zone used by domain server will be hosted under>"

server_fqdn = "mc.example.com"

launcher_fqdn = "mc-launcher.example.com"
```

Once the configuration variables are set run `terraform apply` to deploy infrastucture to AWS.

