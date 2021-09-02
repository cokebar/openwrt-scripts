#!/bin/sh

# version: 0.0.2

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
LOGFILE=/var/log/ss_watchdog.log
if [ `date +%w%H%M` == 70100 ];then
	echo -n "" > $LOGFILE
fi
sleep `awk 'BEGIN{srand();print int(rand()*10)}'`
wget --spider --quiet --tries=1 --timeout=10 https://www.google.com/
if [ "$?" == "0" ]; then
	echo '['$LOGTIME'] No Problem.' >> $LOGFILE
	exit 0
else
	wget --spider --quiet --tries=1 --timeout=10 https://www.baidu.com/
	if [ "$?" == "0" ]; then
		echo '['$LOGTIME'] Problem decteted, restarting shadowsocks.' >> $LOGFILE
		/etc/init.d/shadowsocks restart
	else
		echo '['$LOGTIME'] Network Problem. Do nothing.' >> $LOGFILE
	fi
fi
