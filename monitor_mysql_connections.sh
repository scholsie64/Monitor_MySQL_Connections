#!/bin/bash

set -vx

# Declare some global variables
hostname=talisman-web22.com
threshold_connections=${1:-200}
check_frequency=${3:-300}
mail_max_frequency=3600
mail_last_sent=0
mail_recipients=${2:-tonys@talisman.tech}

send_alert_mail() {
	now=`date +%s`
	if [ `expr $now - $mail_last_sent` -gt $mail_max_frequency ]
	then
		mail_last_sent=$now
		echo "Only $1 Connection slots free at `date`.\n\nKInd Regards" | mutt -s "MySQL Connections monitor on $hostname" $mail_recipients
	fi
}

while [ true ]
do
	max_connections=`mysql -N -B -e "SHOW VARIABLES LIKE 'max_connections';" | cut -f2`
	current_connections=`mysql -N -B -e "SHOW PROCESSLIST" | wc -l`

	free_connections=`expr $max_connections - $current_connections`

	if [ $free_connections -lt $threshold_connections ] 
	then
		send_alert_mail $free_connections
	fi

	sleep $check_frequency
done

exit 0
