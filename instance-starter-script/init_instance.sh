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

# Make deploy script and run it
cat > /home/ec2-user/deploy.sh << 'EOT0'
#!/bin/bash
cd /home/ec2-user
wget github.com/ryantantiern/strange-references/archive/master.zip
unzip master.zip
rm master.zip
mv strange-references-master/ strange-references/
chmod 755 `find . -type d`
chmod 644 `find . -type f`
EOT0
chmod +x /home/ec2-user/deploy.sh

source /home/ec2-user/deploy.sh


# Update DEBUG setting in settings.py
sed -i "s/DEBUG = True/DEBUG = False/g" /home/ec2-user/strange-references/strange_references_project/settings.py


# Make Python script for GitHub webhook
cat > /home/ec2-user/webhook.py << 'EOT1'
#!/usr/bin/env python

EOT1

# Add startup script to update dns, update webhook, and start apache
cat > /home/ec2-user/boot.sh << 'EOT2'
#!/bin/bash
NEW_PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
sed -i "s/ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = \[ '$NEW_PUBLIC_DNS' \]/g" /home/ec2-user/strange-references/strange_references_project/settings.py

source /home/ec2-user/webhook.py
service httpd start
EOT2
chmod +x /home/ec2-user/boot.sh

printf '\nsource /home/ec2-user/boot.sh\n' >> /etc/rc.local
source /home/ec2-user/boot.sh







