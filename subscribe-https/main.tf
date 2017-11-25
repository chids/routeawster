variable "endpoint" {}
variable "topic_arn" {}

resource "aws_sns_topic_subscription" "subscribe" {
  topic_arn             	= "${var.topic_arn}"
  protocol              	= "https"
  endpoint              	= "${var.endpoint}"
  raw_message_delivery  	= false
  endpoint_auto_confirms 	= true
}
