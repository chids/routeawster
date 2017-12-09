variable "service" {
  type = "string"
}

output "queue" {
  value = "${aws_sqs_queue.queue.arn}"
}

data "aws_sns_topic" "topic" {
  name = "${var.service}"
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.service}-dummy-dlq"
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
}

resource "aws_sqs_queue" "queue" {
  name                      = "${var.service}-dummy"
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
        values   = ["${data.aws_sns_topic.topic.arn}"]
    }
  }
}
