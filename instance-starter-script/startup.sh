#!/bin/bash
# This script runs on instance startup.

# 01: Fetch app from repo

cd /home/ec2-user
curl -L -u blzq-mu:3669b531d5d5ae756280723fd071e0a1640db581 \
https://github.com/ryantantiern/strange-references/archive/hooklistener.zip \
> strange-references.zip
unzip strange-references.zip
rm strange-references.zip
mv strange-references-hooklistener/ strange-references/

chmod 755 `find . -type d`
chmod 644 `find . -type f`

chown -R ec2-user /home/ec2-user

# 02. Update DEBUG setting in settings.py
sed -i "s/DEBUG = True/DEBUG = False/g" /home/ec2-user/strange-references/strange_references_project/settings.py

# 03. Update allowed hosts and start webserver
NEW_PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
sed -i "s/ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = \[ '$NEW_PUBLIC_DNS' \]/g" /home/ec2-user/strange-references/strange_references_project/settings.py

python /home/ec2-user/webhook.py
service httpd start

# 04. Setup GitHub webhook
python /home/ec2-user/deployment-scripts/github-listener/update_webhooks.py

# 05. Start GitHub listener (comment out if using django implementation)
python /home/ec2-user/deployment-scripts/github-listener/server.py