#!/bin/sh

DEVICE="$(cat /opt/inkbox_device)"

if [ "${DEVICE}" == "n873" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n306" ] ||  [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="eth0"
elif [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "n249" ] || [ "${DEVICE}" == "n418" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="wlan0"
else
	WIFI_DEV="eth0"
fi
# I can't figure out why this script can't kill connection_manager, so this file is needed.
echo "true" > "/run/stopping_wifi"

killall -9 connect_to_network.sh connection_manager.sh check_wifi_passphrase.sh prepare_network.sh
killall -9 connect_to_network.sh connection_manager.sh check_wifi_passphrase.sh prepare_network.sh
sleep 0.3
killall -9 connection_manager.sh
killall -9 connection_manager.sh
# This needs to be separate, because it will trigger toggle off otherwise
killall -9  get_dhcp.sh timesync.sh check_wifi_passphrase.sh prepare_network.sh
killall -9  get_dhcp.sh timesync.sh check_wifi_passphrase.sh prepare_network.sh

wpa_cli disconnect; wpa_cli logoff; wpa_cli disable_network 0; wpa_cli remove_network 0; wpa_cli terminate; ip addr flush dev "${WIFI_DEV}"

killall -q dhcpcd wpa_supplicant udhcpc iwevent
killall -q dhcpcd wpa_supplicant udhcpc iwevent
sleep 0.5
killall -9 dhcpcd wpa_supplicant udhcpc iwevent

rm -f "/run/was_connected_to_wifi"
