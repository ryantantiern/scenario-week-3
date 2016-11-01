#!/bin/bash

yum -y update
yum install -y python35 postgresql
pip install -U pip setuptools django

cd /home/ec2-user
aws s3 cp s3://aws-codedeploy-us-west-2/latest/install . --region us-west-2
chmod +x ./install
./install auto
