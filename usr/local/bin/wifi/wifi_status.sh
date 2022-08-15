#!/bin/sh

if [ "${DEVICE}" == "n873" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n306" ] ||  [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="eth0"
elif [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="wlan0"
else
	WIFI_DEV="eth0"
fi

WIFI_EXISTS=$(ip a | grep -o ${WIFI_DEV} | head -1)


if [ "$WIFI_EXISTS" = "$WIFI_DEV" ];then
    WIFI_IP=$(echo `ifconfig ${WIFI_DEV} 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`)
    # https://unix.stackexchange.com/questions/111841/regular-expression-in-bash-to-validate-ip-address
    if expr "$WIFI_IP" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
        echo "configured" > /run/wifi_status
    else
        echo "enabled" > /run/wifi_status
    fi
else
    echo "disabled" > /run/wifi_status
fi
exit 0
