#!/bin/sh
#
# IOPSYS related helper functions.
#
# Config file related functions.
#


iop_configs_to_macro="passwords network wireless system cwmp provisioning"

iop_config_from_macro()
{
	local BMAC=$(db -q get hw.board.BaseMacAddr | tr -d ':')
	BMAC=${BMAC// /}
	local MAC=$(printf "%X\n" $((0x$BMAC)))
	local BSSID=$(printf "%X\n" $((0x$BMAC + 2)))
	local WPAKEY=$(db get hw.board.wpaKey)
	local SERIALNR=$(db get hw.board.serialNumber)
	local HWVER=$(db get hw.board.hardwareVersion)
	local RMODEL=$(db get hw.board.routerModel)
	local DESKEY=$(db get hw.board.desKey)
	local IOPVER=$(db get hw.board.iopVersion)
	local IOPHOSTNAME=${IOPVER//[!a-zA-Z0-9-]/-} # hostname as in RFC 1035

	local MACLAN=$(printf "%0.12x\n" $((0x$BMAC)))
	local MACWAN=$(printf "%0.12x\n" $((0x$BMAC + 1)))
	MACLAN=$(echo $MACLAN | sed -e "s/.\{2\}/&:/g")
	MACWAN=$(echo $MACWAN | sed -e "s/.\{2\}/&:/g")
	MACLAN=${MACLAN:0:17}
	MACWAN=${MACWAN:0:17}

	local oid=${BMAC:0:6}
	local mac=$BMAC
	local mac2=$(echo -n $MAC | tail -c 2)
	local mac4=$(echo -n $MAC | tail -c 4)
	local mac6=$(echo -n $MAC | tail -c 6)
	local bssid=$BSSID
	local bssid2=$(echo -n $BSSID | tail -c 2)
	local bssid4=$(echo -n $BSSID | tail -c 4)
	local bssid6=$(echo -n $BSSID | tail -c 6)
	local wpakey="${WPAKEY:-1234567890}"
	local hardwareid=$HWVER-$(echo $RMODEL | sed -r 's;.+-(.+);\1;')

	for config in $iop_configs_to_macro; do
		if [ -f /etc/config/$config ]; then
			grep -q "\$MACLAN" /etc/config/$config && sed -i "s/\$MACLAN/$MACLAN/g" /etc/config/$config
			grep -q "\$MACWAN" /etc/config/$config && sed -i "s/\$MACWAN/$MACWAN/g" /etc/config/$config
			grep -q "\$MAC6" /etc/config/$config && sed -i "s/\$MAC6/$mac6/g" /etc/config/$config
			grep -q "\$MAC4" /etc/config/$config && sed -i "s/\$MAC4/$mac4/g" /etc/config/$config
			grep -q "\$MAC2" /etc/config/$config && sed -i "s/\$MAC2/$mac2/g" /etc/config/$config
			grep -q "\$MAC" /etc/config/$config && sed -i "s/\$MAC/$mac/g" /etc/config/$config
			grep -q "\$BSSID6" /etc/config/$config && sed -i "s/\$BSSID6/$bssid6/g" /etc/config/$config
			grep -q "\$BSSID4" /etc/config/$config && sed -i "s/\$BSSID4/$bssid4/g" /etc/config/$config
			grep -q "\$BSSID2" /etc/config/$config && sed -i "s/\$BSSID2/$bssid2/g" /etc/config/$config
			grep -q "\$BSSID" /etc/config/$config && sed -i "s/\$BSSID/$bssid/g" /etc/config/$config
			grep -q "\$WPAKEY" /etc/config/$config && sed -i "s/\$WPAKEY/$wpakey/g" /etc/config/$config
			grep -q "\$DESKEY" /etc/config/$config && sed -i "s/\$DESKEY/$DESKEY/g" /etc/config/$config
			grep -q "\$SER" /etc/config/$config && sed -i "s/\$SER/$SERIALNR/g" /etc/config/$config
			grep -q "\$OUI" /etc/config/$config && sed -i "s/\$OUI/$oid/g" /etc/config/$config
			grep -q "\$HARDWAREID" /etc/config/$config && sed -i "s/\$HARDWAREID/$hardwareid/g" /etc/config/$config
			grep -q "\$IOPVER" /etc/config/$config && sed -i "s/\$IOPVER/$IOPVER/g" /etc/config/$config
			grep -q "\$IOPHOSTNAME" /etc/config/$config && sed -i "s/\$IOPHOSTNAME/$IOPHOSTNAME/g" /etc/config/$config
			[ "$config" == "wireless" ] && grep -q "pskmixedpsk2" /etc/config/$config && sed -i "s/pskmixedpsk2/mixed-psk/g" /etc/config/$config
		fi
	done

}

iop_config_to_macro()
{
	local BMAC=$(db -q get hw.board.BaseMacAddr | tr -d ':')
	BMAC=${BMAC// /}
	local MAC=$(printf "%X\n" $((0x$BMAC)))
	local BSSID=$(printf "%X\n" $((0x$BMAC + 2)))
	local WPAKEY=$(db get hw.board.wpaKey)
	local SERIALNR=$(db get hw.board.serialNumber)
	local HWVER=$(db get hw.board.hardwareVersion)
	local RMODEL=$(db get hw.board.routerModel)
	local DESKEY=$(db get hw.board.desKey)
	local IOPVER=$(db get hw.board.iopVersion)
	local IOPHOSTNAME=${IOPVER//[!a-zA-Z0-9-]/-} # hostname as in RFC 1035

	local MACLAN=$(printf "%0.12x\n" $((0x$BMAC)))
	local MACWAN=$(printf "%0.12x\n" $((0x$BMAC + 1)))
	MACLAN=$(echo $MACLAN | sed -e "s/.\{2\}/&:/g")
	MACWAN=$(echo $MACWAN | sed -e "s/.\{2\}/&:/g")
	MACLAN=${MACLAN:0:17}
	MACWAN=${MACWAN:0:17}

	local oid=${BMAC:0:6}
	local mac=$BMAC
	local mac2=$(echo -n $MAC | tail -c 2)
	local mac4=$(echo -n $MAC | tail -c 4)
	local mac6=$(echo -n $MAC | tail -c 6)
	local bssid=$BSSID
	local bssid2=$(echo -n $BSSID | tail -c 2)
	local bssid4=$(echo -n $BSSID | tail -c 4)
	local bssid6=$(echo -n $BSSID | tail -c 6)
	local wpakey="${WPAKEY:-1234567890}"
	local hardwareid=$HWVER-$(echo $RMODEL | sed -r 's;.+-(.+);\1;')

	for config in $iop_configs_to_macro; do
		if [ -f /etc/config/$config ]; then
			grep -q "$MACLAN" /etc/config/$config && sed -i "s/$MACLAN/\$MACLAN/g" /etc/config/$config
			grep -q "$MACWAN" /etc/config/$config && sed -i "s/$MACWAN/\$MACWAN/g" /etc/config/$config
			grep -q "$mac6" /etc/config/$config && sed -i "s/$mac6/\$MAC6/g" /etc/config/$config
			grep -q "$mac4" /etc/config/$config && sed -i "s/$mac4/\$MAC4/g" /etc/config/$config
			grep -q "$mac2" /etc/config/$config && sed -i "s/$mac2/\$MAC2/g" /etc/config/$config
			grep -q "$mac" /etc/config/$config && sed -i "s/$mac/\$MAC/g" /etc/config/$config
			grep -q "$bssid6" /etc/config/$config && sed -i "s/$bssid6/\$BSSID6/g" /etc/config/$config
			grep -q "$bssid4" /etc/config/$config && sed -i "s/$bssid4/\$BSSID4/g" /etc/config/$config
			grep -q "$bssid2" /etc/config/$config && sed -i "s/$bssid2/\$BSSID2/g" /etc/config/$config
			grep -q "$bssid" /etc/config/$config && sed -i "s/$bssid/\$BSSID/g" /etc/config/$config
			grep -q "$wpakey" /etc/config/$config && sed -i "s/$wpakey/\$WPAKEY/g" /etc/config/$config
			grep -q "$DESKEY" /etc/config/$config && sed -i "s/$DESKEY/\$DESKEY/g" /etc/config/$config
			grep -q "$SERIALNR" /etc/config/$config && sed -i "s/$SERIALNR/\$SER/g" /etc/config/$config
			grep -q "$oid" /etc/config/$config && sed -i "s/$oid/\$OUI/g" /etc/config/$config
			grep -q "$hardwareid" /etc/config/$config && sed -i "s/$hardwareid/\$HARDWAREID/g" /etc/config/$config
			grep -q "$IOPVER" /etc/config/$config && sed -i "s/$IOPVER/\$IOPVER/g" /etc/config/$config
			grep -q "$IOPHOSTNAME" /etc/config/$config && sed -i "s/$IOPHOSTNAME/\$IOPHOSTNAME/g" /etc/config/$config
		fi
	done

}
