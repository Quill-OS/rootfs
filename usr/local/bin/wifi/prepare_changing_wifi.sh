#!/bin/sh

if [ "${DEVICE}" == "n873" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n306" ] ||  [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="eth0"
elif [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="wlan0"
else
	WIFI_DEV="eth0"
fi
# I cant explain why this script cant kill connection_manager, so this file is needed. i dont want to know. please leave it :(
echo "true" > /run/stopping_wifi

killall -9 connect_to_network.sh connection_manager.sh
killall -9 connect_to_network.sh connection_manager.sh
sleep 0.3
killall -9 connection_manager.sh
killall -9 connection_manager.sh
# This needs to be separate, because it will trigger toggle off otherwise
killall -9  get_dhcp.sh smarter_time_sync.sh
killall -9  get_dhcp.sh smarter_time_sync.sh

wpa_cli disconnect; wpa_cli logoff; wpa_cli disable_network 0; wpa_cli remove_network 0; wpa_cli terminate; ip addr flush dev "${WIFI_DEV}"
killall -q dhcpcd wpa_supplicant udhcpc iwevent
killall -q dhcpcd wpa_supplicant udhcpc iwevent
sleep 0.5
killall -9 dhcpcd wpa_supplicant udhcpc iwevent

rm /run/wifi_stats
touch /run/wifi_stats

rm -f /run/wifi_logs
touch /run/wifi_logs
