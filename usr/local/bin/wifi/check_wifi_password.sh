#!/bin/bash

# https://superuser.com/questions/903464/wpa-supplicant-detecting-that-my-password-is-incorrect
# TODO: Find a way to exit the subshell without using killall

function waitFunction {
	while true; do
		sleep 0.2
	done
}

function watchForPassword {
	(waitFunction) | wpa_cli | while read line; do
		case "${line}" in
			*'4-Way Handshake failed'*)
				echo "Incorrect key for network"
				echo "false" > "/run/correct_wifi_password"
				killall -9 check_wifi_password.sh
				;;
			*'CTRL-EVENT-CONNECTED'*)
				echo "Connected to network"
				echo "true" > "/run/correct_wifi_password"
				killall -9 check_wifi_password.sh
				;;
			*)
				# More logs
				echo "${line}" >> "/var/log/wifi.log"
				;;
		esac
	done
}

wpa_cli disable_network 0 > /dev/null
wpa_cli enable_network 0 > /dev/null

watchForPassword

exit 1
