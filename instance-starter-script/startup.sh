#!/bin/bash
# This script runs on instance startup.

# 01. Update allowed hosts and start webserver
NEW_PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
sed -i "s/ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = \[ '$NEW_PUBLIC_DNS' \]/g" /home/ec2-user/strange-references/strange_references_project/settings.py

service httpd start

# 02. Setup GitHub webhook
python /home/ec2-user/deployment-scripts/github-listener/update_webhooks.py 2>&1 | tee /home/ec2-user/webhook_log.txt

# 03. Start GitHub listener (comment out if using django implementation)
python /home/ec2-user/deployment-scripts/github-listener/server.py &