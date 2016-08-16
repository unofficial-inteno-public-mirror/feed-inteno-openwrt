#!/bin/sh

bcm_dsl_annex() {
        ANNEX=`cat /proc/nvram/dslAnnex`
#       echo $ANNEX

        if [ -f "/etc/adsl/adsl_phy.bin" ]
        then
                echo "DSL firmware symlink set"
        else
                if [ "$ANNEX" = "A" ]; then
                        echo "DSL Annex A detected"
                        ln -s /etc/dsl/a_adsl_phy.bin /etc/adsl/adsl_phy.bin
                elif [ "$ANNEX" = "B" ]; then
                        echo "DSL Annex B detected"
                        ln -s /etc/dsl/b_adsl_phy.bin /etc/adsl/adsl_phy.bin
                else
                        echo "DSL Annex A default"
                        ln -s /etc/dsl/a_adsl_phy.bin /etc/adsl/adsl_phy.bin
                fi
        fi
}

brcm_insmod() {
	echo Loading brcm modules
	sh /lib/bcm-base-drivers.sh start
	echo brcm modules loaded
}

brcm_env() {
	echo "Y" > /sys/module/printk/parameters/time
	echo Setting up brcm environment
	/bin/mount -a
	echo "Copying device files from /lib/dev to /dev"
	cp -a /lib/dev/* /dev
	mknod /var/fuse c 10 229
	chmod a+rw /var/fuse
	mkdir -p /var/log /var/run /var/state/dhcp /var/ppp /var/udhcpd /var/zebra /var/siproxd /var/cache /var/tmp /var/samba /var/samba/share /var/samba/homes /var/samba/private /var/samba/locks
}

id_upgrade_reconfig() {

    local basemac=$(cat /proc/nvram/BaseMacAddr | tr '[a-z]' '[A-Z]')
    local boardid=$(cat /proc/nvram/BoardId)
    local vendorid=${basemac:0:8}
    if [ "$boardid" == "963268BU" ]; then
        if [ "$vendorid" == "00 22 07" ]; then
            echo "Setting new boardid and voiceboardid"
            echo DG301R0 > /proc/nvram/BoardId
            echo SI32176X2 > /proc/nvram/VoiceBoardId
            echo "00 00 00 01" >/proc/nvram/ulBoardStuffOption
            sync
            sleep 3
            /sbin/brcm_fw_tool set -x 17 -p 0
        fi
    fi
}

feed_rng_entropy() {
    if lsmod |grep -q bcmtrng; then
        echo "Seeding rng from hw trng"
        head -c 1024 /dev/hwrandom > /dev/random
    fi
}

brcm_env
id_upgrade_reconfig
bcm_dsl_annex
brcm_insmod
feed_rng_entropy

