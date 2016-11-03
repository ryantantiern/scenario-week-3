#!/usr/bin/env python
# This script retrieves the current AWS public DNS address via the AWS CLI and communicates with GitHub to set up webhooks.

import subprocess
import json
import time
import urllib2, base64

# Config

# Github Config
GITHUB_TOKEN = "b9501e841e0c37fe7a56c96cfedef07938ece540"
GITHUB_USERNAME = "ryantantiern"
GITHUB_REPO = "strange-references"
WEBHOOK_SECRET = "strange1"
GITHUB_WEBHOOKS_API = "https://api.github.com/repos/%s/%s/hooks" % (GITHUB_USERNAME, GITHUB_REPO)

# AWS Config
AWS_INSTANCE_NAME = "ScenarioStaging"
AWS_HOSTNAME_ENDPOINT = "http://169.254.169.254/latest/meta-data/public-hostname"

# Github-Listener Config
LISTENER_LOCATION = ":8080"  # The location where github-listener is running. Port 8080.

# Preferences
REMOVE_ALL_EXISTING_WEBHOOKS = True

# Utility Functions
def generate_auth(request):
    base64string = base64.b64encode('%s:%s' % (GITHUB_USERNAME, GITHUB_TOKEN))
    request.add_header("Authorization", "Basic %s" % base64string)
    
def log(message):
    print "[%s] %s" % (time.ctime(), message)
    
# Contact AWS to get hostname.
# Result stored in var public_dns_str.
# If running on VM, get public hostname (DNS) from instance metadata.
log("Contacting AWS...")
try:
    hostname_req = urllib2.Request(AWS_HOSTNAME_ENDPOINT)
    hostname_response = urllib2.urlopen(hostname_req).read()
    public_dns_str = hostname_response
except:
    # Instance metadata not available - we're not running on the VM. Query AWS CLI to retrieve current AWS public DNS address.
    AWS_GET_PUBLICDNS = 'aws ec2 describe-instances --filters "Name=instance-state-name,Values=running,Name=tag:Name,Values=%s" --query "Reservations[].Instances[].PublicDnsName"' % AWS_INSTANCE_NAME

    aws_instances_result = subprocess.check_output(AWS_GET_PUBLICDNS, shell = True)
    parsed_json = json.loads(aws_instances_result)
    public_dns_str = parsed_json[0]

log("DNS entry retrieved: %s." % public_dns_str)

# Connect to Github API
log("Contacting GitHub...")

# Get list of existing hooks
req = urllib2.Request(GITHUB_WEBHOOKS_API)
req.add_header('Content-Type', 'application/json')
generate_auth(req)
hooks_response = urllib2.urlopen(req).read()
hooks = json.loads(hooks_response)

log("There are %d hooks registered." % len(hooks))

# Go through list of hooks and remove if already existing.
for hook in hooks:
    hook_id = hook['id']
    hook_name = hook['name']
    if hook_name == 'web':
        hook_url = hook['config']['url']
        log("ID: " + str(hook_id) + " URL: " + hook_url)
        
        remove = False
        
        if hook_url.find(public_dns_str) > -1 or REMOVE_ALL_EXISTING_WEBHOOKS:
            remove = True
            
        if remove:
            log("Note: Webhook already exists. Removing...")
            del_req = urllib2.Request(GITHUB_WEBHOOKS_API + "/" + str(hook_id))
            generate_auth(del_req)
            del_req.get_method = lambda: 'DELETE'
            del_response = urllib2.urlopen(del_req)
            
            log("Webhook %d removed." % hook_id)

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
log("Attempting to register webhook.")
try:
    response = urllib2.urlopen(request).read()
    log("Webhook successfully registered.")
except urllib2.HTTPError as e:
    log("ERROR: An error occurred - see response:")
    error_message = e.read()
    log(error_message)