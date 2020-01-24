d#!/bin/bash
###################################################################
###############       Automatic Mysql Backup       ################
###############       @itfinden                    ################
###################################################################

# MySQL Config
USER="root"
PASS="hafizh"
HOST="localhost"

# Backup Dirctory
DIR="/home/cloud_backup"

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

# chequeando MySQL Password
echo "\n" >> $DIR/$LOG
echo "Chequear MySQL Login ..." >> $DIR/$LOG
echo exit | mysql --user=$USER --password=$PASS -B 2>/dev/null
if [ "$?" -gt 0 ]; then
  echo "MySQL ${mysql_user} password incorrecta" >>  $DIR/$LOG
  exit 1
else
  echo "MySQL ${mysql_user} password correcta."  >> $DIR/$LOG
fi

# Respaldo Databases
echo "\n">> $DIR/$LOG

echo "Comprobación de vencimiento de Respaldo para liberar espacio ..." >> $DIR/$LOG
# Checking expire backup
if [ $DAY != 0 ]; then
    echo "Expire by Day. Searching expire files " >> $DIR/$LOG
    for file in $(cd $DIR; find ./ -mindepth 2 -type d -mtime +$[$EXP])
    do
        if [ -z $file ]; then
            break;
        else
            echo "Borrando $file" >> $DIR/$LOG
            rm -rf $file
        fi
    done;
    echo "Borrando directorio antiguo" >> $DIR/$LOG
    find $DIR/ -type d -mtime +$[$EXP] -print0 | xargs -0 rm
else
    echo "Caducar por horas. Búsqueda de archivos caducados" >> $DIR/$LOG
    for file in $(find $DIR/ -mindepth 2 -type d -mmin +$[$EXP*60])
    do
        echo $file
        if [[ -z "$file" ]]; then
            echo "No hay archivos vencidos"
            break;
        else
            echo "Borrando $file" >> $DIR/$LOG
            rm -rf $file
        fi
    done;
    echo "Borrando directorio antiguo" >> $DIR/$LOG
    find $DIR/ -type d -mmin $[$EXP*60] -print0 | xargs -0 rm
fi

echo "Creando directorio para Respaldo ..." >> $DIR/$LOG
mkdir -p $DIR/$DATE/$HOURS

for db in $($MYSQL --user=$USER --password=$PASS -e 'show databases' | egrep -ve 'Database|schema|test|phpmyadmin')
do
    echo "Respaldando la base de Datos $db" >> $DIR/$LOG
    $MYSQLDUMP  --user=$USER --password=$PASS --host=$HOST $db | gzip > $DIR/$DATE/$HOURS/$db.sql.gz
    sleep 1
done
echo "Creacion de respaldo realizada ..." >> $DIR/$LOG

echo "Respaldo hecho. Saliendo ..."
exit 0
