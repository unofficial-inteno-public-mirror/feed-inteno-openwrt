#!/bin/sh
#
# IOPSYS related helper functions.
#
# handling of functions related to IOPSYS software versions.
#
#

iop_current_root()
{
    if cat /proc/cmdline |grep -q "ubi.*:rootfs_0"; then
 	echo "rootfs_0"
    else
	echo "rootfs_1"
    fi
}

iop_other_root()
{
    if cat /proc/cmdline |grep -q "ubi.*:rootfs_0"; then
 	echo "rootfs_1"
    else
	echo "rootfs_0"
    fi
}

iop_other_prep()
{
    local other

    [ -e /tmp/sysinfo/other_os-release ] && return

    other=$(iop_other_root)

    mount -t ubifs ubi0:${other} /mnt
    cp /mnt/etc/os-release  /tmp/sysinfo/other_os-release
    umount /mnt
}


iop_os_release(){
    .  /etc/os-release
}

iop_other_os_release(){
    iop_other_prep

    .  /tmp/sysinfo/other_os-release
}

iop_os_release_print()
{
    cat /etc/os-release
}

iop_other_os_release_print()
{
    iop_other_prep
    
    cat /tmp/sysinfo/other_os-release
}


