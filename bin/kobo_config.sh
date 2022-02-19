#!/bin/sh

DEVICE=$(cat /opt/inkbox_device)

if [ "${DEVICE}" = "n705" ]; then
	echo "pixie"
elif [ "${DEVICE}" = "n905b" ] || [ "${DEVICE}" = "n905c" ] || [ "${DEVICE}" = "n905" ]; then
	echo "trilogy"
elif [ "${DEVICE}" = "n613" ]; then
	echo "daylight"
elif [ "${DEVICE}" = "n236" ]; then
	echo "star"
elif [ "${DEVICE}" = "n437" ]; then
	echo "alyssum"
elif [ "${DEVICE}" = "n306" ]; then
	echo "luna"
elif [ "${DEVICE}" = "n873" ]; then
	echo "storm"
fi
