#!/bin/bash

cd "$(dirname ""${0}"")"
git rev-parse HEAD > ./.commit
chmod u+s "bin/busybox"
find . -type f -name ".keep" -exec rm {} \;
rm -f ../rootfs.squashfs
mksquashfs . ../rootfs.squashfs -b 1048576 -comp xz -Xdict-size 100% -always-use-fragments -all-root -e .git -e .gitignore -e .vscode -e release.sh
rm ./.commit
find . -type d ! -path "*.git*" -empty -exec touch '{}'/.keep \;
echo "Root filesystem has been compressed."

