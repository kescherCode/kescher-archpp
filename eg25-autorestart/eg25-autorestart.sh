#!/usr/bin/env bash

prefix="/dev/serial/by-id"
devices=("usb-Quectel_EG25-G-if0" "usb-Quectel__Incorporated_LTE_Module_*-if0")
suffix="-port0"

if ! systemctl -q is-active eg25-manager; then
    exit
fi

if [ -d "$prefix" ]; then
    for device in "${devices[@]}"; do
        for i in {0..3}; do
            if [ -L "$prefix/"$device"$i""$suffix" ]; then
                # Found a symlink, check if all links exist for this device
                for j in {0..3}; do
                    if [ ! -L "$prefix/"$device"$j""$suffix" ]; then
                        break 2
                    fi
                done
                # All links found, no need to restart modem
                exit
            fi
        done
    done
fi

# Either the prefix path did not exist, or no complete set of symlinks
# could be found under any device name; restart modem.

modem_manager=()
if systemctl -q is-enabled ModemManager; then
    modem_manager+=(ModemManager)
elif systemctl -q is-enabled ofono; then
    modem_manager+=(ofono)
fi

systemctl stop eg25-manager "${modem_manager[@]}"
sleep 2

# The following is modified work from Dreemurrs Embedded Labs / DanctNIX Community, Copyright (C) 2020.
# The original work is available at:
# https://github.com/dreemurrs-embedded/Pine64-Arch/blob/1f587391b4ac2e8d72c8b69cf2283a3310e14bb3/PKGBUILDS/pine64/danctnix-eg25-misc/eg25_power.sh

# GPIO35 is PWRKEY
# GPIO68 is RESET_N
# GPIO232 is W_DISABLE

for i in 35 68 232
do
    [ -e /sys/class/gpio/gpio$i ] && continue
    echo $i > /sys/class/gpio/export || exit 1
    echo out > /sys/class/gpio/gpio$i/direction || exit 1
done

echo 1 > /sys/class/gpio/gpio68/value
echo 1 > /sys/class/gpio/gpio232/value

echo 1 > /sys/class/gpio/gpio35/value && sleep 2 && echo 0 > /sys/class/gpio/gpio35/value

if grep -q 1.1 /proc/device-tree/model
then
    # Intentional delay on Braveheart
    # As modem gets corrupted very easily on that model.
    sleep 30
else
    sleep 2
fi

echo 0 > /sys/class/gpio/gpio68/value || exit 1
echo 0 > /sys/class/gpio/gpio232/value || exit 1

( echo 1 > /sys/class/gpio/gpio35/value && sleep 2 && echo 0 > /sys/class/gpio/gpio35/value ) || exit 1

sleep 2

for i in 35 68 232
do
        [ ! -e /sys/class/gpio/gpio$i ] && continue
        echo $i > /sys/class/gpio/unexport || exit 1
done

systemctl restart "${modem_manager[@]}" eg25-manager
