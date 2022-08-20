#!/bin/bash

# https://superuser.com/questions/903464/wpa-supplicant-detecting-that-my-password-is-incorrect
function waitFunction {
    while true
    do
        sleep 1
    done
}

exitcode=0

function watchForPassword {
    (waitFunction) || exit $? | wpa_cli | while read line
    do
        case "$line" in
            *'4-Way Handshake failed'*)
                echo "Incorrect key for network"
                exitcode=1
                return
            ;;
            *'CTRL-EVENT-CONNECTED'*)
                echo "Connected to network"
                exitcode=0
                return
            ;;
            *)
				# More logs
				echo "$line" >> /run/wifi_logs
            ;;
        esac
    done
}

watchForPassword

exit $exitcode
