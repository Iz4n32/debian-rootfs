#!/bin/bash

# Check architecture and set variables
if [[ ! $check_and_set ]]; then
    . 0-check-and-set.sh $1
fi

# Set hostname
filename=$build_dir/$rootfs_dir/etc/hostname
echo $arch > $filename

# MODIF: Set /etc/inittab
filename=$build_dir/$rootfs_dir/etc/inittab
if [[ -f $filename ]]; then
	sed -i 's+id:[0-9]:initdefault:+id:3:initdefault:+g' $filename
	sed -i 's/1:2345:respawn:\/sbin\/getty\ 38400\ tty1/#1:2345:respawn:\/sbin\/getty\ 38400\ tty1/g' $filename

	if ! grep -Fxq "T1:23:respawn:/sbin/getty -L ttyPSC0 115200 xterm" $filename; then
		printf 'T1:23:respawn:/sbin/getty -L ttyPSC0 115200 xterm\n' >> $filename;
	fi
fi

# DNS.WATCH servers
filename=$build_dir/$rootfs_dir/etc/resolv.conf
echo "# DNS.WATCH servers" > $filename
echo "nameserver 84.200.69.80" >> $filename
echo "nameserver 84.200.70.40" >> $filename

# Enable root autologin
filename=$build_dir/$rootfs_dir/lib/systemd/system/serial-getty@.service
autologin='--autologin root'
execstart='ExecStart=-\/sbin\/agetty'
if [[ ! $(grep -e "$autologin" $filename) ]]; then
    sed -i "s/$execstart/$execstart $autologin/" $filename
fi

# Set systemd logging
filename=$build_dir/$rootfs_dir/etc/systemd/system.conf
for i in 'LogLevel=warning'\
         'LogTarget=journal'\
; do
    sed -i "/${i%=*}/c\\$i" $filename
done

# Enable root to connect to ssh with empty password
filename=$build_dir/$rootfs_dir/etc/ssh/sshd_config
if [[ -f $filename ]]; then
    for i in 'PermitRootLogin yes'\
             'PermitEmptyPasswords yes'\
             'UsePAM no'\
    ; do
        sed -ri "/^#?${i% *}/c\\$i" $filename
    done
fi

echo
echo "$build_dir/`readlink $build_dir/$rootfs_dir` configured"
