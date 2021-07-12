#!/bin/bash

if [ -z "${GITDIR}" ]; then
	echo "Please specify the GITDIR environment variable."
	exit 1
fi
if [ ${EUID} != 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

cd "${GITDIR}"
find . -type f -name ".keep" -exec rm {} \;
rm -f ../rootfs.squashfs
mksquashfs . ../rootfs.squashfs -b 1048576 -comp gzip -always-use-fragments -e .git -e release.sh
find . -type d ! -path "*.git*" -empty -exec touch '{}'/.keep \;
echo "Root filesystem has been compressed."

