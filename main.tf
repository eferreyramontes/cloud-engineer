provider "aws" {
  region = "eu-west-2"
}

variable "tags" {
  type = map(string)
  default = {
    Owner : "Emmanuel Montes",
    Project : "Cloud Engineer"
  }
}