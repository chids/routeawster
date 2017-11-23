terraform {
  required_version = ">= 0.10.8"
}

provider "aws" {
  region  = "eu-central-1"
  version = "~> 1.2.0"
}

module "api" {
  source    = "./module"
  topic     = "sample"
  role_arn  = "${aws_iam_role.role.arn}"
  role_name = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
  name               = "routeawster"
  assume_role_policy = "${data.aws_iam_policy_document.assume.json}"
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "attach" {
    role       = "${aws_iam_role.role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
