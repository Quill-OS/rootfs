set fish_greeting
if status --is-interactive
	if ! [ (ifsctl mnt rootfs stat) = "Root filesystem is mounted read-write." ]
	        echo -e "\033[1m* Warning *\033[0m\nRoot filesystem is mounted read-only.\nInvoke `ifsctl mnt rootfs rw' to make it read-write."
	end
end
