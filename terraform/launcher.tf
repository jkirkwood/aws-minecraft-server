# Use Lambda functions and API gateway to start and stop minecraft server.
# Based on this article: https://learn.hashicorp.com/terraform/aws/lambda-api-gateway

resource "aws_lambda_function" "launcher" {
  function_name = "minecraft-server-launcher"

  filename = "${var.launcher_lambda_filename}"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"

  runtime = "nodejs8.10"

  role = "${aws_iam_role.launcher.arn}"
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "launcher" {
  name = "minecraft-server-launcher"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Allow launcher to access ssm parameters
resource "aws_iam_role_policy" "launcher_ssm" {
  name = "ssm-access"
  role = "${aws_iam_role.launcher.id}"

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

# Allow launcher to save logs
resource "aws_iam_role_policy" "launcher_cloudwatch_logs" {
  name = "cloudwatch-logs-access"
  role = "${aws_iam_role.launcher.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${var.aws_region}:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "launcher_ec2" {
  name = "allow-ec2-control"
  role = "${aws_iam_role.launcher.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances"
      ],
      "Resource": [
        "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.server.id}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_api_gateway_rest_api" "launcher" {
  name        = "minecraft-server-launcher"
  description = "Minecraft server launch API"
}

resource "aws_api_gateway_resource" "launcher" {
  rest_api_id = "${aws_api_gateway_rest_api.launcher.id}"
  parent_id   = "${aws_api_gateway_rest_api.launcher.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "launcher" {
  rest_api_id   = "${aws_api_gateway_rest_api.launcher.id}"
  resource_id   = "${aws_api_gateway_resource.launcher.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "launcher" {
  rest_api_id = "${aws_api_gateway_rest_api.launcher.id}"
  resource_id = "${aws_api_gateway_method.launcher.resource_id}"
  http_method = "${aws_api_gateway_method.launcher.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.launcher.invoke_arn}"
}

resource "aws_api_gateway_method" "launcher_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.launcher.id}"
  resource_id   = "${aws_api_gateway_rest_api.launcher.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "launcher_root" {
  rest_api_id = "${aws_api_gateway_rest_api.launcher.id}"
  resource_id = "${aws_api_gateway_method.launcher_root.resource_id}"
  http_method = "${aws_api_gateway_method.launcher_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.launcher.invoke_arn}"
}

resource "aws_api_gateway_deployment" "launcher" {
  depends_on = [
    "aws_api_gateway_integration.launcher",
    "aws_api_gateway_integration.launcher_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.launcher.id}"
  stage_name  = "main"
}

resource "aws_lambda_permission" "launcher_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.launcher.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* part allows invocation from any method or resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_deployment.launcher.execution_arn}/*/*"
}

# Set up domain name
resource "aws_acm_certificate" "launcher_cert" {
  domain_name       = "${var.launcher_fqdn}"
  validation_method = "DNS"
}

resource "aws_route53_record" "launcher_cert_validation" {
  name    = "${aws_acm_certificate.launcher_cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.launcher_cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.hosted_zone_id}"
  records = ["${aws_acm_certificate.launcher_cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "launcher_cert" {
  certificate_arn         = "${aws_acm_certificate.launcher_cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.launcher_cert_validation.fqdn}"]
}

resource "aws_api_gateway_domain_name" "launcher" {
  domain_name              = "${var.launcher_fqdn}"
  regional_certificate_arn = "${aws_acm_certificate_validation.launcher_cert.certificate_arn}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "launcher" {
  name    = "${aws_api_gateway_domain_name.launcher.domain_name}"
  type    = "A"
  zone_id = "${var.hosted_zone_id}"

  alias {
    evaluate_target_health = true
    name                   = "${aws_api_gateway_domain_name.launcher.regional_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.launcher.regional_zone_id}"
  }
}

resource "aws_api_gateway_base_path_mapping" "launcher" {
  api_id      = "${aws_api_gateway_rest_api.launcher.id}"
  stage_name  = "${aws_api_gateway_deployment.launcher.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.launcher.domain_name}"
}
