#!/bin/bash
set -ex
exec > /var/log/user-data.log 2>&1

yum update -y
amazon-linux-extras enable nginx1
yum install -y nginx

systemctl start nginx
systemctl enable nginx