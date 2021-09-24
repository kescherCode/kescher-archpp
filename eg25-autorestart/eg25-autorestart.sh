#!/usr/bin/env bash

msg() {
	printf "%s\n" "$@"
}

err() {
	printf "%s\n" "$@" 1>&2
}

errexit() {
	printf "%s\n" "$@" 1>&2
	exit 1
}

prefix="/dev/serial/by-id"
devices=("usb-Quectel_EG25-G-if0" "usb-Quectel__Incorporated_LTE_Module_*-if0")
suffix="-port0"

if ! systemctl -q is-active eg25-manager; then
    errexit "eg25-manager is not active, refusing to check for the modem"
fi

if [ -d "$prefix" ]; then
    for device in "${devices[@]}"; do
        for i in {0..3}; do
            # shellcheck disable=SC2027,SC2086
            if [ -L "$prefix/"$device"$i""$suffix" ]; then
                # Found a symlink, check if all links exist for this device
                for j in {1..3}; do
                    # shellcheck disable=SC2027,SC2086
                    if [ ! -L "$prefix/"$device"$j""$suffix" ]; then
                        break 2
                    fi
                done
                msg "All modem devices found."
                exit
            fi
        done
    done
fi

# Either the prefix path did not exist, or no complete set of symlinks
# could be found under any device name; restart modem.
msg "Not all modem devices were found."

modem_manager=()
if systemctl -q is-enabled ModemManager; then
    modem_manager+=(ModemManager)
elif systemctl -q is-enabled ofono; then
    modem_manager+=(ofono)
else
    if [[ $- == *i* ]]; then
        err "Unknown modem manager, please restart the modem manager yourself after this script has run."
    else
        errexit "Unknown modem manager, refusing to restart modem."
    fi
fi

log_message="Stopping: eg25-manager"
for m in "${modem_manager[@]}"; do
    log_message="$log_message $m"
done
msg "$log_message"
unset log_message
systemctl stop eg25-manager "${modem_manager[@]}"
sleep 2
msg "Resetting the modem..."

# The following is modified work from Dreemurrs Embedded Labs / DanctNIX Community, Copyright (C) 2020.
# The original work is available at:
# https://github.com/dreemurrs-embedded/Pine64-Arch/blob/1f587391b4ac2e8d72c8b69cf2283a3310e14bb3/PKGBUILDS/pine64/danctnix-eg25-misc/eg25_power.sh

# GPIO35 is PWRKEY
# GPIO68 is RESET_N
# GPIO232 is W_DISABLE

for i in 35 68 232
do
    [[ -e /sys/class/gpio/gpio$i ]] && continue
    echo $i > /sys/class/gpio/export || errexit "Failed exporting GPIO$i!"
    echo out > /sys/class/gpio/gpio$i/direction || errexit "Failed setting GPIO$i direction to out!"
done

echo 1 > /sys/class/gpio/gpio68/value || errexit "Failed setting RESET_N GPIO!"
echo 1 > /sys/class/gpio/gpio232/value || errexit "Failed setting W_DISABLE GPIO!"

echo 1 > /sys/class/gpio/gpio35/value || errexit "Failed setting PWRKEY GPIO!"
sleep 2
echo 0 > /sys/class/gpio/gpio35/value || errexit "Failed unsetting PWRKEY GPIO!"

if grep -q 1.1 /proc/device-tree/model
then
    # Intentional delay on Braveheart
    # As modem gets corrupted very easily on that model.
    msg "Braveheart model detected - sleeping 30 seconds to prevent modem flash corruption"
    sleep 30
else
    sleep 2
fi

echo 0 > /sys/class/gpio/gpio68/value || errexit "Failed unsetting RESET_N GPIO!"
echo 0 > /sys/class/gpio/gpio232/value || errexit "Failed unsetting W_DISABLE GPIO!"

echo 1 > /sys/class/gpio/gpio35/value || errexit "Failed setting PWRKEY GPIO!"
sleep 2
echo 0 > /sys/class/gpio/gpio35/value || errexit "Failed unsetting PWRKEY GPIO!"

sleep 2

for i in 35 68 232
do
        [[ ! -e /sys/class/gpio/gpio$i ]] && continue
        echo $i > /sys/class/gpio/unexport || errexit "Failed unexporting GPIO$i!"
done

log_message="Starting: eg25-manager"
for m in "${modem_manager[@]}"; do
    log_message="$log_message $m"
done
msg "$log_message"
unset log_message
systemctl restart "${modem_manager[@]}" eg25-manager
