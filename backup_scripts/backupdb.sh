# Postgresql version must of RDS and EC2 must be the same
# .pgpass = hostname:port:database:username:password
# store on home directory of USER

# backing up from prod db server

HOSTNAME='scenariodbinstance.cn23ibbreyu5.eu-west-1.rds.amazonaws.com'
USERNAME='strangeuser'
DBNAME='strangedb'
DIRECTTORYPATH="~/$(date +%F-%-k-%M-%S-%N)"

pg_dump -h $HOSTNAME -U $USERNAME -Fd $DBNAME -f $DIRECTTORYPATH # $directoryPath must not exist 






