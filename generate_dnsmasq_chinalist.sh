#!/bin/sh

# Name:         generate_dnsmasq_chinalist.sh
# Desription:   A script which auto-download newest dnsmasq-china-list and add ipset rules to the config file.
# Version:      0.2
# Date:         2017-03-13
# Author:       Cokebar Chi
# Website:      https://github.com/cokebar

_usage() {
        cat <<-EOF

Usage: sh generate_dnsmasq_chinalist.sh [options] -o FILE
Valid options are:
    -d, --dns <dns_ip>
                DNS IP address for the GfwList Domains (Default: 114.114.114.114)
    -p, --port <dns_port>
                DNS Port for the GfwList Domains (Default: 53)
    -s, --ipset <ipset_name>
                Ipset name for the China-List domains
                (If not given, ipset rules will not be generated.)
    -o, --output <FILE>
                /path/to/output_filename
    -i, --insecure
                Force bypass certificate validation (insecure)
    -h, --help  Usage
EOF
        exit $1
}

_clean_and_exit(){
	# Clean up temp files
	printf 'Cleaning up...'
	rm -rf $_WORKING_DIR
	printf ' Done.\n\n'
	exit $1
}

_check_depends(){
	which awk curl >/dev/null
	if [ $? != 0 ]; then
		printf '\033[31mError: Missing Dependency.\nPlease check whether you have the following binaries on you system:\nawk, curl\033[m\n'
		exit 3
	fi
}

_get_args(){
	_DNS_IP='114.114.114.114'
	_DNS_PORT='53'
	_IPSET_NAME=''
	_OUT_FILE=''
	_CURL_EXTARG=''
	_WITH_IPSET=0

	while [ ${#} -gt 0 ]; do
		case "${1}" in
			--help | -h)
				_usage 0
				;;
			--insecure | -i)
				_CURL_EXTARG='--insecure'
				;;
			--dns | -d)
				_DNS_IP="$2"
				shift
				;;
			--port | -p)
				_DNS_PORT="$2"
				shift
				;;
			--ipset | -s)
				_IPSET_NAME="$2"
				shift
				;;
			--output | -o)
				_OUT_FILE="$2"
				shift
				;;
			*)
				echo "Invalid argument: $1"
				_usage 1
				;;
		esac
		shift 1
	done

	# Check path & file name
	if [ -z $_OUT_FILE ]; then
		echo 'Please enter full path to the file.(/path/to/output_filename)'
		exit 1
	else
		if [ -z ${_OUT_FILE##*/} ]; then
			echo 'Please enter full path to the file, include file name.'
			exit 1
		else
			if [ ${_OUT_FILE}a != ${_OUT_FILE%/*}a ] && [ ! -d ${_OUT_FILE%/*} ]; then
				echo "Folder do not exist: ${_OUT_FILE%/*}"
				exit 1
			fi
		fi
	fi

	# Check DNS IP
	_IP_TEST=$(echo $_DNS_IP | grep -E '^((2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)\.){3}(2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)$')
	if [ "$_IP_TEST" != "$_DNS_IP" ]; then
		echo 'Please enter a valid DNS server IP address.'
		exit 1
	fi

	# Check DNS port
	if [ $_DNS_PORT -lt 1 -o $_DNS_PORT -gt 65535 ]; then
		echo 'Please enter a valid DNS server port.'
		exit 1
	fi

	# Check ipset name
	if [ -z $_IPSET_NAME ]; then
		_WITH_IPSET=0
	else
		_IPSET_TEST=$(echo $_IPSET_NAME | grep -E '^\w+$')
		if [ "$_IPSET_TEST" != "$_IPSET_NAME" ]; then
			echo 'Please enter a valid IP set name.'
			exit 1
		else
			_WITH_IPSET=1
		fi
	fi
}

_process(){
	_BASE_URL='https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf'
	_WORKING_DIR=`mktemp -d /tmp/generate_dnsmasq_chinalist.XXXXXX`
	_CHINA_LIST_FILE=$_WORKING_DIR/accelerated-domains.china.conf
	_TMP_FILE=$_WORKING_DIR/generate_dnsmasq_chinalist.tmp
	
	# Fetch China-List
	printf 'Fetching China-List...'
	curl -s -L $_CURL_EXTARG -o$_CHINA_LIST_FILE $_BASE_URL
	if [ $? != 0 ]; then
		printf '\033[31mFailed to fetch China-List. Please check your Internet connection.\033[m\n'
		_clean_and_exit 2
	fi
	printf ' Done.\n\n'
	
	# Convert
	if [ $_WITH_IPSET -eq 0 ]; then
		echo "Writing file to $_OUT_FILE without ipset ..."
		awk -v _dns="$_DNS_IP" -v _port="$_DNS_PORT" -F'/' '{printf("%s/%s/%s#%s\n",$1,$2,_dns,_port)}' $_CHINA_LIST_FILE > $_TMP_FILE
	else
		echo "Writing file to $_OUT_FILE with ipset ..."
		awk -v _dns="$_DNS_IP" -v _port="$_DNS_PORT" -v _ipset="$_IPSET_NAME" -F'/' '{printf("%s/%s/%s#%s\nipset=/%s/%s\n",$1,$2,_dns,_port,$2,_ipset)}' $_CHINA_LIST_FILE > $_TMP_FILE
	fi
	
	mv $_TMP_FILE $_OUT_FILE
	
	_clean_and_exit 0
}

main() {
	if [ -z "$1" ]; then
		_usage 0
	else
		_check_depends
		_get_args "$@"
		_process
	fi
}

main "$@"
