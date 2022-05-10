#!/bin/sh

ntpd -n -q
hwclock --systohc -u
