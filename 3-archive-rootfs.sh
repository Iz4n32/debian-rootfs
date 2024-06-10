#!/bin/bash

TAR_EXTENSION=.tar.gz

# Check architecture and set variables
if [[ ! $check_and_set ]]; then
    . 0-check-and-set.sh $1
fi

rootfs_dir_utc=`readlink $build_dir/$rootfs_dir`
tar_name=rootfs$TAR_EXTENSION

cd $build_dir/$rootfs_dir_utc
tar cfz ../$tar_name *
cd - >/dev/null

echo
echo "$(du -h build/armhf/rootfs.tar.gz) created"

