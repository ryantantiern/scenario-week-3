import subprocess
import json

# Change --key-name, --security-group-ids as needed for the AWS account
start_cmd = "aws ec2 run-instances --image-id ami-5ec1673e --count 1" + \
	" --instance-type t2.micro --key-name server1keypair" + \
	" --security-group-ids sg-156c1b6c --user-data file://init_instance.sh"

process = subprocess.run([start_cmd], stdout=subprocess.PIPE, shell=True)
output = process.stdout

output = json.loads(output.decode("utf-8"))
print(json.dumps(output, indent=2))

instanceID = output['Instances'][0]['InstanceId']

# Change the following to change the name or other tags
tags = 'Key=Name,Value=Server1'
label_cmd = 'aws ec2 create-tags --resources ' + instanceID + \
	' --tags ' + tags

subprocess.run([label_cmd], shell=True)