#!/bin/sh

ROOTFS_STATUS=$(/usr/bin/ifsctl mnt rootfs stat)

if [ "$ROOTFS_STATUS" != "Root filesystem is mounted read-write." ]; then
        echo -e "\033[1m* Warning *\033[0m\nRoot filesystem is mounted read-only.\nInvoke \`ifsctl mnt rootfs rw' to make it read-write."
fi
