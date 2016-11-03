#!/bin/bash

yum -y update
yum install -y postgresql python27-psycopg2
yum install -y httpd24 mod24_wsgi-python27

python -m pip install -U pip setuptools
python -m pip install django psycopg2

# Update Apache conf to support Django
DJANGO_CONF=\
"WSGIScriptAlias / /home/ec2-user/strange-references/strange_references_project/wsgi.py
WSGIDaemonProcess strange-references python-path=/home/ec2-user/strange-references:/usr/local/lib/python2.7/site-packages
WSGIProcessGroup strange-references
<Directory /home/ec2-user/strange-references/strange_references_project>
<Files wsgi.py>
Require all granted
</Files>
</Directory>"

printf "$DJANGO_CONF" > /etc/httpd/conf.d/django.conf

# Pull all deployment scripts from Github and run deploy.sh
cd /home/ec2-user
curl -L -u ryantantiern:b9501e841e0c37fe7a56c96cfedef07938ece540 \
https://github.com/ryantantiern/scenario-week-3/archive/deployment-scripts-ray.zip \
> deployment-scripts.zip
unzip deployment-scripts.zip
rm deployment-scripts.zip
mv scenario-week-3-deployment-scripts-ray/ deployment-scripts/

chmod 755 `find . -type d`
chmod 644 `find . -type f`

cd /home/ec2-user/deployment-scripts

source instance-starter-script/deploy.sh

# Make Python script for GitHub webhook
source github-listener/update_webhooks.py
source github-listener/server.py


# Add startup script to update dns, update webhook, and start apache
cat > /home/ec2-user/boot.sh << 'EOT2'
#!/bin/bash
NEW_PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
sed -i "s/ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = \[ '$NEW_PUBLIC_DNS' \]/g" /home/ec2-user/strange-references/strange_references_project/settings.py

python /home/ec2-user/webhook.py
service httpd start
EOT2
chmod +x /home/ec2-user/boot.sh

printf '\nsource /home/ec2-user/boot.sh\n' >> /etc/rc.local
source /home/ec2-user/boot.sh







