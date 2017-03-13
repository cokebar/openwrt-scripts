#!/bin/sh

# version: 0.0.1

set -e -o pipefail

wget -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | \
    awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > \
    /tmp/chinadns_chnroute.txt

mv /tmp/chinadns_chnroute.txt /etc/

if pidof ss-redir>/dev/null; then
    /etc/init.d/shadowsocks restart
fi
