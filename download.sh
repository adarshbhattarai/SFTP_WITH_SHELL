#!/bin/sh

###########################
# Get the Program Directory  
# resolve links - $0 may be a softlink
BASEDIR=$(dirname "$0")
cd $BASEDIR

PRG=$(basename "$0")

# loop to follow links to link to links.
while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done
PRGDIR=`dirname "$PRG"`
echo "Program Directory is: $(readlink -f $PRGDIR)"


#######################################
# Update Properties File with DB config
if [ ! -f ${PRGDIR}/../../lib/config.cfg ]
then
echo "Config file doesn't exist at defined location"
exit 1
fi
. ${PRGDIR}/../../lib/config.cfg

HOSTNAME=$HOST_NAME
MAILBOX=$USER
PORTNO=$PORT

FILESFROM=$Fromdirectory
FILESTO=../../../i/file_location
LOGSAT=../../../i/log_location

TIME=$(date +%k.%M)
TODAY=`/bin/date +%Y-%m-%d`
YESTERDAY=`/bin/date +%Y-%m-%d -d yesterday`
LOGNAME=example.incoming.$TODAY.$TIME.out

if [ -z "$1" ]
  then 
   FILENAME=XYZ_ ${YESTERDAY}_*.zip
   TODAYSFILE=XYZ_${TODAY}_*.zip
  else
   FILENAME=$1
fi
#check if path exists
[ -d ${PRGDIR}$FILESTO ] && echo "Directory exist $PRGDIR"|| mkdir -p $FILESTO && echo "Directory doesn't exist, creating new $FILESTO" 
[ -d $LOGSAT ] || mkdir -p $LOGSAT

{
#try connecting to the mailbox and get given file
sftp -oPort=$PORTNO $MAILBOX@$HOSTNAME:/ <<EOF
cd $FILESFROM
get $FILENAME
get $TODAYSFILE
bye 
EOF

} >> $LOGSAT/$LOGNAME ||
{
#catch exit if error occured
 echo "Something went wrong. See the logs"
 echo "connection was refused.." >> $LOGSAT/$LOGNAME
 exit 1 
}
mv -f $TODAYSFILE $FILESTO
if [ $? -eq 0 ]; then
  echo "Successfully Moved today's file to $FILESTO/$DAY" >> $LOGSAT/$LOGNAME 
else
  echo "Not found Today's file, moving Yesterday's" >> $LOGSAT/$LOGNAME
fi   
   
mv -f $FILENAME  $FILESTO 
if [ $? -eq 0 ]; then 
  echo "Successfully Moved to $FILESTO/$DAY" >> $LOGSAT/$LOGNAME 
  echo "Successfully Downloaded"
else 
  echo "Move Failed" >>  $LOGSAT/$LOGNAME
  echo "Failed to move"
  exit 1
 fi
 echo "Successful"
 exit 0
