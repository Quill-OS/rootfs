#!/bin/sh

SERVER="23.163.0.39"
INSTALLED_VERSION=$(cat /opt/isa/version)
OTA_CURRENT=$(busybox wget -O - http://${SERVER}/bundles/inkbox/native/update/ota_current 2>/dev/null)
# Fully Qualified Device Identifier
FQDI=$(cat /opt/inkbox_device)

UPDATE_COMP=$(echo ${OTA_CURRENT}'>'${INSTALLED_VERSION} | bc -l)
if [ "${UPDATE_COMP}" == "1" ]; then
	echo "true" > /kobo/run/can_ota_update
	if [ "${1}" == "download" ]; then
		busybox wget "http://${SERVER}/bundles/inkbox/native/update/${OTA_CURRENT}/${FQDI}/inkbox-update-${OTA_CURRENT}.upd.isa" -O "/data/onboard/.inkbox/inkbox-update-${OTA_CURRENT}.upd.isa"
		if [ ${?} != 0 ]; then
			rm -f "/data/onboard/.inkbox/inkbox-update-${OTA_CURRENT}.upd.isa"
			echo "false" > /kobo/run/can_install_ota_update
			exit 1
		else
			echo "true" > /data/onboard/.inkbox/can_update
			rc-service update_inkbox restart
			echo "true" > /kobo/run/can_install_ota_update
		fi
	fi
else
	echo "false" > /data/onboard/.inkbox/can_update
	echo "false" > /kobo/run/can_ota_update
	exit 1
fi
