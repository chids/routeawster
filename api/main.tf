variable "service" {
  type = "string"
}

variable "entities" {
  type = "list"
}

output "topic" {
  value = "${aws_sns_topic.topic.arn}"
}

data "aws_region" "current" {
  current = true
}

/*
 * Base API setup
 */

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.service}"
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part = "publish"
}

resource "aws_sns_topic" "topic" {
  name = "${var.service}"
}

data "aws_iam_policy_document" "publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = ["${aws_sns_topic.topic.arn}"]
  }
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

resource "aws_iam_policy" "topic-policy" {
    name        = "${var.service}-publish"
    description = "Allow API Gateway to publish to ${var.service}"
    policy      = "${data.aws_iam_policy_document.publish.json}"
}

resource "aws_iam_role" "role" {
  name               = "${var.service}"
  assume_role_policy = "${data.aws_iam_policy_document.assume.json}"
}

resource "aws_iam_role_policy_attachment" "attach-topic-policy" {
    role       = "${aws_iam_role.role.name}"
    policy_arn = "${aws_iam_policy.topic-policy.arn}"
}

resource "aws_iam_role_policy_attachment" "attach-cloudwatch-policy" {
    role       = "${aws_iam_role.role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

/*
 * Per entity APIs below
 */

resource "aws_api_gateway_resource" "publish" {
  count       = "${length(var.entities)}"
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_resource.root.id}"
  path_part   = "${var.entities[count.index]}"
}

resource "aws_api_gateway_method" "endpoint" {
  count       = "${length(var.entities)}"
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${element(aws_api_gateway_resource.publish.*.id, count.index)}"
  http_method = "POST"
  authorization = "NONE"
  api_key_required = true
  depends_on    = ["aws_api_gateway_resource.publish"]
}

resource "aws_api_gateway_integration" "integration" {
  count       = "${length(var.entities)}"
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${element(aws_api_gateway_resource.publish.*.id, count.index)}"
  http_method = "POST"
  type        = "AWS"
  uri         = "arn:aws:apigateway:${data.aws_region.current.name}:sns:action/Publish"
  credentials = "${aws_iam_role.role.arn}"
  integration_http_method = "POST"
  request_parameters = {
    "integration.request.querystring.TopicArn"                                    = "'${aws_sns_topic.topic.arn}'"
    "integration.request.querystring.Message"                                     = "'{}'"
    "integration.request.querystring.MessageAttributes.entry.1.Name"              = "'entity'"
    "integration.request.querystring.MessageAttributes.entry.1.Value.DataType"    = "'String'"
    "integration.request.querystring.MessageAttributes.entry.1.Value.StringValue" = "'${var.entities[count.index]}'"
  }
  depends_on  = ["aws_api_gateway_resource.publish"]
}

resource "aws_api_gateway_method_response" "200" {
  count       = "${length(var.entities)}"
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${element(aws_api_gateway_resource.publish.*.id, count.index)}"
  http_method = "${element(aws_api_gateway_method.endpoint.*.http_method, count.index)}"
  status_code = "200"
  depends_on  = ["aws_api_gateway_method.endpoint", "aws_api_gateway_resource.publish"]
}

resource "aws_api_gateway_integration_response" "response" {
  count       = "${length(var.entities)}"
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${element(aws_api_gateway_resource.publish.*.id, count.index)}"
  http_method = "${element(aws_api_gateway_method.endpoint.*.http_method, count.index)}"
  status_code = "${element(aws_api_gateway_method_response.200.*.status_code, count.index)}"
  depends_on  = ["aws_api_gateway_resource.publish", "aws_api_gateway_method.endpoint", "aws_api_gateway_method_response.200"]
}