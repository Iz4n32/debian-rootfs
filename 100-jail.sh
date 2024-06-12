#!/bin/bash

# Available architectures with their associated qemu
declare -A qemu_static
#qemu_static[amd64]=qemu-x86_64-static => see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=703825
qemu_static[arm64]=qemu-aarch64-static
qemu_static[armel]=qemu-arm-static
qemu_static[armhf]=qemu-arm-static
qemu_static[i386]=qemu-i386-static
qemu_static[mips]=qemu-mips-static
qemu_static[mipsel]=qemu-mipsel-static
qemu_static[powerpc]=qemu-ppc-static
qemu_static[powerpcspe]=qemu-ppc-static
qemu_static[ppc64el]=qemu-ppc64le-static
qemu_static[s390x]=qemu-s390x-static

set_chroot() {

	# Copy qemu binary to rootfs
	cp $qemu_path $rootfs_dir_utc$qemu_path

	# Mount /dev in rootfs
	mount --bind /dev $rootfs_dir_utc/dev
}

unset_chroot() {

	# Kill processes running in rootfs
	fuser -sk $rootfs_dir_utc

	# Remove qemu binary from rootfs
	rm $rootfs_dir_utc$qemu_path 2>/dev/null

	# Umount /dev in rootfs
	umount $rootfs_dir_utc/dev
}

print_archs() {
    echo "    - $host_arch"
    for i in ${!qemu_static[@]}; do
	if [[ $i != $host_arch ]]; then
            echo "    - $i"
        fi
    done
}

# Ckeck script is sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "`basename $0` needs to be sourced"
    exit 1
fi

# Get caller script
caller_script=`basename $(caller | awk '{print $2}')`
exit_or_return=`[[ $caller_script != NULL ]] && echo exit|| echo return`

# Make sure only root can run our script
if [[ $(id -u) != 0 ]]; then
   echo "This script must be run as root"
   $exit_or_return 1
fi

# Get host architecture
host_arch=`dpkg --print-architecture`

# Print usage
if [[ ! $1 || $1 == "-h" || $1 == "--help" ]]; then
    running_script=`[[ $caller_script != NULL ]] && echo $caller_script ||\
    echo "source \`basename ${BASH_SOURCE[0]}\`"`

    echo "usage: $running_script ARCHITECTURE [ROOTFS_DIR]"
    echo "  ARCHITECTURE can be:"
    print_archs
    $exit_or_return 1
fi
arch=$1
rootfs_dir_utc="$2"

# Check architecture is suppported
if [[ $arch != $host_arch ]]; then
    if [[ ! ${qemu_static[$arch]} ]]; then
        echo "$arch not valid, architectures supported are:"
        print_archs
        $exit_or_return 1
    fi
    
    # Find qemu binary
    qemu_path=`which ${qemu_static[$arch]}`
fi

# Cleanup when interrupt signal is received
trap "umount $rootfs_dir_utc/dev; exit 1" SIGINT

if [[ $arch == $host_arch ]]; then
    # Create /dev in rootfs
    mkdir -p $rootfs_dir_utc/dev 2>/dev/null

    # Mount /dev in rootfs
    mount --bind /dev $rootfs_dir_utc/dev
else
    # Set environment variables
    export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
    export LC_ALL=C LANGUAGE=C LANG=C

	set_chroot
fi


# ENTER Jail
chroot $rootfs_dir_utc /bin/bash

unset_chroot

exit 0

