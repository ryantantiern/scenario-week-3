#!/bin/bash

yum -y update
yum install -y postgresql python27-psycopg2
yum install -y httpd24 mod24_wsgi-python27

python -m pip install -U pip setuptools
python -m pip install django psycopg2

# Update Apache conf to support Django
DJANGO_CONF=\
"WSGIScriptAlias / /home/ec2-user/s-ref/strange-references/strange_references_project/wsgi.py
WSGIDaemonProcess strange-references python-path=/home/ec2-user/s-ref/strange-references:/usr/local/lib/python2.7/site-packages
WSGIProcessGroup strange-references
<Directory /home/ec2-user/s-ref/strange-references/strange_references_project>
<Files wsgi.py>
Require all granted
</Files>
</Directory>"

printf "$DJANGO_CONF" > /etc/httpd/conf.d/django.conf

# Pull all deployment scripts from Github and run deploy.sh
cd /home/ec2-user/
mkdir /home/ec2-user/s-ref/
chmod 755 /home/ec2-user/s-ref
chmod 755 .
cd /home/ec2-user/s-ref

curl -L -u ryantantiern:b9501e841e0c37fe7a56c96cfedef07938ece540 \
https://github.com/ryantantiern/scenario-week-3/archive/deployment-scripts-ray.zip \
> deployment-scripts.zip
unzip deployment-scripts.zip
rm deployment-scripts.zip
mv scenario-week-3-deployment-scripts-ray/ deployment-scripts/

chmod 755 `find . -type d`
chmod 644 `find . -type f`

cd /home/ec2-user/s-ref/deployment-scripts
source instance-starter-script/deploy.sh 2>&1 | tee /home/ec2-user/s-ref/deploy_log.txt
cd /home/ec2-user/s-ref/deployment-scripts

# Put startup script into startup list and run once.
printf '\nsource /home/ec2-user/s-ref/deployment-scripts/instance-starter-script/startup.sh 2>&1 | tee /home/ec2-user/startup_log.txt\n' >> /etc/rc.local
source instance-starter-script/startup.sh 2>&1 | tee /home/ec2-user/startup_log.txt
