#!/bin/sh

# version: 0.0.1

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
wget --spider --quiet --tries=1 --timeout=10 https://www.google.com/
if [ "$?" == "0" ]; then
	echo '['$LOGTIME'] No Problem.'
	exit 0
else
	wget --spider --quiet --tries=1 --timeout=10 https://www.baidu.com/
	if [ "$?" == "0" ]; then
		echo '['$LOGTIME'] Problem decteted, restarting shadowsocks.'
		/etc/init.d/shadowsocks restart
	else
		echo '['$LOGTIME'] Network Problem. Do nothing.'
	fi
fi
