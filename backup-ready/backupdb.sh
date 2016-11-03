#!/bin/bash

HOSTNAME='scenariodbinstance.cn23ibbreyu5.eu-west-1.rds.amazonaws.com'
USERNAME='strangeuser'
DBNAME='strangedb'
DIRECTORYPATH="/home/ec2-user/$(date +%F-%-k-%M-%S-%N)"

pg_dump --verbose -h $HOSTNAME -U $USERNAME --format=directory -f $DIRECTORYPATH -d $DBNAME
