#!/bin/sh

PREFIX='php.fpm'
URL='http://127.0.0.1/status'

CURL='/usr/bin/curl'
TMP='/tmp/php-fpm-ping.tmp'
SENDER='/usr/bin/zabbix_sender'
CONFIG='/etc/zabbix/zabbix_agentd.conf'

if [ ! -x ${CURL} ]
then echo Seems, path to curl is incorrect or not installed. && exit 0
else if [ ! -x ${SENDER} ]
then echo Seems, path to zabbix_sender is incorrect or not installed. && exit 0
else if [ ! -f ${CONFIG} ]
then echo Seems, path to zabbix_agentd.conf is incorrect && exit 0
fi fi fi

(time ${CURL} --no-keepalive -sm3 ${URL}) 2>$TMP | awk --assign pr="- ${PREFIX}." '
/^accepted c/ {print pr"accepted_conn "$3}
/^active proc/ {print pr"active_processes "$3}
/^idle proc/ {print pr"idle_processes "$3}
/^listen queue:/ {print pr"listen_queue_len "$3}
/^max children reach/ {print pr"max_children_reached "$4}
/^max listen queue:/ {print pr"max_listen_queue_len "$4}' | ${SENDER} -c ${CONFIG} -i - 2>/dev/null | awk --assign t="${TMP}" '/^sent/{if($6==0){print"-0.001";print>t}}'
awk '/real/{split($2,a,"[ms]");print a[1]*60+a[2];}' $TMP
rm $TMP
exit 1
