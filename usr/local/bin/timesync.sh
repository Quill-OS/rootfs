#!/bin/sh

ntpdate 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
if [ ${?} != 0 ]; then
	echo "Failed to connect to NTP servers"
fi
hwclock --systohc -u
if [ ${?} != 0 ]; then
	echo "Failed to sync device clock"
fi
exit 0
