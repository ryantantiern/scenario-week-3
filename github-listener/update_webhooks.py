#!/usr/bin/python
# This script retrieves the current AWS public DNS address via the AWS CLI and communicates with GitHub to set up webhooks.

import subprocess
import json
import urllib2, base64

# Config
AWS_INSTANCE_NAME = "ScenarioStaging"
GITHUB_TOKEN = "b9501e841e0c37fe7a56c96cfedef07938ece540"
GITHUB_USERNAME = "ryantantiern"
GITHUB_REPO = "scenario-week-3"
WEBHOOK_SECRET = "strange1"
GITHUB_WEBHOOKS_API = "https://api.github.com/repos/%s/%s/hooks" % (GITHUB_USERNAME, GITHUB_REPO)

# Utility Functions
def generate_auth(request):
    base64string = base64.b64encode('%s:%s' % (GITHUB_USERNAME, GITHUB_TOKEN))
    request.add_header("Authorization", "Basic %s" % base64string)

# Call AWS CLI to retrieve current AWS public DNS address.
# Result stored in public_dns_str.
AWS_GET_PUBLICDNS = 'aws ec2 describe-instances --filters "Name=instance-state-name,Values=running,Name=tag:Name,Values=%s" --query "Reservations[].Instances[].PublicDnsName"' % AWS_INSTANCE_NAME

aws_instances_result = subprocess.check_output(AWS_GET_PUBLICDNS, shell = True)
parsed_json = json.loads(aws_instances_result)
public_dns_str = parsed_json[0]

# For debug:
#print aws_instances_result
print("There are %s entries." % len(parsed_json))
print(public_dns_str)

# Connect to Github API
params = {
    "name": "web",
    "active": "true",
    "events": [
        "push"
    ],
    "config": {
        "url": "http://randy.com/webhooks",
        "content_type": "json",
        "secret": WEBHOOK_SECRET
    }
}

data = json.dumps(params)
print data
request = urllib2.Request(GITHUB_WEBHOOKS_API, data)
request.add_header('Content-Type', 'application/json')
generate_auth(request)
try:
    response = urllib2.urlopen(request).read()
except Exception:
    print "error ocurred"
print(response)