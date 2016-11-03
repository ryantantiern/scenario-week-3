#!/usr/bin/env python
# This script launches EC2 instances, creating a security group if not already present.
# This script optionally accepts three arguments:
# Argument 1: KEY_NAME
# Argument 2: INSTANCE_NAME
# Argument 3: IMAGE_ID
# Arguments that are not supplied will assume default values.
import subprocess
import json
import sys

# Config
# Set KEY_NAME, SECURITY_GROUP_ID as needed for the AWS account.
KEY_NAME = "server1keypair"
INSTANCE_NAME = "StrangeProd"

# These constants should be fixed.
IMAGE_ID = "ami-5ec1673e"
SECURITY_GROUP_NAME = "strange-security-group"

# Get command line arguments
# Argument 1: KEY_NAME
# Argument 2: INSTANCE_NAME
# Argument 3: IMAGE_ID
if len(sys.argv[1:]) > 0:
    KEY_NAME = sys.argv[1:][0]
if len(sys.argv[1:]) > 1:
    INSTANCE_NAME = sys.argv[1:][1]
if len(sys.argv[1:]) > 2:
    IMAGE_ID = sys.argv[1:][2]

# ---- SECURITY GROUP ----
    
# See if security group is already present
check_security_group_json = None
try:
    check_security_group_cmd = 'aws ec2 describe-security-groups --group-names %s' % SECURITY_GROUP_NAME
    check_security_group_result = subprocess.check_output(check_security_group_cmd, shell = True)
    check_security_group_json = json.loads(check_security_group_result)
except:
    print("No existing security group.")

if not (check_security_group_json is None) and len(check_security_group_json['SecurityGroups']) > 0:
    security_group_id = check_security_group_json['SecurityGroups'][0]['GroupId']

else:
    # Security group not present - create security group.
    print("Creating security group...")
    create_security_group_cmd = 'aws ec2 create-security-group --group-name %s --description "Strange security group"' % SECURITY_GROUP_NAME
    create_security_group_result = subprocess.check_output(create_security_group_cmd, shell = True)
    create_security_group_json = json.loads(create_security_group_result)
    security_group_id = create_security_group_json['GroupId']

    set_rules_cmd = 'aws ec2 authorize-security-group-ingress --group-name %s --protocol all --cidr 0.0.0.0/0' % SECURITY_GROUP_NAME
    subprocess.call(set_rules_cmd, shell = True)
    
# ---- EC2 INSTANCE ----

# Launch instance
print("Launching EC2 instance...")
start_cmd = "aws ec2 run-instances --image-id %s --count 1" % IMAGE_ID + \
	" --instance-type t2.micro --key-name %s" % KEY_NAME + \
	" --security-group-ids %s --user-data file://init_instance.sh" % security_group_id
    
result = subprocess.check_output(start_cmd, shell = True)
parsed_json = json.loads(result)

instanceID = parsed_json['Instances'][0]['InstanceId']

# Set instance name for the newly created instance.
tags = 'Key=Name,Value=%s' % INSTANCE_NAME
label_cmd = 'aws ec2 create-tags --resources ' + instanceID + \
	' --tags ' + tags

result = subprocess.check_output(label_cmd, shell = True)

print("EC2 instance launched.")