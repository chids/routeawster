variable "topic" {
  type = "string"
}

data "null_data_source" "topic" {
  inputs = {
    name = "${element(split(":", var.topic), 5)}"
  }
}

output "queue" {
  value = "${aws_sqs_queue.queue.arn}"
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${data.null_data_source.topic.outputs["name"]}-dummy-dlq"
  max_message_size          = 2048
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
}

resource "aws_sqs_queue" "queue" {
  name                      = "${data.null_data_source.topic.outputs["name"]}-dummy"
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
        values   = ["${var.topic}"]
    }
  }
}
