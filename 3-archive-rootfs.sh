#!/bin/bash

TAR_EXTENSION=.tar.gz

set_chroot () {
	# Copy qemu binary to rootfs
	cp $qemu_path $build_dir/$rootfs_dir_utc$qemu_path

	# Mount /dev in rootfs
	mount --bind /dev $build_dir/$rootfs_dir_utc/dev
}

unset_chroot () {
	# Kill processes running in rootfs
	fuser -sk $build_dir/$rootfs_dir_utc

	# Remove qemu binary from rootfs
	rm $build_dir/$rootfs_dir_utc$qemu_path 2>/dev/null

	# Umount /dev in rootfs
	umount $build_dir/$rootfs_dir_utc/dev
}

# USAGE: script_to_LowerCase <runlevel_number> <uppercase_letter> <script_name>
script_to_LowerCase () {
	local RUNLEVEL=$1
	local UPPERCASE=$2
	local LOWERCASE=$(tr '[:upper:]' '[:lower:]' <<< "$UPPERCASE")
	local NAME=$3

	link_found=$(find $build_dir/$rootfs_dir/etc/rc$RUNLEVEL.d/ -maxdepth 1 -type l -regextype posix-egrep -regex "$build_dir/$rootfs_dir/etc/rc$RUNLEVEL.d/$UPPERCASE[0-9]{2}$NAME")
	new_link_name="${link_found##*/}" && new_link_name="$LOWERCASE${new_link_name:1}"
	mv $link_found $build_dir/$rootfs_dir/etc/rc$RUNLEVEL.d/$new_link_name
}

# Check architecture and set variables
if [[ ! $check_and_set ]]; then
    . 0-check-and-set.sh $1
fi

rootfs_dir_utc=`readlink $build_dir/$rootfs_dir`
tar_name=rootfs$TAR_EXTENSION

#Borrar ficheros sobrantes
rm -f $build_dir/$rootfs_dir/etc/cron.daily/cracklib-runtime

set_chroot

#ldconfig: library links
chroot $build_dir/$rootfs_dir_utc ldconfig

# Generic depmod, versions are read from /lib/modules/* folder
for dir in $build_dir/$rootfs_dir/lib/modules/*/; do
	[ -d "$dir" ] && echo "depmod: $(basename $dir)" && chroot $build_dir/$rootfs_dir_utc depmod -a -w "$(basename $dir)"
done

# /bin/sh -> bash (en lugar de dash)
chroot $build_dir/$rootfs_dir_utc rm -rf /bin/sh
chroot $build_dir/$rootfs_dir_utc ln -s bash /bin/sh

# CIS: Remove users and groups
users_list=("games" "man" "list" "gnats" "nobody")
for user in "${users_list[@]}"; do
	chroot $build_dir/$rootfs_dir_utc userdel -r $user > /dev/null 2>&1
done

unset_chroot

# remove all .socket that will be ignored
rm -rf $build_dir/$rootfs_dir_utc/run/*.socket

cd $build_dir/$rootfs_dir_utc
tar --xattrs -zcpf ../$tar_name *
cd - >/dev/null

echo
echo "[OK] $build_dir/$tar_name created"
