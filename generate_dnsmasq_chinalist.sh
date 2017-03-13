#!/bin/sh

# Name:         generate_dnsmasq_chinalist.sh
# Desription:   A script which auto-download newest dnsmasq-china-list and add ipset rules to the config file.
# Version:      0.1
# Date:         2017-01-30
# Author:       Cokebar Chi
# Website:      https://github.com/cokebar

usage() {
        cat <<-EOF
                Usage: generate_dnsmasq_chinalist [options] -f FILE

                Valid options are:

                    -d <dns_ip>		DNS IP address for the China domains (Default: 114.114.114.114)
                    -s <ipset_name>	IP set name for the China domains (If not given, ipset rules will not be generated.)
                    -f <FILE>		/path/to/output_filename
                    -h			Usage
EOF
        exit $1
}

DNS_IP=''
FILE_FULLPATH=''
IPSET_NAME=''

while getopts "d:s:f:h" arg; do
	case "$arg" in
		f)
			FILE_FULLPATH=$OPTARG
			;;
		d)
			DNS_IP=$OPTARG
			;;
		s)
			IPSET_NAME=$OPTARG
			;;
		h)
			usage 0
			;;
		*)
			echo "Invalid argument: -$OPTARG"
			exit 1
			;;
	esac
done

# Check input arguments

# Check path & file name
if [ -z $FILE_FULLPATH ]; then
	echo 'Please enter full path to the file.( Use: -f /path/to/output_filename)'
	exit 1
else
	if [ -z ${FILE_FULLPATH##*/} ]; then
		echo 'Please enter full path to the file, include file name.'
		exit 1
	else
		if [ ! -d ${FILE_FULLPATH%/*} ]; then
			echo "Folder do not exist: ${FILE_FULLPATH%/*}"
			exit 1
		fi
	fi
fi

# Check DNS IP
if [ -z $DNS_IP ]; then
	DNS_IP=114.114.114.114
else
	IP_TEST=$(echo $DNS_IP | grep -E '^((2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)\.){3}(2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)$')
	if [ "$IP_TEST" != "$DNS_IP" ]; then
		echo 'Please enter a valid DNS server IP address.'
		exit 1
	fi
fi

# Check IP set name
if [ -z $IPSET_NAME ]; then
	# Download dnsmasq-china-list and replace DNS IP
	echo "Download & writing file to $FILE_FULLPATH without ipset ..."
	( wget -O- 'https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf' || (echo "Failed to download dnsmasq-china-list"; exit 2;) ) |\
		sed -r 's#server=/(\S+)/(((2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)\.){3}(2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?))#server=/\1/'$DNS_IP'#g' >\
		/tmp/dnsmasq_chinalist.tmp
else
	IPSET_TEST=$(echo $IPSET_NAME | grep -E '^\w+$')
	if [ "$IPSET_TEST" != "$IPSET_NAME" ]; then
		echo 'Please enter a valid IP set name.'
		exit 1
	else
		echo "Download & writing file to $FILE_FULLPATH with ipset ..."
		# Download dnsmasq-china-list, and replace DNS IP and add ipset rules
		( wget -O- 'https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf' || (echo "Failed to download dnsmasq-china-list"; exit 2;) ) |\
			sed -r 's#server=/(\S+)/(((2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)\.){3}(2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?))#server=/\1/'$DNS_IP'\nipset=/\1/'$IPSET_NAME'#g' >\
			/tmp/dnsmasq_chinalist.tmp
	fi
fi

mv /tmp/dnsmasq_chinalist.tmp $FILE_FULLPATH
