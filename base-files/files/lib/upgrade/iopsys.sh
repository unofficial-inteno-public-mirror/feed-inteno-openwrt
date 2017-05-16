
# This file must be sourced after common.sh to override OpenWRT defaults.

source /usr/share/libubox/jshn.sh


#--------------------------------------------------------------
install_bin() { # <file> [ <symlink> ... ]
	echo "install_bin NOT USED, CAN LIKELY BE REMOVED! OR?"
	sleep 9999h
}



#--------------------------------------------------------------
v() {
	[ "$VERBOSE" -ge 1 ] && echo "$@"
}



#--------------------------------------------------------------
get_image() { # <source> [ <command> ]
	local from="$1"
	local conc="$2"
	local cmd

	local sysinfo=$(ubus call router.system info)
	json_load "$sysinfo"
	json_select system
	json_get_var firmware firmware
	json_get_var filesystem filesystem
	json_select ..
	json_cleanup

	case "$from" in
		http://*|ftp://*) cmd="wget -O- -q --user-agent=\"$firmware:$filesystem\"";;
		*) cmd="cat";;
	esac
	if [ -z "$conc" ]; then
		local magic="$(eval $cmd \"$from\" 2>/dev/null | dd bs=2 count=1 2>/dev/null | hexdump -n 2 -e '1/1 "%02x"')"
		case "$magic" in
			1f8b) conc="zcat";;
			425a) conc="bzcat";;
		esac
	fi

	eval "$cmd \"$from\" 2>/dev/null ${conc:+| $conc}"
}



#--------------------------------------------------------------
is_inteno_image() {
	[ "$(dd if=$1 bs=1 count=10 2>/dev/null)" == "IntenoBlob" ] && return 0
	return 1
}



#--------------------------------------------------------------
get_image_type() {
	if is_inteno_image $1; then
		echo "INTENO"
	else
		echo "UNKNOWN"
	fi
}



#--------------------------------------------------------------
get_inteno_tag_val() {
	local from="$1"
	local tag="$2"
	local val

	val=$(head -c 1024 $from |awk "/^$tag / {print \$2}")
	[ -z "$val" ] && val=0
	echo $val
}



#--------------------------------------------------------------
get_image_board_id() {
	get_inteno_tag_val $1 board
}



#--------------------------------------------------------------
get_image_model_name() {
	get_inteno_tag_val $1 model
}



#--------------------------------------------------------------
get_image_customer() {
	get_inteno_tag_val $1 customer
}



#--------------------------------------------------------------
get_image_chip_id() {
	get_inteno_tag_val $1 chip
}



#--------------------------------------------------------------
check_image_size() {
	# FIXME!
	echo "SIZE_OK"
}



#--------------------------------------------------------------
check_crc() {
	local from=$1
	local file_sz calc csum

	case $(get_inteno_tag_val $from integrity) in
		MD5SUM)
			file_sz=$(ls -l $from |awk '{print $5}')
			calc=$(head -c $(($file_sz-32)) $from |md5sum |awk '{print $1}')
			csum=$(tail -c 32 $from)
			[ "$calc" == "$csum" ] && echo "CRC_OK" || echo "CRC_BAD"
			;;
		*)
			echo "UNKNOWN"
			;;
	esac
}



#--------------------------------------------------------------
check_sig() {
	local from=$1
	local len

	len=$(($(get_inteno_tag_val $from cfe) +
	$(get_inteno_tag_val $from vmlinux) +
	$(get_inteno_tag_val $from ubifs) +
	$(get_inteno_tag_val $from ubi) ))

	# get pubkey from cert.
	openssl x509 -in /etc/ssl/certs/opkg.pem -pubkey -noout >/tmp/pubkey

	# extract signature data from firmware image.
	dd if=$from bs=1 skip=$((1024+len)) count=256 2>/dev/null >/tmp/sig

	result=$(dd if=$from bs=1024 skip=1 2>/dev/null | \
		head -c $len | \
		openssl dgst -sha256 \
			-verify /tmp/pubkey \
			-signature /tmp/sig )
	rm /tmp/pubkey
	rm /tmp/sig

	[ "$result" == "Verified OK" ] && return 0
	return 1
}



#--------------------------------------------------------------
iopsys_check_image() {
	local from

	[ "$ARGC" -gt 1 ] && return 1

	echo "Image platform check started ..." > /dev/console

	case "$1" in
		http://*|ftp://*) get_image "$1" "cat" > /tmp/firmware.bin; from=/tmp/firmware.bin;;
		*) from=$1;;
	esac

	[ "$(check_crc $from)" == "CRC_OK" ] || {
		echo "CRC check failed" > /dev/console
		return 1
	}

	if [ -e /etc/ssl/certs/opkg.pem ]; then
		if ! check_sig "$from"; then
		echo "Signature of file is wrong. Aborting!" > /dev/console
		return 1
		fi
	fi

	[ "$(check_image_size "$from")" == "SIZE_OK" ] || {
		echo "Image size is too large" > /dev/console
		return 1
	}

	if [ "$(get_image_chip_id "$from")" != "$(get_chip_id)" ]; then
		echo "Chip model of image does not match" > /dev/console
		return 1
	fi

	# Customer name check should be carried out
	# only if a regarding parameter set in config.
	# For now skip customer name check.
	if [ 1 -eq 0 ]; then
		[ -f /lib/db/version/iop_customer ] \
			&& [ "$(get_image_customer "$from")" != "$(cat /lib/db/version/iop_customer)" ] && {
			echo "Image customer doesn't match" > /dev/console
			return 1
		}
		# NOTE: expr interprets $(db get hw.board.hardware) as a
		# regexp which could give unexpected results if the harware
		# name contains any magic characters.
		expr "$(get_image_model_name "$from")" : "$(db get hw.board.hardware)" || {
			echo "Image model name doesn't match board hardware" > /dev/console
			return 1
		}
	fi

	echo "Image platform check completed" > /dev/console

	return 0
}



#--------------------------------------------------------------
iopsys_upgrade() {
	local from mtd_no
	local klink sname

	case "$1" in
		http://*|ftp://*) from=/tmp/firmware.bin;;
		*) from=$1;;
	esac


	# Stop unnecessary processes
	for klink in $(ls /etc/rc.d/K[0-9]*); do
		sname=$(basename $(readlink -f $klink))
		case $sname in
			bcmhotproxy|boot|cgroups|dropbear|iwatchdog|telnet|umount)
				v "Not stopping $sname"
				;;
			*)
				v "Stopping $sname..."
				$klink stop
				;;
		esac
	done
	sleep 3s

	if [ "$SAVE_OVERLAY" -eq 1 -a -z "$USE_REFRESH" ]; then
		v "Creating save overlay file marker"
		touch /SAVE_OVERLAY
	else
		v "Not saving overlay files"
		rm -f /SAVE_OVERLAY
	fi
	if [ "$SAVE_CONFIG" -eq 1 -a -z "$USE_REFRESH" ]; then
		v "Creating save config file marker"
		touch /SAVE_CONFIG
	else
		v "Not saving config files"
		rm -f /SAVE_CONFIG
	fi
	sync

	# Product specific low level write to flash
	target_upgrade $from || return

	v "Upgrade completed!"
	rm -f $from
	[ -n "$DELAY" ] && sleep "$DELAY"
	v "Rebooting system ..."
	sync
	export REBOOT_REASON=upgrade
	echo "upgrade complete. rebooting system."
	reboot -f
}


