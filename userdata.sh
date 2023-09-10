#!/bin/bash
hostnamectl set-hostname ${myserver}
yum update -y
yum install -y httpd
#yum install -y wget
#cd /var/www/html
#wget https://raw.githubusercontent.com/awsdevopsteam/route-53/master/N.virginia_1/index.html
#wget https://raw.githubusercontent.com/awsdevopsteam/route-53/master/N.virginia_1/N.virginia_1.jpg
systemctl start httpd
systemctl enable httpd

