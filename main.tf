data "aws_ami" "amazon-linux-2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_instance" "tf-my-ec2" {
  ami = data.aws_ami.amazon-linux-2023.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  iam_instance_profile   = "EC3-S3-FullAccess"
  user_data = templatefile("userdata.sh", { myserver = var.server-name }) 
  tags = {
    Name = var.tag
  }
}

resource "aws_security_group" "tf-sec-gr" {
  name = "${var.tag}-terraform-sec-grp"
  tags = {
    Name = var.tag
  }

  ingress {
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "tf-fo-bckt" {
  bucket = var.s3_bucket_name
  force_destroy = true
  website {
    index_document = "index.html" 
    error_document = "error.html" 
  }
  tags = {
    Name = "failover-s3-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "tf-s3-public-access" {
  bucket = aws_s3_bucket.tf-fo-bckt.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_access" {
  bucket = aws_s3_bucket.tf-fo-bckt.id
  policy = data.aws_iam_policy_document.my_policy.json
}

data "aws_iam_policy_document" "my_policy" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.tf-fo-bckt.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_route53_record" "primary_record" {
  zone_id = "Z00651972D5VIEQ337ZPG" 
  name    = "terraform.slhttnunlu.net"
  type    = "A" 
  ttl     = "60" 
  
  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "primary"
  records = [aws_instance.tf-my-ec2.public_ip]
  health_check_id = aws_route53_health_check.tf_health_check.id
}

resource "aws_route53_record" "secondary_record" {
  zone_id = "Z00651972D5VIEQ337ZPG" 
  name    = "terraform.slhttnunlu.net" 
  type    = "A" 
  #ttl     = "60"
  
  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary"
  alias {
    name                   = aws_s3_bucket.tf-fo-bckt.website_domain
    zone_id                = "Z3AQBSTGFYJSTF"
    evaluate_target_health = true
  }
}

resource "aws_route53_health_check" "tf_health_check" {
  ip_address           = aws_instance.tf-my-ec2.public_ip
  port                 = 80 
  type                 = "HTTP"
  resource_path        = "/" 
  request_interval     = 30 
  failure_threshold    = 3 
}









