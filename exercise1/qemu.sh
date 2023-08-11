#!/usr/bin/env bash

<<EOF
This script creates a root filesystem with an init binary.
It then downloads and compiles a Linux kernel and then uses qemu to emulate hardware.

This script assumes you have qemu already installed.
We use c99 as it is part of the POSIX standard.
We prefer 'mkdir -p' over 'mkdir --parents' as it is considered more portable.
We use the 6.4 release of the Linux kernel as it is the most recent and most likely to compile without issues.

Dependencies:
build-essential, qemu, isolinux, genisoimage
EOF

# Change current working directory to location of the script
cd "$(dirname "")"
pwd -P

# Readonly variables:
readonly TMP_DIR="${TMP:-tmp}"

readonly CC="${CC:-c99}"

readonly ROOTFS_DIR="${TMP_DIR}/rootfs"
readonly ROOTFS="rootfs.cpio"

# 6.1 is the LTS variant
readonly KERNEL_VERSION="6.4"
readonly KERNEL_DIR="linux-$KERNEL_VERSION"

# Functions:
# Create a rootfile system and store it in an archive
function rootfs {
	# Create root filesystem
	echo "Creating root filesystem ($ROOTFS)..."
	mkdir -p "$ROOTFS_DIR"

	# Compile init program
	$CC -static init.c -o "${ROOTFS_DIR}/init"

  # Use a subshell to cleanly enter and exit the rootfs directory
	(
		cd "$ROOTFS_DIR"

		# Copy files in the rootfs folder to an archive and compress it
		find | cpio --quiet --create --format=newc | bzip2 --stdout >../$ROOTFS
	)
}

# Compile the Linux kernel
function compile {
		echo "Creating default kernel config..."
		make defconfig

		echo "Compiling kernel..."
		make --jobs=2
}

# Create a bootable ISO image from the kernel and rootfs archive
function create_iso {
	echo "Creating an ISO image of the kernel and root filesystem..."
	make isoimage FDINITRD=../rootfs.cpio
}

# Download, unpack and compile a version of the linux kernel
function kernel {
	local tarball="${1:-linux-${KERNEL_VERSION}.tar.gz}"
	local version="${2:-$KERNEL_VERSION}"
	local url="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/linux-${version}.tar.gz"
	local kernel_dir="linux-$version"

	# Download kernel
	if [[ ! -f "$tarball" ]]; then
		echo "Downloading Linux kernel (version $version)..."

		wget --output-document="$tarball" \
			--quiet \
			--show-progress \
			"$url"
	fi

	# Extract kernel
	if [[ ! -d "$kernel_dir" ]]; then
		echo "Extracting kernel"
		tar -xzf "$tarball"
	fi

  # Configure and compile kernel and generate bootable ISO image
	(
		cd "$kernel_dir"

		compile    # Compile the kernel
		create_iso # Generate an ISO image of the kernel
	)
}

# Run kernel with rootfs on emulated hardware, using QEMU
function qemu {
	local bzimage_path="${1:-${KERNEL_DIR}}/arch/x86_64/boot/bzImage"
	local rootfs_path="${2:-$ROOTFS}"

	echo "Starting QEMU..."

	# Now pass the kernel binary and rootfs archive to qemu
	qemu-system-x86_64 \
		-kernel "$bzimage_path" \
		-initrd "$rootfs_path"
}

# Start of script:
# Debugging flag
[[ -n "$DEBUG" ]] && set -x

mkdir -p "$TMP_DIR"

# Create rootfs
rootfs

# Continue working from tmp dir
cd "$TMP_DIR"

# Download, configure and compile kernel
kernel

# Run qemu
qemu
