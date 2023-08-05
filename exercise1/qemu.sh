#!/usr/bin/env bash


# Change current working directory to location of the script
cd "$(dirname "")"
pwd -P

readonly IMG="qemu.img"

# Create the qemu-img
qemu-img create -f qcow2 ${IMG} 40G

qemu-system-x86_64 \
    -enable-kvm    \
		-m size=4G
    $IMG
