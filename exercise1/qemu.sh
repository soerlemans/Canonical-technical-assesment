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

# Functions:
function download_kernel {
	local KERNEL_VERSION="${1:-6.4}"
	local KERNEL="${2:-kernel.tar.gz}"
	local KERNEL_URL="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/linux-${KERNEL_VERSION}.tar.gz"

	if [[ ! -f "$1" ]]; then
		echo "Downloading Linux kernel (version $2)..."

		wget --output-document="$1" \
			--quiet \
			--show-progress \
			"$KERNEL_URL"
	fi
}

function compile_kernel {
	local EXT_KERNEL="linux-${1:-6.4}"

	# Extract kernel if not already extracted
	if [[ ! -d "$EXT_KERNEL" ]]; then
		tar -xzf "$KERNEL"
	fi

	cd "linux-$KERNEL_VERSION"
	make defconfig
	# make -j
	make
}

# Compile init program
cc -static init.c -o init

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
download_kernel
echo

echo "Compile kernel..."
compile_kernel

echo "Start QEMU..."
qemu-system-x86_64 \
	-kernel "${KERNEL_PATH}" \
	-initrd "${ROOTFS_PATH}"
