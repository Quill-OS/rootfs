#!/bin/sh

INSTALLED_VERSION=$(/opt/update/version)
OTA_CURRENT=$(busybox-initrd wget -O - http://pkgs.kobox.fermino.me/bundles/inkbox/native/update/ota_current 2>/dev/null)
# Fully Qualified Device Identifier
FQDI=$(cat /opt/inkbox_device)

if [ ${OTA_CURRENT} -gt ${INSTALLED_VERSION} ]; then
	echo "true" > /kobo/run/can_ota_update
	if [ "${1}" == "install" ]; then
		busybox-initrd wget "http://pkgs.kobox.fermino.me/bundles/inkbox/native/update/${OTA_CURRENT}/${FQDI}/inkbox-update-${OTA_CURRENT}.upd.isa" -O "/data/onboard/.inkbox/inkbox-update-${OTA_CURRENT}.upd.isa"
		echo "true" > /data/onboard/.inkbox/can_update
		rc-service update_inkbox restart
		echo "true" > /kobo/run/can_install_ota_update
	fi
	
else
	echo "false" > /data/onboard/.inkbox/can_update
	echo "false" > /kobo/run/can_ota_update
	exit 1
fi
