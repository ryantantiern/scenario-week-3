# Postgresql version must of RDS and EC2 must be the same
# .pgpass = hostname:port:database:username:password
# store on home directory of USER

# deploy to prod db server

HOSTNAME='scenariodbinstance.cn23ibbreyu5.eu-west-1.rds.amazonaws.com'
USERNAME='strangeuser'
DBNAME='strangedb'
LATEST_BACKUP="~/$(ls-t | head -1)" 

pg_restore -h $HOSTNAME -U $USERNAME -C -d postgres LATEST_BACKUP # $directoryPath must not exist 






