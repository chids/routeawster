variable "topic" {
  type = "string"
}

variable "protocol" {
  type = "string"
}

variable "endpoint" {
  type = "string"
}

variable "entities" {
  type = "list"
}

module "sqs-subscribe" {
  source  = "./sqs"
  queue   = "${var.endpoint}"
  topic   = "${var.topic}"
  enabled = "${var.protocol == "sqs" ? 1 : 0}"
}

module "https-subscribe" {
  source  = "./https"
  url     = "${var.endpoint}"
  topic   = "${var.topic}"
  enabled = "${var.protocol == "https" ? 1 : 0}"
}

/**
 * Hack until Terraform supports SNS subscription filters:
 * https://github.com/terraform-providers/terraform-provider-aws/issues/2554
 */

data "aws_region" "current" {
  current = true
}

resource "null_resource" "filter" {
  provisioner "local-exec" {
    command = "aws --region ${data.aws_region.current.name} sns set-subscription-attributes --subscription-arn '${element(coalescelist(module.sqs-subscribe.arn, module.https-subscribe.arn), 0)}' --attribute-name 'FilterPolicy' --attribute-value '${data.template_file.filter.rendered}'"
  }
  triggers {
    entities = "${join(",", var.entities)}"
  }
}

data "template_file" "filter" {
  template = "${file("${path.module}/filter.tpl")}"
  vars { entities = "${jsonencode(var.entities)}" }
}
