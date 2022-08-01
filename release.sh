#!/bin/bash

if [ -z "${GITDIR}" ]; then
	echo "Please specify the GITDIR environment variable."
	exit 1
fi

cd "${GITDIR}"
git rev-parse HEAD > ./.commit
chmod u+s "${GITDIR}/bin/busybox"
find . -type f -name ".keep" -exec rm {} \;
rm -f ../rootfs.squashfs
mksquashfs . ../rootfs.squashfs -b 1048576 -comp xz -Xdict-size 100% -always-use-fragments -all-root -e .git -e .gitignore -e release.sh
rm ./.commit
find . -type d ! -path "*.git*" -empty -exec touch '{}'/.keep \;
echo "Root filesystem has been compressed."

