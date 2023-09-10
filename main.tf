#primary web page from nginx in instance
#secondary web page index.html from s3

#apache server kuruldu en son user datayi guncelle
#how to copy index.html to s3 bucket?

#s3bucket


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

resource "aws_instance" "tfmyec2" {
  ami = data.aws_ami.amazon-linux-2023.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  user_data = templatefile("userdata.sh", { myserver = var.server-name }) #base64encode
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











