terraform {
  required_version = ">= 0.10.8"
}

provider "aws" {
  region  = "eu-central-1"
  version = "~> 1.2.0"
}

variable "service" {
  default = "routeawster"
}

module "articles" {
  topic     = "articles"
  api       = "${aws_api_gateway_rest_api.api.id}"
  api_root  = "${aws_api_gateway_resource.root.id}"
  source    = "./topic"
  service   = "${var.service}"
  role_arn  = "${aws_iam_role.role.arn}"
  role_name = "${aws_iam_role.role.name}"
}

module "tags" {
  topic     = "tags"
  api       = "${aws_api_gateway_rest_api.api.id}"
  api_root  = "${aws_api_gateway_resource.root.id}"
  source    = "./topic"
  service   = "${var.service}"
  role_arn  = "${aws_iam_role.role.arn}"
  role_name = "${aws_iam_role.role.name}"
}


resource "aws_api_gateway_rest_api" "api" {
  name = "${var.service}"
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part = "publish"
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
