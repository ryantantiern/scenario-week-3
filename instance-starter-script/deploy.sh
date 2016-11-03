#!/bin/bash
# Removes existing files if present then downloads latest application files from Github repo.

cd /home/ec2-user
rm -rf strange-references*
curl -L -u blzq-mu:3669b531d5d5ae756280723fd071e0a1640db581 \
https://github.com/ryantantiern/strange-references/archive/master.zip \
> strange-references.zip
unzip strange-references.zip
rm strange-references.zip
mv strange-references-master/ strange-references/

chmod 755 `find . -type d`
chmod 644 `find . -type f`

chown -R ec2-user /home/ec2-user

# Update DEBUG setting in settings.py
sed -i "s/DEBUG = True/DEBUG = False/g" /home/ec2-user/strange-references/strange_references_project/settings.py