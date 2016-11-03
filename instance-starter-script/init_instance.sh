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

Alias /static/ /var/www/html/static/
<Directory /var/www/html/static/>
Require all granted
</Directory>

<Directory /home/ec2-user/s-ref/strange-references/strange_references_project>
<Files wsgi.py>
Require all granted
</Files>
</Directory>"

printf "$DJANGO_CONF" > /etc/httpd/conf.d/django.conf

cd /home/ec2-user/
mkdir /home/ec2-user/s-ref/
chmod 755 /home/ec2-user/s-ref
chmod 755 .

# Set deploy mode
cat > /home/ec2-user/s-ref/deploy_type.env << 'EOT2'
production
EOT2
chmod a+r /home/ec2-user/s-ref/deploy_type.env

# Make deploy script and run it
cat > /home/ec2-user/s-ref/deploy.sh << 'EOT0'
#!/bin/bash
cd /home/ec2-user/s-ref/
rm -rf strange-references

echo "--- IN PRODUCTION ---"
curl -L -u blzq-mu:3669b531d5d5ae756280723fd071e0a1640db581 \
https://github.com/ryantantiern/strange-references/archive/master.zip \
> strange-references.zip


unzip strange-references.zip
rm strange-references.zip
mv strange-references-master/ strange-references/

cd /home/ec2-user/s-ref/strange-references/
chmod 755 `find . -type d`
chmod 644 `find . -type f`
cd /home/ec2-user/s-ref/
chown -R apache /home/ec2-user/s-ref/strange-references/

NEW_PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
sed -i "s/ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = \[ '$NEW_PUBLIC_DNS' \]/g" /home/ec2-user/s-ref/strange-references/strange_references_project/settings.py

python /home/ec2-user/s-ref/strange-references/manage.py collectstatic --no-input
EOT0

chmod a+x /home/ec2-user/s-ref/deploy.sh
source /home/ec2-user/s-ref/deploy.sh
chown apache /home/ec2-user/s-ref/deploy.sh
chown -R apache /home/ec2-user/s-ref/

# Update DEBUG setting in settings.py
sed -i "s/DEBUG = True/DEBUG = False/g" /home/ec2-user/s-ref/strange-references/strange_references_project/settings.py


# Make Python script for GitHub webhook
cat > /home/ec2-user/s-ref/webhook.py << 'EOT1'
#!/usr/bin/env python
# This script retrieves the current AWS public DNS address via the AWS CLI and communicates with GitHub to set up webhooks.
import subprocess
import json
import time
import urllib2, base64

# Config
AWS_INSTANCE_NAME = "ScenarioStaging"
GITHUB_TOKEN = "b9501e841e0c37fe7a56c96cfedef07938ece540"
GITHUB_USERNAME = "ryantantiern"
GITHUB_REPO = "strange-references"
WEBHOOK_SECRET = "strange1"
LISTENER_LOCATION = "/hook"
GITHUB_WEBHOOKS_API = "https://api.github.com/repos/%s/%s/hooks" % (GITHUB_USERNAME, GITHUB_REPO)
REMOVE_ALL_EXISTING_WEBHOOKS = False

# Utility Functions
def generate_auth(request):
    base64string = base64.b64encode('%s:%s' % (GITHUB_USERNAME, GITHUB_TOKEN))
    request.add_header("Authorization", "Basic %s" % base64string)

# Get public dns
public_dns_str = urllib2.urlopen("http://169.254.169.254/latest/meta-data/public-hostname").read()

# Get list of existing hooks
req = urllib2.Request(GITHUB_WEBHOOKS_API)
req.add_header('Content-Type', 'application/json')
generate_auth(req)
hooks_response = urllib2.urlopen(req).read()
hooks = json.loads(hooks_response)

# Go through list of hooks and remove if already existing
for hook in hooks:
    hook_id = hook['id']
    hook_name = hook['name']
    if hook_name == 'web':
        hook_url = hook['config']['url']
        
        remove = False
        
        if hook_url == public_dns_str or REMOVE_ALL_EXISTING_WEBHOOKS:
            remove = True
            
        if remove:
            del_req = urllib2.Request(GITHUB_WEBHOOKS_API + "/" + str(hook_id))
            generate_auth(del_req)
            del_req.get_method = lambda: 'DELETE'
            del_response = urllib2.urlopen(del_req)
            
# Prepare new webhook
params = {
    "name": "web",
    "active": True,
    "events": [
        "push"
    ],
    "config": {
        "url": "http://" + public_dns_str + LISTENER_LOCATION,
        "content_type": "json",
        "secret": WEBHOOK_SECRET
    }
}

# Prepare POST request.
data = json.dumps(params)
request = urllib2.Request(GITHUB_WEBHOOKS_API, data)
request.add_header('Content-Type', 'application/json')
generate_auth(request)
try:
    response = urllib2.urlopen(request).read()
except urllib2.HTTPError as e:
    error_message = e.read()
EOT1


# Add startup script to update dns, update webhook, and start apache
cat > /home/ec2-user/s-ref/boot.sh << 'EOT2'
#!/bin/bash
NEW_PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
sed -i "s/ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = \[ '$NEW_PUBLIC_DNS' \]/g" /home/ec2-user/s-ref/strange-references/strange_references_project/settings.py
python /home/ec2-user/s-ref/webhook.py
service httpd start
EOT2
chmod +x /home/ec2-user/s-ref/boot.sh

printf '\nsource /home/ec2-user/s-ref/boot.sh\n' >> /etc/rc.local
source /home/ec2-user/s-ref/boot.sh