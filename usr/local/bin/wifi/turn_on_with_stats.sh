#!/bin/sh

rm -f "/run/wifi_stats"
touch "/run/wifi_stats"

rm -f "/var/log/wifi.log"
touch "/var/log/wifi.log"

echo -n "Turning Wi-Fi ON: " >> "/run/wifi_stats"
/usr/bin/time -f '%e' -q -a -o "/run/wifi_stats" /usr/local/bin/wifi/toggle.sh on >> "/var/log/wifi.log" 2>&1

if [ ${?} != 0 ]; then
	# Remove the newline, also it's here to prevent changing the exit code
	truncate -s -1 "/run/wifi_stats"
	echo "s - ERROR" >> "/run/wifi_stats"
	exit 1
else
	# Same thing here
	truncate -s -1 "/run/wifi_stats"
	echo "s - OK" >> "/run/wifi_stats"
fi

iwevent >> "/var/log/wifi.log" &
