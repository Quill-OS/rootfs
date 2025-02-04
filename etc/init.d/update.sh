#!/bin/sh

#    update.sh: Update InkBox packages
#    Copyright (C) 2021-2025 Nicolas Mailloux <nicolecrivain@gmail.com>
#    SPDX-License-Identifier: GPL-3.0-only
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

DEVICE=$(cat /opt/inkbox_device 2>/dev/null)
if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "n306" ] || [ "${DEVICE}" == "n249" ] || [ "${DEVICE}" == "kt" ]; then
        ROOTFS_FMT="ext4"
        RECOVERYFS_PART=2
elif [ "${DEVICE}" == "n873" ]; then
        ROOTFS_FMT="vfat"
        RECOVERYFS_PART=5
else
        ROOTFS_FMT="ext4"
        RECOVERYFS_PART=2
fi

ROOT=$(cat /opt/root/rooted 2>/dev/null)
ALLOW_DOWNGRADE=$(cat /boot/flags/ALLOW_DOWNGRADE 2>/dev/null)

RAND_MNT_NUM=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 10)
BASEPATH="/tmp/update-${RAND_MNT_NUM}"
WRITEABLE_BASEPATH="/data/onboard/.inkbox"

mkdir -p "${WRITEABLE_BASEPATH}"

ISA_PACKAGE=$(ls "${WRITEABLE_BASEPATH}/"*".upd.isa" 2>/dev/null)
UPDATE_DIR="/opt/update"
UI_BUNDLE="${BASEPATH}/update.isa"
UI_BUNDLE_DGST="${UI_BUNDLE}.dgst"
GUI_ROOTFS="${BASEPATH}/gui_rootfs.isa"
GUI_ROOTFS_DGST="${GUI_ROOTFS}.dgst"
ROOTFS="${BASEPATH}/rootfs.squashfs"
ROOTFS_DGST="${ROOTFS}.dgst"
RECOVERYFS="${BASEPATH}/recoveryfs.squashfs"
RECOVERYFS_DGST="${RECOVERYFS}.dgst"
X11_BASE_ROOTFS="${BASEPATH}/X11/base.img"
X11_BASE_ROOTFS_DGST="${X11_BASE_ROOTFS}.dgst"
X11_EXTENSIONS_ROOTFS="${BASEPATH}/X11/extensions-base.img"
X11_EXTENSIONS_ROOTFS_DGST="${X11_EXTENSIONS_ROOTFS}.dgst"
U_BOOT="${BASEPATH}/u-boot_inkbox.bin"
U_BOOT_DGST="${U_BOOT}.dgst"

if grep -q "true" /opt/root/rooted &>/dev/null; then
	KERNEL_TYPE="root"
else
	KERNEL_TYPE="std"
fi

if [ "${DEVICE}" != "n306" ] && [ "${DEVICE}" != "n249" ] && [ "${DEVICE}" != "n873" ] && [ "${DEVICE}" != "n418" ]; then
	KERNEL_IMAGE_TYPE="uImage"
else
	KERNEL_IMAGE_TYPE="zImage"
fi

KERNEL="${BASEPATH}/${KERNEL_IMAGE_TYPE}-${KERNEL_TYPE}-${DEVICE}"
KERNEL_DGST="${KERNEL}.dgst"
DIAGS_KERNEL="${BASEPATH}/${KERNEL_IMAGE_TYPE}-diags-${DEVICE}"
DIAGS_KERNEL_DGST="${DIAGS_KERNEL}.dgst"

REBOOT_FLAG=0

error_msg() {
	VALIDATION_ERROR_MSG="FATAL: ${SUB_VERIFIED} validation failed. Aborting ..."
	echo "${VALIDATION_ERROR_MSG}"
}

write_alert() {
	echo "true" > /boot/flags/ALERT
	if [ "${1}" == "illegal_downgrade" ]; then
		echo "true" > /boot/flags/ALERT_DOWNGRADE
	elif [ "${1}" == "signature" ]; then
		echo "true" > /boot/flags/ALERT_SIGN
	elif [ "${1}" == "invalid_package" ]; then
		echo "true" > /boot/flags/ALERT_INVALID_UPDATE_PACKAGE
	fi
	sync
	rm /opt/update/will_update
	echo "false" > /boot/flags/WILL_UPDATE
	echo "false" > /opt/update/will_update
	sync
	return 0
}

apply_update_ui_bundle() {
	echo "Updating from InkBox ${CURRENT_VERSION} to InkBox ${NEXT_VERSION} ..."
	cp "${UI_BUNDLE}" "${UPDATE_DIR}"
	sync
	rm /opt/update/will_update
	echo "true" > "${UPDATE_DIR}/inkbox_updated"
	echo "false" > /boot/flags/WILL_UPDATE
	echo "false" > /opt/update/will_update
	sync
	return 0
}

update_ui_bundle() {
	openssl dgst -sha256 -verify /opt/key/public.pem -signature "${UI_BUNDLE_DGST}" "${UI_BUNDLE}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${UI_BUNDLE}"
		error_msg
		write_alert signature
		exit 1
	else
		mkdir -p /tmp/update/current
		mkdir -p /tmp/update/next
		squashfuse /opt/update/update.isa /tmp/update/current
		squashfuse "${UI_BUNDLE}" /tmp/update/next
		CURRENT_VERSION=$(cat /tmp/update/current/version)
		NEXT_VERSION=$(cat /tmp/update/next/version)
		umount -l -f /tmp/update/current
		umount -l -f /tmp/update/next
		ILLEGAL_DOWNGRADE=$(echo ${NEXT_VERSION}'<'${CURRENT_VERSION} | bc -l)
		if [ "${ILLEGAL_DOWNGRADE}" == "1" ]; then
			if [ "${ROOT}" == "true" ]; then
				if [ "${ALLOW_DOWNGRADE}" == "true" ]; then
					apply_update_ui_bundle
					return 0
				else
					write_alert illegal_downgrade
					exit 1
				fi
			else
				write_alert illegal_downgrade
				exit 1
			fi
		else
			apply_update_ui_bundle
			echo "${NEXT_VERSION}" > /opt/update/version
			sync
			return 0
		fi
	fi
}

update_x11_base_rootfs() {
	openssl dgst -sha256 -verify /opt/key/kobox-graphic-public.pem -signature "${X11_BASE_ROOTFS_DGST}" "${X11_BASE_ROOTFS}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${X11_BASE_ROOTFS}"
		error_msg
		write_alert signature
		exit 1
	else
		umount -l -f /xorg 2>/dev/null
		cp "${X11_BASE_ROOTFS}" /data/storage/X11/base.img
		rm /opt/update/will_update
		echo "true" > "${UPDATE_DIR}/inkbox_updated"
		echo "false" > /boot/flags/WILL_UPDATE
		echo "false" > /opt/update/will_update
		sync
		REBOOT_FLAG=1
		return 0
	fi
}

update_x11_extensions_rootfs() {
	openssl dgst -sha256 -verify /opt/key/kobox-graphic-public.pem -signature "${X11_EXTENSIONS_ROOTFS_DGST}" "${X11_EXTENSIONS_ROOTFS}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${X11_EXTENSIONS_ROOTFS}"
		error_msg
		write_alert signature
		exit 1
	else
		umount -l -f /xorg 2>/dev/null
		cp "${X11_EXTENSIONS_ROOTFS}" /data/storage/X11/extensions-base.img
		rm /opt/update/will_update
		echo "true" > "${UPDATE_DIR}/inkbox_updated"
		echo "false" > /boot/flags/WILL_UPDATE
		echo "false" > /opt/update/will_update
		sync
		REBOOT_FLAG=1
		return 0
	fi
}

update_gui_rootfs() {
	openssl dgst -sha256 -verify /opt/key/public.pem -signature "${GUI_ROOTFS_DGST}" "${GUI_ROOTFS}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${GUI_ROOTFS}"
		error_msg
		write_alert signature
		exit 1
	else
		umount -l -f /kobo 2>/dev/null
		cp "${GUI_ROOTFS}" /data/storage/gui_rootfs.isa
		cp "${GUI_ROOTFS_DGST}" /data/storage/gui_rootfs.isa.dgst
		rm /opt/update/will_update
		echo "true" > "${UPDATE_DIR}/inkbox_updated"
		echo "false" > /boot/flags/WILL_UPDATE
		echo "false" > /opt/update/will_update
		sync
		REBOOT_FLAG=1
		return 0
	fi
}

update_u_boot() {
	openssl dgst -sha256 -verify /opt/key/public.pem -signature "${U_BOOT_DGST}" "${U_BOOT}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${U_BOOT}"
		error_msg
		write_alert signature
		exit 1
	else
		if [ "${DEVICE}" != "n306" ] && [ "${DEVICE}" != "n249" ] && [ "${DEVICE}" != "n418" ]; then
			dd if="${U_BOOT}" of=/dev/mmcblk0 bs=1K seek=1 skip=1
		else
			dd if="${U_BOOT}" of=/dev/mmcblk0 bs=1K seek=1
		fi
		rm /opt/update/will_update
		echo "true" > "${UPDATE_DIR}/inkbox_updated"
		echo "false" > /boot/flags/WILL_UPDATE
		echo "false" > /opt/update/will_update
		sync
		REBOOT_FLAG=1
		return 0
	fi
}

update_kernel() {
	openssl dgst -sha256 -verify /opt/key/public.pem -signature "${KERNEL_DGST}" "${KERNEL}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${KERNEL}"
		error_msg
		write_alert signature
		exit 1
	else
		if [ "${DEVICE}" == "kt" ]; then
			dd if="${KERNEL}" of=/dev/mmcblk0 bs=512 seek=520
		elif [ "${DEVICE}" == "n249" ] || [ "${DEVICE}" == "n418" ]; then
			cp "${KERNEL}" /boot/zImage
		else
			dd if="${KERNEL}" of=/dev/mmcblk0 bs=512 seek=81920
		fi
		rm /opt/update/will_update
		echo "true" > "${UPDATE_DIR}/inkbox_updated"
		echo "false" > /boot/flags/WILL_UPDATE
		echo "false" > /opt/update/will_update
		sync
		REBOOT_FLAG=1
		return 0
	fi
}

update_diags_kernel() {
	openssl dgst -sha256 -verify /opt/key/public.pem -signature "${DIAGS_KERNEL_DGST}" "${DIAGS_KERNEL}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${DIAGS_KERNEL}"
		error_msg
		write_alert signature
		exit 1
	else
		if [ "${DEVICE}" == "kt" ]; then
			dd if="${DIAGS_KERNEL}" of=/dev/mmcblk0 bs=512 seek=29192
		else
			dd if="${DIAGS_KERNEL}" of=/dev/mmcblk0 bs=512 seek=19456
		fi
		rm /opt/update/will_update
		echo "true" > "${UPDATE_DIR}/inkbox_updated"
		echo "false" > /boot/flags/WILL_UPDATE
		echo "false" > /opt/update/will_update
		sync
		return 0
	fi
}

update_overlaymount_rootfs() {
	openssl dgst -sha256 -verify /opt/key/public.pem -signature "${OVERLAYMOUNT_ROOTFS}" "${OVERLAYMOUNT_ROOTFS_DGST}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${OVERLAYMOUNT_ROOTFS}"
		error_msg
		write_alert signature
		exit 1
	else
		mkdir -p /tmp/update/rootfs
		mkdir -p /tmp/update/recoveryfs
		mount -t "${ROOTFS_FMT}" -o noexec,nosuid,nodev /dev/mmcblk0p3 /tmp/update/rootfs
		mount -t ext4 -o noexec,nosuid,nodev "/dev/mmcblk0p${RECOVERYFS_PART}" /tmp/update/recoveryfs
		cp "${OVERLAYMOUNT_ROOTFS}" /tmp/update/rootfs/overlaymount-rootfs.squashfs
		cp "${OVERLAYMOUNT_ROOTFS_DGST}" /tmp/update/rootfs/overlaymount-rootfs.squashfs.dgst
		cp "${OVERLAYMOUNT_ROOTFS}" /tmp/update/recoveryfs/overlaymount-rootfs.squashfs
		cp "${OVERLAYMOUNT_ROOTFS_DGST}" /tmp/update/recoveryfs/overlaymount-rootfs.squashfs.dgst
		sync
		umount /tmp/update/rootfs -l -f
		umount /tmp/update/recoveryfs -l -f
		sync
		rm /opt/update/will_update
		echo "true" > "${UPDATE_DIR}/inkbox_updated"
		echo "false" > /boot/flags/WILL_UPDATE
		echo "false" > /opt/update/will_update
		sync
		return 0
	fi
}

update_recoveryfs() {
	openssl dgst -sha256 -verify /opt/key/public.pem -signature "${RECOVERYFS_DGST}" "${RECOVERYFS}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${RECOVERYFS}"
		error_msg
		write_alert signature
		exit 1
	else
		mkdir -p /tmp/update/recoveryfs
		mount -t ext4 -o noexec,nosuid,nodev /dev/mmcblk0p2 /tmp/update/recoveryfs
		cp "${RECOVERYFS}" /tmp/update/recoveryfs/recoveryfs.squashfs
		cp "${RECOVERYFS_DGST}" /tmp/update/recoveryfs/recoveryfs.squashfs.dgst
		sync
		umount /tmp/update/recoveryfs -l -f
		sync
		rm /opt/update/will_update
		echo "true" > "${UPDATE_DIR}/inkbox_updated"
		echo "false" > /boot/flags/WILL_UPDATE
		echo "false" > /opt/update/will_update
		sync
		return 0
	fi
}

update_rootfs() {
	openssl dgst -sha256 -verify /opt/key/public.pem -signature "${ROOTFS_DGST}" "${ROOTFS}"
	if [ ${?} != 0 ]; then
		SUB_VERIFIED="${ROOTFS}"
		write_alert signature
		error_msg
		exit 1
	else
		echo "${BASEPATH}" > /run/update_package_mountpoint
		sync
		rm /opt/update/will_update
		echo "true" > "${UPDATE_DIR}/inkbox_updated"
		echo "false" > /boot/flags/WILL_UPDATE
		echo "false" > /opt/update/will_update
		sync
		killall update-splash
		exit 25
	fi
}

if [ -e "${ISA_PACKAGE}" ]; then
	echo "true" > "${WRITEABLE_BASEPATH}/can_update"
fi

if grep -q "true" "${WRITEABLE_BASEPATH}/can_update" &>/dev/null; then
	CAN_UPDATE=1
	if grep -q "true" "${WRITEABLE_BASEPATH}/can_really_update" &>/dev/null; then
		CAN_REALLY_UPDATE=1
	else
		CAN_REALLY_UPDATE=0
	fi
else
	CAN_UPDATE=0
fi

if [ ${CAN_UPDATE} == 1 ]; then
	if [ ${CAN_REALLY_UPDATE} == 1 ]; then
		if [ -e "${ISA_PACKAGE}" ]; then
			mkdir -p "${BASEPATH}"
			squashfuse "${ISA_PACKAGE}" "${BASEPATH}"
			if [ ${?} != 0 ]; then
				echo "FATAL: Error mounting ISA update package. Aborting ..."
				write_alert invalid_package
				exit 1
			else
				if [ -e "${UI_BUNDLE}" ]; then
					echo "Updating UI bundle ..."
					update_ui_bundle
				fi
				if [ -e "${X11_BASE_ROOTFS}" ]; then
					echo "Updating X11 base root filesystem ..."
					update_x11_base_rootfs
				fi
				if [ -e "${X11_EXTENSIONS_BASE_ROOTFS}" ]; then
					echo "Updating X11 extensions root filesystem ..."
					update_x11_extensions_rootfs
				fi
				if [ -e "${GUI_ROOTFS}" ]; then
					echo "Updating GUI rootfs ..."
					update_gui_rootfs
				fi
				if [ -e "${U_BOOT}" ]; then
					echo "Updating U-Boot ..."
					update_u_boot
				fi
				if [ -e "${KERNEL}" ]; then
					echo "Updating 'Main' Linux kernel ..."
					update_kernel
				fi
				if [ -e "${DIAGS_KERNEL}" ]; then
					echo "Updating 'Basic Diagnostics' Linux kernel ..."
					update_diags_kernel
				fi
				if [ -e "${OVERLAYMOUNT_ROOTFS}" ]; then
					echo "Updating overlay mount root filesystem ..."
					update_overlaymount_rootfs
				fi
				if [ -e "${RECOVERYFS}" ]; then
					echo "Updating recovery filesystem ..."
					update_recoveryfs
				fi
				if [ -e "${ROOTFS}" ]; then
					echo "Updating root filesystem ..."
					update_rootfs
				fi
			fi
			umount -l -f "${BASEPATH}"
			rm -rf "${BASEPATH}"
			rm -f "${ISA_PACKAGE}"
			if [ ${REBOOT_FLAG} == 1 ]; then
				reboot no_splash
			fi
		fi
		sync
	fi
else
	echo "Update skipped or no update available, aborting ..."
	echo "false" > "${UPDATE_DIR}/inkbox_updated"
	exit 0
fi

exit 0
