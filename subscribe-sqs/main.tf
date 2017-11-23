variable "service" {}
variable "consumer" {}
variable "topic_arn" {}

resource "aws_sns_topic_subscription" "subscription" {
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = "${var.topic_arn}"
  endpoint             = "${aws_sqs_queue.queue.arn}"
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.service}-${var.consumer}-dlq"
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
}

resource "aws_sqs_queue" "queue" {
  name                      = "${var.service}-${var.consumer}"
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.dlq.arn}\",\"maxReceiveCount\":3}"
}

resource "aws_sqs_queue_policy" "sqs-send" {
  queue_url = "${aws_sqs_queue.queue.id}"
  policy    = "${data.aws_iam_policy_document.sns-publish-to-sqs.json}"
}

data "aws_iam_policy_document" "sns-publish-to-sqs" {
  statement {
    actions = ["sqs:SendMessage"]
    resources = ["${aws_sqs_queue.queue.arn}"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = ["${var.topic_arn}"]
    }
  }
}
