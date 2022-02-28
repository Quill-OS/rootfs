# Put system-wide fish configuration entries here
# or in .fish files in conf.d/
# Files in conf.d can be overridden by the user
# by files with the same name in $XDG_CONFIG_HOME/fish/conf.d

# This file is run by all fish instances.
# To include configuration only for login shells, use
# if status --is-login
#    ...
# end
# To include configuration only for interactive shells, use
# if status --is-interactive
#   ...
# end

set fish_greeting
if ! [ (ifsctl mnt rootfs stat) = "Root filesystem is mounted read-write." ]
        echo -e "\033[1m* Warning *\033[0m\nRoot filesystem is mounted read-only.\nInvoke `ifsctl mnt rootfs rw' to make it read-write."
end
