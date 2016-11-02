#!/usr/bin/python
# This script retrieves the current AWS public DNS address via the AWS CLI and communicates with GitHub to set up webhooks.

import subprocess
import json

# Config
AWS_INSTANCE_NAME = "ScenarioStaging"

# AWS CLI Calls
AWS_GET_PUBLICDNS = 'aws ec2 describe-instances --filters "Name=instance-state-name,Values=running,Name=tag:Name,Values=%s" --query "Reservations[].Instances[].PublicDnsName"' % AWS_INSTANCE_NAME

aws_instances_result = subprocess.check_output(AWS_GET_PUBLICDNS, shell = True)
parsed_json = json.loads(aws_instances_result)

# For debug:
#print aws_instances_result
print("There are %s entries." % len(parsed_json))

public_dns_str = parsed_json[0]

print(public_dns_str)