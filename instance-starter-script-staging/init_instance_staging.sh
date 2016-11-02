#!/bin/bash

yum -y update
yum install -y postgresql
yum install -y httpd24 mod24_wsgi-python27

python -m pip install -U pip setuptools
python -m pip install django

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

cd /home/ec2-user
wget github.com/ryantantiern/strange-references/archive/login-template.zip
unzip login-template.zip
rm login-template.zip
mv strange-references-login-template/ strange-references
chmod 755 `find . -type d`
chmod 644 `find . -type f`

FIRST_PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
sed -i "s/ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = \[ '$FIRST_PUBLIC_DNS' \]/g" /home/ec2-user/strange-references/strange_references_project/settings.py

service httpd start

cat >> /etc/rc.local << 'EOT0'
NEW_PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
sed -i "s/ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = \[ '$NEW_PUBLIC_DNS' \]/g" /home/ec2-user/strange-references/strange_references_project/settings.py
service httpd start
EOT0

cat > /home/ec2-user/strange-references/deploy.sh << 'EOT1'
#!/bin/bash
cd /home/ec2-user
wget github.com/ryantantiern/strange-references/archive/login-template.zip
unzip login-template.zip
rm login-template.zip
mv strange-references-login-template/ strange-references
chmod 755 `find . -type d`
chmod 644 `find . -type f`
EOT1

