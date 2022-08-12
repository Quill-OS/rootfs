#!/bin/sh

killall -q dhcpcd wpa_supplicant udhcpc
killall -q dhcpcd wpa_supplicant udhcpc
sleep 0.5
killall -9 dhcpcd wpa_supplicant udhcpc

rm /run/wifi_stats
touch /run/wifi_stats
