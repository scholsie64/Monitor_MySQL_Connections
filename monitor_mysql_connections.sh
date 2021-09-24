#!/bin/bash

#
# Monitor current MySQL connections, send an email to the support system if a given threshold is exceeded.
#

#set -vx

# Declare some global variables
hostname=mi-man-talsql1
threshold_connections=${1:-200}
check_frequency=${3:-300}
mail_max_frequency=${4:-3600}
mail_last_sent=0
mail_recipients=${2:-help@support.talisman.tech}
mail_subject="MySQL Connections monitor on $hostname"

#
# Send alert mail, not too frequently, avoid flooding support ticket system.
#
send_alert_mail() {
	now=`date +%s`
	if [ `expr $now - $mail_last_sent` -gt $mail_max_frequency ]
	then
		mail_last_sent=$now
		EMAIL=talisman_tech@talisman-web22.com export EMAIL
		echo "Hi,\n\nThe MySQL Connections Monitor in $hostname reports only $1 connections free at `date`.\n\nThere are $2 connections in use of $3 maximum concurrent connections\n\nKind Regards" | mutt -s "$mail_subject" $mail_recipients
	fi
}

while [ true ]
do
	max_connections=`mysql -N -B -e "SHOW VARIABLES LIKE 'max_connections';" | cut -f2`
	current_connections=`mysql -N -B -e "SHOW PROCESSLIST" | wc -l`

	free_connections=`expr $max_connections - $current_connections`

	if [ $free_connections -lt $threshold_connections ] 
	then
		send_alert_mail $free_connections $current_connections $max_connections
	fi

	sleep $check_frequency
done

exit 0
