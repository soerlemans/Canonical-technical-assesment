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

readonly KERNEL_VERSION="6.4"

# Functions:
function rootfs {

	# Create root filesystem
	echo "Creating root filesystem ($ROOTFS)..."
	mkdir -p "${ROOTFS_DIR}"

	# Compile init program
	cc -static init.c -o "${ROOTFS_DIR}/init"

	# Use a subshell to cleanly enter
	(
		cd "${ROOTFS_DIR}"

		# Copy files in the rootfs folder to an archive and compress it
		find | cpio --quiet --create --format=newc | bzip2 --stdout >../$ROOTFS
	)
}

# Download and compile a version of the linux kernel
function kernel {
	local TAR="${1:-kernel.tar.gz}"
	local VERSION="${2:-$KERNEL_VERSION}"
	local URL="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/linux-${VERSION}.tar.gz"
	local EXTRACTED="linux-$VERSION"

	# Download kernel
	if [[ ! -f "$TAR" ]]; then
		echo "Downloading Linux kernel (version $VERSION)..."

		wget --output-document="$TAR" \
			--quiet \
			--show-progress \
			"$URL"
	fi

	# Extract kernel
	if [[ ! -d "$EXTRACTED" ]]; then
		echo "Extracting kernel"
		tar -xzf "$TAR"
	fi

	exit

	# Configure and compile kernel
	(
		cd "$EXTRACTED"

		make defconfig # Use default config
		# make -j
		make
	)
}

function qemu {
	echo "Start QEMU..."
	qemu-system-x86_64 \
		-kernel "$1" \
		-initrd "${2:-$ROOTFS}"
}

# Start of script:
mkdir -p "$TMP_DIR"

# Create rootfs
rootfs

cd "$TMP_DIR"

# Download, configure and compile kernel
kernel "kernel.tar.gz"

# Run qemu
qemu "kernel.tar.gz"
