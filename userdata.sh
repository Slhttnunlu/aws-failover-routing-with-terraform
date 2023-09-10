#!/bin/bash
hostnamectl set-hostname ${myserver}
yum update -y
yum install -y httpd
yum install -y wget
systemctl start httpd
systemctl enable httpd
mkdir s3-bucket-file
cd s3-bucket-file
wget https://raw.githubusercontent.com/Slhttnunlu/aws-failover-routing-with-terraform/main/index.html
aws s3 cp index.html s3://terraform.slhttnunlu.net/
