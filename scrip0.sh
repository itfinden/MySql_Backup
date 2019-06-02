#!/bin/bash
#Variables
backupin=/dsk_backup/mysqlbks
expira=5
servertype=cpanel
myuser="root"
mypass="pass"
myhost="localhost"

if [ $servertype = cpanel ]; then
        mypass=`cat /root/.my.cnf |grep password | cut -d '"' -f2`
fi
MKDIR=/bin/mkdir
TOUCH=/bin/touch
logfile=/var/log/MySQL_log.txt
fecha=$(/bin/date)
if [ ! -d $backupin ]; then
        $MKDIR $backupin
else
        find $backupin -type d -mtime +$expira | xargs rm -Rf

fi
if [ ! -e $logfile ]; then
        $TOUCH $logfile
fi
carpetabk=$backupin/`date +%Y-%m-%d-h%H%M-%S`

if [ ! -d $carpetabk ]; then
        $MKDIR -p $carpetabk
fi
lists=$(echo "show databases;" | mysql -h $myhost -u $myuser -p$mypass | grep -v Database | grep -v information_schema | grep -v performance_schema | grep -v phpmyadmi)
echo "Comenzando el respaldo de las bases de datos" >> $logfile
tput setaf 1
tput bold
#echo "Comenzando el respaldo de las bases de datos"
tput sgr0
echo $fecha >> $logfile
C=0
for db in $lists
do
tput setaf 2
#echo "Respaldo base de datos $db"
mysqldump -h $myhost -u$myuser -p$mypass --opt $db > $carpetabk/$db.sql 2>/var/log/MySQL_BK_errorlog
echo "Respaldando $db" >> $logfile
tput setaf 3
#echo "Comprimiendo (gzip) base de datos --- $db"
tput sgr0
gzip $carpetabk/$db.sql
((C++))
done
echo "Backup completo, se respaldaron $C Bases de Datos!" >> $logfile
echo $fecha >> $logfile
#echo "Puedes revisar el log en $logfile y el errorlog en /var/log/MySQL_BK_errorlog"
tput setaf 2
#echo "Se respaldaron $C Bases de datos"
tput sgr0
