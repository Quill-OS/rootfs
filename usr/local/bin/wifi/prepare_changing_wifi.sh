#!/bin/sh

killall -9 connect_to_network.sh connection_manager.sh only_connect_to_network.sh smarter_time_sync.sh
killall -q dhcpcd wpa_supplicant udhcpc
killall -q dhcpcd wpa_supplicant udhcpc
sleep 0.5
killall -9 dhcpcd wpa_supplicant udhcpc

rm /run/wifi_stats
touch /run/wifi_stats

rm -f /run/wifi_logs
touch /run/wifi_logs
