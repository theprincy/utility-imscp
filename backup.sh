#!/bin/bash
# Script per la creazione di backup dei database MySQL e della directory /var/www

#Definisco le variabili contenenti le credenziali di accesso
MyUSER="user"   # Nome Utente di MySQL
MyPASS="password"   # Password di MySQL
MyHOST="localhost"      # Nome Host sul quale gira MySQL

MySourceDir="/var/www/virtual/" # Directory soggetta a backup
Email="/var/mail/virtual/"

#Utilizzo which per recuperare il path dei comandi che utilizzo e fare in modo
#che lo script sia il piu' flessibile possibile
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"
GZIP="$(which gzip)"
TAR="$(which tar)"
DAY="$(date +%a)"
DEST="/directoroy_backup/"            #Imposto la directory principale per il backup
HOST="$(hostname)"        #Recupero il nome dell'host
NOW="$(date +"%Y-%m-%d")" #Recupero la data odierna nel formato YYYY-MM-DD
MBD="$DEST/$NOW/mysql-$NOW"    #Imposto la directory all'interno della quale saranno
                          #posti i backup dei database di MySQL
DIRDEST="$DEST/$NOW/web-$NOW"  #Imposto la directory entro la quale sare' posto il
                          #backup della root directory di Apache
EMAILDEST="$DEST/$NOW/mail-$NOW" #Bakup email 


# Variabile che definisce all'interno di quale file effettuare il backup
FILE=""
# Variabile dove memorizzo i nomi dei DB presenti
DBS=""

# Lista dei database da escludere dal backup
IGGY="test"

[ ! -d $MBD ] && mkdir -p $MBD || :


# Imposto i permessi in modo che solo root possa accedere ai backup
$CHOWN 0.0 -R $DEST
$CHMOD 0600 $DEST

#Procedo con la creazione del backup della Source_Dir sopra specificata

# Recupero la lista di tutti i database
DBS="$($MYSQL -u $MyUSER -h $MyHOST -p$MyPASS -Bse 'show databases')"

#Procedo con la creazione dei dump di ogni singolo database
for db in $DBS
do
    skipdb=-1
    if [ "$IGGY" != "" ];
    then
        for i in $IGGY
        do
            [ "$db" == "$i" ] && skipdb=1 || :
        done
    fi

    if [ "$skipdb" == "-1" ] ; then
        FILE="$MBD/$db.$HOST.$NOW.gz"
        $MYSQLDUMP  --skip-lock-tables -u $MyUSER -h $MyHOST -p$MyPASS $db | $GZIP -9 > $FILE
        echo "Backup del Database $db completo!"
    fi
done

#Procedo con la creazione del backup della Source_Dir sopra specificata

echo "Inizio Backup di $MySourceDir"

[ ! -d $DIRDEST ] && mkdir -p $DIRDEST || :


WDS=`dir $MySourceDir`

if [ $DAY == "Mon"  ]
then
        
       for w in $WDS
       do
        FILE="$DIRDEST/source-$w.tar.gz"
        $TAR -czpf $FILE $MySourceDir/$w/*
       
       done


      else 


     for w in $WDS
     do
       
        $TAR -czpf $FILE  -N "$(date -d '1 day ago')"  $MySourceDir/$w/*
        echo "Inizio verifica del backup creato"
        tar --diff --compare --verbose -f $DIRDEST/source-$w-$NOW.tar.gz
        echo "Backup di /var/www completo!"

    done 



        fi


echo "Inizio Backup di $EMAILDEST"

[ ! -d $EMAILDEST ] && mkdir -p $EMAILDEST || :


WES=`dir $Email`

for w in $WES
do
        FILE="$EMAILDEST/mail-$w-$NOW.tar.gz"
        $TAR -czpf $FILE $Email/$w/*
done


#scp -r /home/backup/$NOW  user@IP:/directoroy_backup

or 

#sshpass -p 'password' sftp user@IP << EOI
  
  mkdir   $NOW
  cd $NOW
  mkdir  mysql-$NOW
  mkdir mail-$NOW
  mkdir web-$NOW
 put -r $DEST/$NOW/mysql-$NOW/*  /directoroy_backup/$NOW/mysql-$NOW
 put -r $DEST/$NOW/mail-$NOW/*  /directoroy_backup/$NOW/mail-$NOW
 put -r $DEST/$NOW/web-$NOW/*   /directoroy_backup/$NOW/web-$NOW
EOI

rm  -Rf  /directoroy_backup/
