terraform {
  required_version = ">= 0.11.1"
}

provider "aws" {
  region  = "eu-central-1"
  version = "~> 1.5.0"
}

provider "null" {
  version = "~> 1.0.0"
}

provider "template" {
  version = "~> 1.0.0"
}

variable "service" {
  default = "routeawster"
}

module "api" {
  source    = "./api"
  service   = "${var.service}"
  entities  = ["tags", "articles"]
}

# Only here to make this demo complete
# Should really be provisioned by the subscribing party and not by routeawster
module "sqs" {
  source  = "./sqs"
  topic   = "${module.api.topic}"
}

module "subscriber-one" {
  source   = "./subscribe"
  topic    = "${module.api.topic}"
  protocol = "sqs"
  endpoint = "${module.sqs.queue}"
  entities = ["articles", "tags"]
}

module "subscriber-two" {
  source   = "./subscribe"
  topic    = "${module.api.topic}"
  protocol = "https"
  endpoint = "https://routeawster-http-subscriber.herokuapp.com/"
  entities = ["tags"]
}
