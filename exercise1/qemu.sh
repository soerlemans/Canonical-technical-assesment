#!/usr/bin/env bash

<<EOF
This script assumes that you have qemu, gcc preinstalled.
EOF

# Change current working directory to location of the script
cd "$(dirname "")"
pwd -P

# Readonly variables:
readonly TMP_DIR="${TMP:-tmp}"

readonly ROOTFS_DIR="${TMP_DIR}/rootfs"
readonly ROOTFS="rootfs.cpio"
readonly ROOTFS_PATH="${TMP_DIR}/${ROOTFS}"

readonly KERNEL_VERSION="${KERNEL_VERSION:-6.4}"
readonly KERNEL_URL="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/linux-${KERNEL_VERSION}.tar.gz"
readonly KERNEL_PATH="${TMP_DIR}/kernel.tar.gz"

# Functions:

# Start of script:
mkdir -p "${TMP_DIR}"

# Create root filesystem
echo "Creating root filesystem ($ROOTFS)..."
mkdir -p "${ROOTFS_DIR}"
cc -static init.c -o "${ROOTFS_DIR}/init"

# Use a subshell to cleanly enter
(
	cd "${TMP_DIR}/rootfs"

	# Copy files in the rootfs folder to an archive and compress it
	find | cpio --quiet --create --format=newc | bzip2 --stdout >../$ROOTFS
)
echo

echo "Downloading Linux kernel ($KERNEL_VERSION)..."
wget --output-document="$KERNEL_PATH" \
	--quiet \
	--show-progress \
	"$KERNEL_URL"
echo

echo "Compile kernel..."
(
	cd "$TMP_DIR"
	tar -xzvf "$KERNEL_PATH"

	cd 
)

echo "Start QEMU..."
qemu-system-x86_64 \
	-kernel "${KERNEL_PATH}" \
	-initrd "${ROOTFS_PATH}"
