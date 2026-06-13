#!/bin/bash

dnf update -y

dnf install httpd -y

systemctl start httpd

systemctl enable httpd

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

echo "<h1>Terraform 3 Tier Project</h1>" > /var/www/html/index.html

echo "<h2>$INSTANCE_ID</h2>" >> /var/www/html/index.html
