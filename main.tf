terraform {
  required_version = ">= 0.10.8"
}

provider "aws" {
  region  = "eu-central-1"
  version = "~> 1.2.0"
}

variable "service" {
  default = "routeawster"
}

module "api" {
  source    = "./api"
  service   = "${var.service}"
}

module "articles" {
  source    = "./topic"
  topic     = "articles"
  service   = "${var.service}"
  api_id    = "${module.api.id}"
  api_root  = "${module.api.root}"
  role_arn  = "${module.api.role_arn}"
  role_name = "${module.api.role_name}"
}

module "tags" {
  source    = "./topic"
  topic     = "tags"
  service   = "${var.service}"
  api_id    = "${module.api.id}"
  api_root  = "${module.api.root}"
  role_arn  = "${module.api.role_arn}"
  role_name = "${module.api.role_name}"
}
