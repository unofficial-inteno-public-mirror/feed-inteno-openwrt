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

rm_savecfg_files()
{
	rm -f $SAVECFG_WIFI
	rm -f $SAVECFG_FW_REDIRECT
	rm -f $SAVECFG_FW_PARENTAL
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



apply_wifi()
{
	local index ifname network
	local newindex newifname newnetwork

	# loop through all the user wifi-ifaces
	for index in $(seq 0 99) ; do
		ifname=$(sed -n 's/.*wifi-iface\['$index'\]\.ifname='\''\(.*\)'\''/\1/p' $SAVECFG_WIFI )
		[ "$ifname" ] || break
		network=$(sed -n 's/.*wifi-iface\['$index'\]\.network='\''\(.*\)'\''/\1/p' $SAVECFG_WIFI )

		newindex=""
		newifname=""
		newnetwork=""

		# loop through all the newly configured wifi-ifaces
		for newindex in $(seq 0 99) ; do
			newifname=$( uci show wireless | grep wifi-iface | sed -n 's/.*wifi-iface\['$newindex'\]\.ifname='\''\(.*\)'\''/\1/p' )
			if [ -z "$newifname" ] ; then
				# no newifname means that all the wifi-ifaces have already been parsed
				newindex="-1"
				break
			fi
			newnetwork=$(uci show wireless | grep wifi-iface | sed -n 's/.*wifi-iface\['$newindex'\]\.network='\''\(.*\)'\''/\1/p' )

			# two wifi interfaces are the same if "ifname" and "network" are the same
			if [ "$newifname" == "$ifname" ] && [ "$newnetwork" == "$network" ] ; then
				break
			fi
		done

		# prepend "set" to each line NOT containing "]="
		# wireless.@wifi-iface[$index].<option>='<value>' becomes
		# set wireless.@wifi-iface[$newindex].<option>='<value>'
		sed -i '/.*]=.*/! s/\(.*\[\)'$index'\(\].*\)/set \1'$newindex'\2/' $SAVECFG_WIFI

		if [ "$newindex" == "-1" ] ; then
			# prepend "add" to each line containing "]="
			# AND keep only the package name (before the first dot) and section type (after equal)
			# wireless.@wifi-iface[0]=wifi-iface becomes
			# add wireless wifi-iface
			sed -i 's/\(.*\)\..*\['$index'\]=\(.*\)/add \1 \2/' $SAVECFG_WIFI
		else
			# no need to create a new uci section, just delete the line defining a new section
			sed -i '/\(.*\)\..*\['$index'\]=\(.*\)/d' $SAVECFG_WIFI
		fi

	done
	# commit at the end of the script
	[ -s $SAVECFG_WIFI ] && echo "commit" >> $SAVECFG_WIFI

	echo "The generated file / uci script:" >/dev/console
	cat $SAVECFG_WIFI >/dev/console
	### cat $SAVECFG_WIFI | uci batch >/dev/null 2>&1
}

apply_fw_redirect()
{
	# prepend "set" to each line NOT containing "]="
	# firewall.@redirect[0].enabled='1' becomes
	# set firewall.@redirect[0].enabled='1'
	sed -i '/.*]=.*/! s/.*/set \0/' $SAVECFG_FW_REDIRECT

	# prepend "add" to each line containing "]="
	# AND keep only the package name (before the first dot) and section type (after equal)
	# firewall.@redirect[0]=redirect becomes
	# add firewall redirect
	sed -i 's/\(.*\)\..*]=\(.*\)/add \1 \2/' $SAVECFG_FW_REDIRECT

	# change all the array indexes to [-1]
	sed -i 's/\[.\?.\?.\?.\?\]/[-1]/' $SAVECFG_FW_REDIRECT

	# commit at the end of the script
	[ -s $SAVECFG_FW_REDIRECT ] && echo "commit" >> $SAVECFG_FW_REDIRECT

	echo "The generated file / uci script:" >/dev/console
	cat $SAVECFG_FW_REDIRECT >/dev/console
	### cat $SAVECFG_FW_REDIRECT | uci batch >/dev/null 2>&1
}

apply_fw_parental()
{
	# prepend "set" to each line NOT containing "]="
	# firewall.@redirect[0].enabled='1' becomes
	# set firewall.@redirect[0].enabled='1'
	sed -i '/.*]=.*/! s/.*/set \0/' $SAVECFG_FW_PARENTAL

	# prepend "add" to each line containing "]="
	# AND keep only the package name (before the first dot) and section type (after equal)
	# firewall.@redirect[0]=redirect becomes
	# add firewall redirect
	sed -i 's/\(.*\)\..*]=\(.*\)/add \1 \2/' $SAVECFG_FW_PARENTAL

	# change all the array indexes to [-1]
	sed -i 's/\[.\?.\?.\?.\?\]/[-1]/' $SAVECFG_FW_PARENTAL

	# commit at the end of the script
	[ -s $SAVECFG_FW_PARENTAL ] && echo "commit" >> $SAVECFG_FW_PARENTAL

	echo "The generated file / uci script:" >/dev/console
	cat $SAVECFG_FW_PARENTAL >/dev/console
	### cat $SAVECFG_FW_PARENTAL | uci batch >/dev/null 2>&1
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

	rm_savecfg_files
}
