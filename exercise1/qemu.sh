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
	local VERSION="${1:-$KERNEL_VERSION}"
	local TAR="${2:-kernel.tar.gz}"
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

	# Configure and compile kernel
	cd "$EXTRACTED"
	make defconfig # Use default config
	# make -j
	make
}

# Start of script:
mkdir -p "$TMP_DIR"

# Create rootfs
rootfs

cd "$TMP_DIR"

# Download, configure and compile kernel
kernel

echo "Start QEMU..."
qemu-system-x86_64 \
	-kernel "${KERNEL_PATH}" \
	-initrd "${ROOTFS_PATH}"
