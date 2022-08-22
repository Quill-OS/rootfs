#!/bin/sh

# syntax:
# current wifi name
# ip
# mask
# default gateway

if [ "${DEVICE}" == "n873" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n306" ] ||  [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="eth0"
elif [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="wlan0"
else
	WIFI_DEV="eth0"
fi

iwgetid -r > /run/wifi_informations
ifconfig ${WIFI_DEV} 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://' >> /run/wifi_informations
/sbin/ifconfig eth0 | grep Mask | cut -d":" -f4 >> /run/wifi_informations
/sbin/ip route | awk '/default/ { print $3 }' >> /run/wifi_informations
