variable "topic" {
  type = "string"
}

variable "queue" {
  type = "string"
}

variable "enabled" {
  type = "string"
}

output "arn" {
  value = "${aws_sns_topic_subscription.subscription.*.id}"
}

resource "aws_sns_topic_subscription" "subscription" {
  count                = "${var.enabled}"
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = "${var.topic}"
  endpoint             = "${var.queue}"
}
