#!/bin/bash

HOSTNAME='scenariodbinstance.cn23ibbreyu5.eu-west-1.rds.amazonaws.com' 
USERNAME='strangeuser' 
DBNAME='strangedb' 
LATEST_BACKUP='/home/ec2-user/2016-11-3-backup'

#pg_restore --verbose --clean -O -w -C -d postgres /home/ec2-user/2016-11-3-backup

pg_restore -h scenariodbinstance.cn23ibbreyu5.eu-west-1.rds.amazonaws.com -U strangeuser --clean -w -O -C -d postgres /home/ec2-user/2016-11-3-backup


