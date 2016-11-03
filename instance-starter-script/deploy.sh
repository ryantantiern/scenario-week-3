#!/bin/bash
# Removes existing files if present then downloads latest application files from Github repo.

cd /home/ec2-user/s-ref/
rm -rf strange-references
curl -L -u blzq-mu:3669b531d5d5ae756280723fd071e0a1640db581 \
https://github.com/ryantantiern/strange-references/archive/hooklistener.zip \
> strange-references.zip
unzip strange-references.zip
rm strange-references.zip
mv strange-references-hooklistener/ strange-references/

chmod 755 `find . -type d`
chmod 644 `find . -type f`
chown -R apache /home/ec2-user/s-ref/

# Update DEBUG setting in settings.py
sed -i "s/DEBUG = True/DEBUG = False/g" /home/ec2-user/s-ref/strange-references/strange_references_project/settings.py