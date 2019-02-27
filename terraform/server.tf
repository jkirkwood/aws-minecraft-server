# Create minecraft server security group
resource "aws_security_group" "server" {
  name        = "minecraft-server"
  description = "Allow SSH and Minecraft client connections"
  vpc_id      = "${module.vpc.vpc_id}"

  # Allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Minecraft
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Application = "minecraft-server"
  }
}

# Create IAM policy for minecraft server
resource "aws_iam_role" "server" {
  name = "minecraft-server"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
         "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Application = "minecraft-server"
  }
}

# Allow minecraft server to access s3 bucket
resource "aws_iam_role_policy" "server_s3" {
  name = "s3-access"
  role = "${aws_iam_role.server.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${var.s3_bucket_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    }
  ]
}
EOF
}

# Allow minecraft server to access ssm parameters
resource "aws_iam_role_policy" "server_ssm" {
  name = "ssm-access"
  role = "${aws_iam_role.server.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeParameters",
        "ssm:GetParameter"
      ],
      "Resource": "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/minecraft-server/*"
    }
  ]
}
EOF
}

# Allow minecraft server to update dns record
resource "aws_iam_role_policy" "server_r53" {
  name = "route53-access"
  role = "${aws_iam_role.server.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:ChangeResourceRecordSets",
      "Resource": "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "server" {
  name = "minecraft-server"
  role = "${aws_iam_role.server.name}"
}

# Create the minecraft server instance
resource "aws_instance" "server" {
  ami           = "${var.server_ami}"
  instance_type = "${var.server_instance_type}"

  subnet_id                   = "${element(module.vpc.public_subnets, 0)}"
  vpc_security_group_ids      = ["${aws_security_group.server.id}"]
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.server.name}"

  tags = {
    Name        = "minecraft-server"
    Application = "minecraft-server"
  }

  lifecycle = {
    # Server may be shut down, which prevents these properties from being read.
    # This causes Terraform to think they are changing causing the instance
    # to be replaced
    ignore_changes = ["associate_public_ip_address", "id"]
  }
}
