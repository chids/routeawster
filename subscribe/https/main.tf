variable "url" {
  type = "string"
}

variable "topic" {
  type = "string"
}

variable "enabled" {
  type = "string"
}

output "arn" {
  value = "${aws_sns_topic_subscription.subscription.*.arn}"
}

resource "aws_sns_topic_subscription" "subscription" {
  count                   = "${var.enabled}"
  topic_arn               = "${var.topic}"
  protocol                = "https"
  endpoint                = "${var.url}"
  raw_message_delivery    = false
  endpoint_auto_confirms  = true
}
