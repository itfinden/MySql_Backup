#!/bin/bash
###################################################################
###############       Automatic Mysql Backup       ################
###############       @itfinden                    ################
###################################################################

# MySQL Config
USER="root"
PASS="hafizh"
HOST="localhost"

# Backup Dirctory
DIR="/home/hafizh/mysqlbackup"

# Backup Fecha
DATE=$(date +"%d-%b-%Y")

# Backup Hora
HOURS=$(date +"%H-00")

# Backup Retencion
RETAIN=2

# Backup Expira
EXP=2

# Día para caducar. Establezca en 0 si elige caducar por hora y establezca HOUR en n horas
DAY=0

# Hora de caducar. Establezca en 0 si elige caducar por día y establezca DÍA en n días
HOUR=1

# MySQL ruta
MYSQL=$(which mysql)
MYSQLDUMP=$(which mysqldump)
LOG="mysql-backup.log"

echo "Iniciando Backup ..."
# Compruebe que el directorio de copia de seguridad existe y créelo si no existe
if [ ! -d $DIR ]
then
    echo "El directorio no existe! Creando un directorio de respaldo ..."
    mkdir -p $DIR
    echo "Directorio creado con éxito!" >> $DIR/$LOG
    echo "+++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Iniciar MySQL Backup" >> $DIR/$LOG
else 
    echo "" > $DIR/$LOG
    echo "Iniciar MySQL Backup" >> $DIR/$LOG
fi

# Checking MySQL Password
echo "\n" >> $DIR/$LOG
echo "Chequear MySQL Login ..." >> $DIR/$LOG
echo exit | mysql --user=$USER --password=$PASS -B 2>/dev/null
if [ "$?" -gt 0 ]; then
  echo "MySQL ${mysql_user} password incorrect" >>  $DIR/$LOG
  exit 1
else
  echo "MySQL ${mysql_user} password correct."  >> $DIR/$LOG
fi

# Backup Databases
echo "\n">> $DIR/$LOG

echo "Checking expire backup to free space ..." >> $DIR/$LOG
# Checking expire backup
if [ $DAY != 0 ]; then
    echo "Expire by Day. Searching expire files " >> $DIR/$LOG
    for file in $(cd $DIR; find ./ -mindepth 2 -type d -mtime +$[$EXP])
    do
        if [ -z $file ]; then
            break;
        else
            echo "Removing $file" >> $DIR/$LOG
            rm -rf $file
        fi
    done;
    echo "Removing old Directory" >> $DIR/$LOG
    find $DIR/ -type d -mtime +$[$EXP] -print0 | xargs -0 rm
else
    echo "Expire by Hours. Searching expire files" >> $DIR/$LOG
    for file in $(find $DIR/ -mindepth 2 -type d -mmin +$[$EXP*60])
    do
        echo $file
        if [[ -z "$file" ]]; then
            echo "No file expired"
            break;
        else
            echo "Removing $file" >> $DIR/$LOG
            rm -rf $file
        fi
    done;
    echo "Removing old Directory" >> $DIR/$LOG
    find $DIR/ -type d -mmin $[$EXP*60] -print0 | xargs -0 rm
fi

echo "Creating database directory ..." >> $DIR/$LOG
mkdir -p $DIR/$DATE/$HOURS

for db in $($MYSQL --user=$USER --password=$PASS -e 'show databases' | egrep -ve 'Database|schema|test|phpmyadmin')
do
    echo "Backup database $db" >> $DIR/$LOG
    $MYSQLDUMP  --user=$USER --password=$PASS --host=$HOST $db | gzip > $DIR/$DATE/$HOURS/$db.sql.gz
    sleep 1
done
echo "Creating Backup MySQL Done ..." >> $DIR/$LOG

echo "Backup done. Exiting ..."
exit 0
