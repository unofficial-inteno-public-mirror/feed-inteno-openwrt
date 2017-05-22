#!/bin/sh

# Functions to save parts of the uci config over defaultreset

# Before defaultreset:
# Collect raw output from 'uci show'
# Store it in several files

# After defaultreset and boot:
# Transform the outputs of 'uci show' into uci scripts.


SAVECFG=/rom/tmp/savecfg

SAVECFG_WIFI=$SAVECFG"_wifi"
SAVECFG_FW_REDIRECT=$SAVECFG"_fw_redirect"
SAVECFG_FW_PARENTAL=$SAVECFG"_fw_parental"


prepare_fresh_file()
{
	file=$1
	rm -f $file
	touch $file
}



save_wifi()
{
	prepare_fresh_file $SAVECFG_WIFI

	uci show wireless | grep "wifi-iface" >> $SAVECFG_WIFI
}

save_fw_redirect()
{
	prepare_fresh_file $SAVECFG_FW_REDIRECT

	uci show firewall | grep redirect >> $SAVECFG_FW_REDIRECT
}

save_fw_parental()
{
	prepare_fresh_file $SAVECFG_FW_PARENTAL

	local parentalrules=$(uci show firewall | grep -i "Parental Rule" | grep -o "rule\[.*\]")
	for rule in $parentalrules ; do
		uci show firewall | grep -F "$rule" >> $SAVECFG_FW_PARENTAL
	done
}

save_config_before_overlay_rebuild()
{
	local saves="$@"
	echo "$0: saves = \"$saves\"" >/dev/console

	for save in $saves ; do
		echo "save: $save" >/dev/console
		[ "$save" == "wifi" ] && save_wifi
		[ "$save" == "fw_redirect" ] && save_fw_redirect
		[ "$save" == "fw_parental" ] && save_fw_parental
	done
}




apply_wifi()
{

}

apply_fw_redirect()
{

}

apply_fw_parental()
{

}

apply_config_after_overlay_rebuild()
{
	local applies="$@"
	echo "$0: applies: \"$applies\"" >/dev/console

	for apply in $applies ; do
		echo "apply: $apply" >/dev/console
		[ "$apply" == "wifi" ] && apply_wifi
		[ "$apply" == "fw_redirect" ] && apply_fw_redirect
		[ "$apply" == "fw_parental" ] && apply_fw_parental
	done

}
