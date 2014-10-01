#!/bin/bash
# FLO Backup Tool

if [ $# -lt 0 ] || [ $# -gt 2 ] ; then
	echo "Usage: $0 [backup|clr|server [update|clr]]"
	exit 1
fi

## Config
SERVER="zbox"
DESTFOLDER="/home/flo/3TB/Daten/Backup_YOGA"

# Directories
DIRECTORIES[0]="/home/flo/projects/"
DIRECTORIES[1]="/home/flo/bin/"
DIRECTORIES[2]="/home/flo/hsr/"
DIRECTORIES[3]="/home/flo/.ssh/"
DIRECTORIES[4]="/home/flo/dev/"
DIRECTORIES[5]="/opt/ide/"
DIRECTORIES[6]="/home/flo/doc/"
DIRECTORIES[7]="/usr/local/bin/"

## Const	
TEMPEXT=".IAMOLD"
BAKEXT=".BAK"
TS="date +%T"
SEP1="==============================================================================="
SEP2="-------------------------------------------------------------------------------"
STOPWATCH=`date +%s`
LOGMSGTYP="BACKUP,COPY,DEL,MISC,MOUNT,NAME1,PROGRESS2,REMOVE,STATS,SYMSAFE"
COLORKEYWORDS="backed up\|deleting"


if [ $# -eq 0 ] ; then
	echo $SEP1
	echo `$TS` "Backup Folders.."
	for DIRECTORY in ${DIRECTORIES[*]} ; do
		echo $SEP2
		echo `$TS` "$DIRECTORY:"
		TMPSTOPWATCH=`date +%s`
		rsync -avzR --delete --backup --suffix=.`date +"%Y-%m-%d_%H-%M"`$BAKEXT$TEMPEXT --exclude "*$BAKEXT*" --info=$LOGMSGTYP -e ssh $DIRECTORY $SERVER:$DESTFOLDER | sed -e "s/^$COLORKEYWORDS/\x1b[91m&\x1b[0m/"
		echo "took" $(((`date +%s`-TMPSTOPWATCH)/60)) "min." $(((`date +%s`-TMPSTOPWATCH)%60)) "sec."
	done
	ssh zbox iu-backup server update
	echo `$TS` "DONE!" "took" $(((`date +%s`-STOPWATCH)/60)) "min." $(((`date +%s`-STOPWATCH)%60)) "sec."
elif [ $1 == "clr" ] ; then
	ssh zbox iu-backup server clr
elif [ $1 == "server" ] ; then
	cd $DESTFOLDER
	if [ $2 == "update" ] ; then
		echo $SEP1
		echo `$TS` "Check for Updates.."
		find . -type f -name "*$TEMPEXT" -print0 | while read -d $'\0' FILE ; do
			OLDFILE=${FILE:0:-7}
			BASEFILE=${FILE:0:-28}
			BASENAME=${BASEFILE##*/}
			EXTENSION=${BASENAME##*.}

			if [[ $BASENAME == *$BAKEXT* ]] ; then
				mv "$FILE" "$BASEFILE"
				echo iu
			else
				echo `$TS` "Backup Old Version of: $BASEFILE"
				mv "$FILE" "$OLDFILE.$EXTENSION"
			fi
		done
		echo $SEP1
	elif [ $2 == "clr" ] ; then
		find -name "*.BAK.*"
		echo "Clear Old Files? (y/n)"
		read a
		if [ $a == 'y' ] ; then
			find -type f -name "*.BAK.*" -exec rm {} \;
		fi
	fi
fi
