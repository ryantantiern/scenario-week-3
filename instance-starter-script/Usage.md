# AWS EC2 Instance starter script

## Requirements
Needs AWS CLI to have been installed (`pip install awscli`) and configured (`aws configure`).

## Description
Consists of two parts: a Python wrapper (`start_instance_py_wrapper.py`) for AWS CLI commands that start and label the instance, and a script that runs on the instance once it has been launched (`init_instance.sh`). To launch the instance with different options, modify the Python wrapper; to change software that is installed on the instance after it is launched, modify the shell script. 