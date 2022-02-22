#!/bin/sh

RAND_STR=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 10)
SF="/tmp/sysreport-${RAND_STR}"

touch "${SF}"

# Heading
echo "<h1>InkBox OS system report</h1>" >> "${SF}"
echo "<i>Generated on $(date)</i>" >> "${SF}"

# General info
echo "<h2>General</h2>" >> "${SF}"
echo "<b>InkBox OS version: <code>$(cat /opt/version)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Version control info:</b>" >> "${SF}"
echo "<ul>" >> "${SF}"
echo "<li><b>GUI: <code>$(cat /run/inkbox_gui_git_commit)</code></b></li>" >> "${SF}"
echo "<li><b>Root filesystem: <code>$(cat /.commit | head -c 7)</code></b></li>" >> "${SF}"
echo "<li><b>Kernel: <code>$(echo 'get_kernel_commit' > /run/initrd-fifo; sleep 0.1; cat /run/kernel_commit)</code></b></li>" >> "${SF}"
echo "</ul>" >> "${SF}"
echo "<b>Device: <code>$(cat /opt/inkbox_device)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Kernel type: <code>$(if grep -q "true" /opt/root/rooted 2>/dev/null; then echo "Root"; else echo "Standard"; fi)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Kernel build ID: <code>$(echo 'get_kernel_build_id' > /run/initrd-fifo; sleep 0.1; cat /run/kernel_build_id)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Kernel version: <code>$(uname -r)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Kernel build info: <code>$(uname -v)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Developer key: <code>$(if grep -q "true" /opt/developer/key/valid-key 2>/dev/null; then echo "Yes"; else echo "No"; fi)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>System uptime: <code>$(awk '{print int($1/86400)"d "int($1%86400/3600)"h "int(($1%3600)/60)"m "int($1%60)"s"}' /proc/uptime)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"

# Filesystems
echo "<h2>Filesystems</h2>" >> "${SF}"
echo "<b>Onboard storage: <code>$(cd /data/onboard; df -Ph . | tail -1 | awk '{print $3}'; cd - &>/dev/null)/$(cd /data/onboard; df -Ph . | tail -1 | awk '{print $2}'; cd - &>/dev/null)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Boot partition: <code>$(cd /boot; df -Ph . | tail -1 | awk '{print $3}'; cd - &>/dev/null)/$(cd /boot; df -Ph . | tail -1 | awk '{print $2}'; cd - &>/dev/null)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Recovery partition: <code>$(mount /dev/mmcblk0p2 -o ro,nosuid,noexec /mnt; cd /mnt; df -Ph . | tail -1 | awk '{print $3}'; cd - &>/dev/null; umount -l -f /mnt)/$(mount /dev/mmcblk0p2 -o ro,nosuid,noexec /mnt; cd /mnt; df -Ph . | tail -1 | awk '{print $2}'; cd - &>/dev/null; umount -l -f /mnt)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Root filesystem partition: <code>$(mount /dev/mmcblk0p3 -o ro,nosuid,noexec /mnt; cd /mnt; df -Ph . | tail -1 | awk '{print $3}'; cd - &>/dev/null; umount -l -f /mnt)/$(mount /dev/mmcblk0p3 -o ro,nosuid,noexec /mnt; cd /mnt; df -Ph . | tail -1 | awk '{print $2}'; cd - &>/dev/null; umount -l -f /mnt)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>User data partition: <code>$(cd /data/storage; df -Ph . | tail -1 | awk '{print $3}'; cd - &>/dev/null)/$(cd /data/storage; df -Ph . | tail -1 | awk '{print $2}'; cd - &>/dev/null)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"

# KoBox/X11
echo "<h2>KoBox/X11</h2>" >> "${SF}"
echo "<b>Enabled: <code>$(if grep -q "true" /boot/flags/X11_START 2>/dev/null; then echo "Yes"; else echo "No"; fi)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"
echo "<b>Running: <code>$(if grep -q "true" /boot/flags/X11_STARTED 2>/dev/null; then echo "Yes"; else echo "No"; fi)</code></b>" >> "${SF}"
echo "<br>" >> "${SF}"

mv "${SF}" "/tmp/sysreport.html"
htmldoc -f sysreport.pdf sysreport.html --no-toc --no-title --fontsize 15 --fontspacing 1.5
