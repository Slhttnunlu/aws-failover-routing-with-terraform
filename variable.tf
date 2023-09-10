variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "key_name" {
  type = string
  default = "mackeypair"
}

variable "tag" {
  type = string
  default = "nginx-Instance"
}

variable "s3_bucket_name" {
  type = string
  default = "terraform.slhttnunlu.net"
}

variable "server-name" {
  type = string
  default = "nginx-instance"
}

