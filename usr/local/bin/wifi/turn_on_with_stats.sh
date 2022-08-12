#!/bin/sh

rm -f /run/wifi_stats
touch /run/wifi_stats

echo -n "Turning on wifi: " >>  /run/wifi_stats
/usr/bin/time -f '%e' -a -o /run/wifi_stats /usr/local/bin/wifi/toggle.sh on

if [ ${?} != 0 ]; then
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
	echo "s - ERROR" >>  /run/wifi_stats
	exit 1
else
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
    echo "s - OK" >>  /run/wifi_stats
fi
