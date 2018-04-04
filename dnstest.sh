#!/bin/bash

command -v bc > /dev/null || { echo "bc was not found. Please install bc."; exit 1; }
{ command -v drill > /dev/null && dig=drill; } || { command -v dig > /dev/null && dig=dig; } || { echo "dig was not found. Please install dnsutils."; exit 1; }

NAMESERVERS=`cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f 2 | sed 's/\(.*\)/&#&/'`

PROVIDERS="
1.1.1.1#cloudflare-1st 
1.0.0.1#cloudflare-2nd
8.8.8.8#google-1st
8.8.4.4#google-2nd
9.9.9.9#quad9 
208.67.222.220#opendns-1st 
208.67.222.222#opendns-2nd 
199.85.126.20#norton 
185.228.168.168#cleanbrowsing 
77.88.8.7#yandex 
176.103.130.132#adguard 
156.154.70.3#neustar 
8.26.56.26#comodo
4.2.2.4#level3-1st
4.2.2.2#level3-2nd
195.46.39.39#safedns-1st
195.46.39.40#safedns-2nd
64.6.64.6#verisign-1st
64.6.65.6#verisign-2nd
"

# Domains to test. Duplicated domains are ok
DOMAINS2TEST="www.google.com amazon.com www.reddit.com wikipedia.org gmail.com www.tabnak.ir whatsapp.com www.irib.ir"

totaldomains=0
printf "%-18s" ""
for d in $DOMAINS2TEST; do
    totaldomains=$((totaldomains + 1))
    printf "%-8s" "test$totaldomains"
done
printf "%-8s" "Average"
echo ""


for p in $NAMESERVERS $PROVIDERS; do
    pip=${p%%#*}
    pname=${p##*#}
    ftime=0

    printf "%-18s" "$pname"
    for d in $DOMAINS2TEST; do
        ttime=`$dig +tries=1 +time=2 +stats @$pip $d |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2`
        if [ -z "$ttime" ]; then
	        #let's have time out be 1s = 1000ms
	        ttime=1000
        elif [ "x$ttime" = "x0" ]; then
	        ttime=1
	    fi

        printf "%-8s" "$ttime ms"
        ftime=$((ftime + ttime))
    done
    avg=`bc -lq <<< "scale=2; $ftime/$totaldomains"`

    echo "  $avg"
done

exit 0;
