variable "service" {}

output "id" {
  value = "${aws_api_gateway_rest_api.api.id}"
}

output "root" {
  value = "${aws_api_gateway_resource.root.id}"
}

output "role_name" {
  value = "${aws_iam_role.role.name}"
}

output "role_arn" {
  value = "${aws_iam_role.role.arn}"
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
  name               = "${var.service}"
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
