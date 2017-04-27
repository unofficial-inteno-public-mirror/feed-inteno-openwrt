#!/bin/sh
# (C) 2015 Inteno Broadband Technology AB

. /lib/functions.sh

copy_mounted_overlay() {
	if [ -e /mnt/overlay/SAVE_OVERLAY ]; then
		echo "Copying overlay..."
		cp -rfdp /mnt/overlay/* /overlay/
		rm -f /overlay/SAVE_OVERLAY
	fi
}

copy_config_from() {
	local FILES=""

	save_selected_backup_files() {
		config_get conservative_keep $1 conservative_keep "0"
		if [ "$conservative_keep" = "1" ]; then
			config_get file "$1" file
			for f in $file; do
				FILES="$FILES $f"
			done
		fi
	}

	if [ -e $1/sysupgrade.tgz ]; then
	    echo "Unpacking old config..."
		tar xvzf $1/sysupgrade.tgz -C /overlay/
		# we don't want to keep backup file
		[ -f /overlay/etc/config/backup ] && cp /rom/etc/config/backup /overlay/etc/config/backup
	else
		echo "Conservative copy of old config..."
		local file="$1"
		config_load backup
		config_foreach save_selected_backup_files service
		for file in $FILES
		do
			if [ -e $1$file ]; then
				echo "copy $1$file to /overlay$(dirname $file)/"
				mkdir -p /overlay$(dirname $file)
				cp -rfp $1$file /overlay$(dirname $file)/
			else
				echo "skip $1$file not found"
			fi
		done
	fi
	rm -f /overlay/SAVE_CONFIG
}

copy_old_config() {

	local iVersion=$1
	local new_fs_type=$2
	local old_vol old_fs_mtd

	if [ "$iVersion" = "04" -a "$new_fs_type" = "ubifs" ]; then

		# ubifs -> ubifs upgrade
		echo "Upgrading $new_fs_type from iVersion 4"

		if cat /proc/cmdline |grep -q "ubi.*:rootfs_0"; then
			old_vol="ubi:rootfs_1"
		else
			old_vol="ubi:rootfs_0"
		fi

		echo "Mount $old_vol on /mnt"
		mount -t ubifs -o ro,noatime $old_vol /mnt
		copy_mounted_overlay
		if [ -e /mnt/overlay/SAVE_CONFIG ]; then
			copy_config_from /mnt/overlay
		fi
		umount /mnt

	elif [ "$iVersion" = "03" ]; then
		# jffs2 -> jffs2/ubifs upgrade
		echo "Upgrading $new_fs_type from iVersion 3"

		if [ "$new_fs_type" = "jffs2" ]; then
			old_fs_mtd="mtd:rootfs_update"
		elif brcm_fw_tool -i update /dev/mtd6 >/dev/null 2>&1; then
			# was there a jffs2 partition?
			old_fs_mtd="mtd:mtd_hi"
		else
			# No valid jffs2 partition, just empty flash
			old_fs_mtd=""
		fi

		if [ -n "$old_fs_mtd" ]; then
			echo "Mount $old_fs_mtd on /mnt"
			mount -t jffs2 -o ro $old_fs_mtd /mnt
			copy_mounted_overlay
			if [ -e /mnt/overlay/SAVE_CONFIG ]; then
				copy_config_from /mnt/overlay
			fi
			umount /mnt
		fi
	else
		if [ "$new_fs_type" = "jffs2" ]; then
			# IOP2 jffs2 layout -> IOP3 jffs2 upgrade
			echo "Upgrading $new_fs_type from unknown iVersion"
			echo "Mount mtd:rootfs_update_data on /mnt"
			mount -t jffs2 -o ro mtd:rootfs_update_data /mnt
			#Always copies config from IOP2
			copy_config_from /mnt
			umount /mnt
		else
			echo "Cannot copy config files to UBIFS from unknown iVersion"
		fi
		echo 03 > /proc/nvram/iVersion
	fi

	# remove db to trigger init
	rm -f /overlay/lib/db/config/hw
}

build_minimal_rootfs() {

	cd $1

	mkdir bin
	cp /bin/busybox bin
	cp -d /bin/ash bin
	cp -d /bin/cat bin
	cp -d /bin/mount bin
	cp -d /bin/sh bin
	cp -d /bin/umount bin

	local ubi_ctrl_minor=$(awk -F= '/MINOR/ {print $2}' \
				/sys/devices/virtual/misc/ubi_ctrl/uevent)
	local ubi_dev_major=$(awk -F= '/MAJOR/ {print $2}' \
				/sys/devices/virtual/ubi/ubi0/uevent)
	mkdir dev
	mknod -m 644 dev/kmsg     c   1 11
	mknod -m 644 dev/mtd0     c  90  0
	mknod -m 644 dev/mtd1     c  90  2
	mknod -m 644 dev/mtd2     c  90  4
	mknod -m 644 dev/mtd3     c  90  6
	mknod -m 644 dev/mtd4     c  90  8
	mknod -m 644 dev/mtd5     c  90 10
	mknod -m 644 dev/mtd6     c  90 12
	mknod -m 644 dev/ubi_ctrl c  10 $ubi_ctrl_minor
	mknod -m 644 dev/ubi0     c $ubi_dev_major  0
	mknod -m 644 dev/ubi0_0   c $ubi_dev_major  1
	mknod -m 644 dev/ubi0_1   c $ubi_dev_major  2
	mknod -m 644 dev/ubi0_2   c $ubi_dev_major  3

	mkdir lib
	cp /lib/ubi_fixup.sh /lib/libc* /lib/libm* /lib/libgcc* /lib/ld-* lib

	mkdir old_root
	mkdir proc

	mkdir sbin
	cp -d /sbin/pivot_root sbin

	mkdir sys
	mkdir tmp
	mkdir usr

	mkdir usr/bin
	cp -d /usr/bin/awk usr/bin
	cp -d /usr/bin/env usr/bin

	mkdir usr/sbin
	cp -d /usr/sbin/chroot usr/sbin
	cp /usr/sbin/imagewrite usr/sbin
	cp /usr/sbin/nanddump usr/sbin
	cp /usr/sbin/ubiattach usr/sbin
	cp /usr/sbin/ubidetach usr/sbin
	cp /usr/sbin/ubimkvol usr/sbin
	cp /usr/sbin/ubinfo usr/sbin
	cp /usr/sbin/ubirsvol usr/sbin
	cp /usr/sbin/ubiupdatevol usr/sbin

	cd -
}

# iopsys_upgrade_handling
# This function needs to handle the following cases:
# - normal boot, no upgrade
# - first boot after upgrade jffs2->jffs2
# - first boot after upgrade jffs2->ubifs
# - restarted init after upgrade jffs2->ubifs
# - first boot after upgrade ubifs->ubifs
#
iopsys_upgrade_handling() {
	local iVersion local fs_type

	# Skip if not first boot
	[ -e /IOP3 ] || return

	export FIRST_BOOT="yes"

	mount proc /proc -t proc
	# need to have a writable root for the rest of the script to work
	mount -o remount,rw /

	if grep -q '/tmp tmpfs' /proc/mounts; then
		# preinit restart after upgrade jffs2 -> ubifs
		umount /tmp
		umount /proc
		rm /IOP3
		return
	fi

	if [ -e /proc/nvram/iVersion ]; then
		# for broadcom legacy
		iVersion=$(awk '{ print $1 }' </proc/nvram/iVersion)
		fs_type=$(awk '/jffs2|ubifs/ { print $3 }' </proc/mounts)
	else
		# mediatek
		iVersion="04"
		fs_type="ubifs"
	fi
	copy_old_config "$iVersion" "$fs_type"

	if [ "$iVersion" = "04" -o "$fs_type" = "jffs2" ]; then
		# upgrading ubifs -> ubifs or jffs2 -> jffs2
		umount /proc
		rm /IOP3
		return
	fi

	# upgrading jffs2 -> ubifs
	mount sysfs /sys -t sysfs

	echo "====== Start flash partition update ======"

	mount tmpfs /tmp -t tmpfs -o size=100M,mode=0755
	build_minimal_rootfs /tmp	

	# move devtmpfs into pivot and if devtmpfs
	# isn't used create an empty tmpfs.
	grep -qE "[[:space:]]/dev[[:space:]]" /proc/mounts || \
		mount -t tmpfs tmpfs /dev -o mode=0755,size=512K,nosuid,noatime
	mount -o move /dev /tmp/dev

	umount /sys
	umount /proc

	cd /tmp
	pivot_root . /tmp/old_root
	exec chroot . /lib/ubi_fixup.sh &> dev/kmsg

	# Never returns here, ubi_fixup.sh will respawn /etc/preinit
}

