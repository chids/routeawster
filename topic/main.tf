variable "api_id" {}
variable "api_root" {}
variable "topic" {}
variable "service" {}
variable "role_arn" {}
variable "role_name" {}

resource "aws_sns_topic" "topic" {
  name = "${var.service}-${var.topic}"
}

data "aws_iam_policy_document" "publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = ["${aws_sns_topic.topic.arn}"]
  }
}

resource "aws_iam_policy" "topic-policy" {
    name        = "${var.service}-publish-${var.topic}"
    description = "Allow API Gateway to publish to ${var.topic}"
    policy      = "${data.aws_iam_policy_document.publish.json}"
}

resource "aws_iam_role_policy_attachment" "attach-topic-policy" {
    role       = "${var.role_name}"
    policy_arn = "${aws_iam_policy.topic-policy.arn}"
}

resource "aws_api_gateway_resource" "publish" {
  rest_api_id = "${var.api_id}"
  parent_id = "${var.api_root}"
  path_part = "${var.topic}"
}

resource "aws_api_gateway_method" "endpoint" {
  rest_api_id = "${var.api_id}"
  resource_id = "${aws_api_gateway_resource.publish.id}"
  http_method = "POST"
  authorization = "NONE"
  api_key_required = true
  request_parameters = {
    "method.request.header.referer" = true
    "method.request.header.x-event" = true
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = "${var.api_id}"
  resource_id = "${aws_api_gateway_resource.publish.id}"
  http_method = "${aws_api_gateway_method.endpoint.http_method}"
  type        = "AWS"
  uri         = "arn:aws:apigateway:eu-central-1:sns:action/Publish"
  credentials = "${var.role_arn}"
  integration_http_method = "POST"
  request_parameters = {
    "integration.request.querystring.TopicArn"                                    = "'${aws_sns_topic.topic.arn}'"
    "integration.request.querystring.Message"                                     = "'dummy'"
    "integration.request.querystring.MessageAttributes.entry.1.Name"              = "'url'"
    "integration.request.querystring.MessageAttributes.entry.1.Value.DataType"    = "'String'"
    "integration.request.querystring.MessageAttributes.entry.1.Value.StringValue" = "method.request.header.referer"
    "integration.request.querystring.MessageAttributes.entry.2.Name"              = "'type'"
    "integration.request.querystring.MessageAttributes.entry.2.Value.DataType"    = "'String'"
    "integration.request.querystring.MessageAttributes.entry.2.Value.StringValue" = "method.request.header.x-event"
  }
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${var.api_id}"
  resource_id = "${aws_api_gateway_resource.publish.id}"
  http_method = "${aws_api_gateway_method.endpoint.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "response" {
  rest_api_id = "${var.api_id}"
  resource_id = "${aws_api_gateway_resource.publish.id}"
  http_method = "${aws_api_gateway_method.endpoint.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
}
