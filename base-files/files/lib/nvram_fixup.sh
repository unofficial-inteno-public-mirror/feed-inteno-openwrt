#!/bin/sh


get_block0_nvram_offset() {

	if cat /proc/cpuinfo |grep -q "ARM"; then
	   echo "$((65536+1408))"
	else
	   echo "1408" 
        fi
}


find_mtd_no() {
	local part=$(awk -F: "/\"$1\"/ { print \$1 }" /proc/mtd)
	echo ${part##mtd}
}

nvram_upgrade2(){

	local mtd_no=$(find_mtd_no nvram2 ) 
	local default_mtd=$(find_mtd_no nvram )
	local skip=$(get_block0_nvram_offset ) 
	local nvpath=/tmp/nvram2.img
	#local bakpath=/nvram.bak
        echo -ne "NVRAM\n\377\377\001\000\000\000\377\377\377\377" > $nvpath || return 
	cat /dev/null | tr '\000' '\377' | head -c $(( 2048 - 16 )) >> $nvpath || return 
	dd if=/dev/mtd$default_mtd bs=1 count=1k skip=$skip of=$nvpath seek=16 conv=notrunc || return 
	
        #echo -ne "NVRAM\n" > $bakpath
        #cat /dev/null | /usr/bin/tr '\000' '\377' | /bin/head -c $(( 2048 - 6 )) >> $bakpath

	echo "Write secondary nvram..."
	imagewrite -c -s 0 -b 1 /dev/mtd$mtd_no $nvpath 
	imagewrite -c -s 1 -b 1 /dev/mtd$mtd_no $nvpath 
	imagewrite -c -s 2 -b 1 /dev/mtd$mtd_no $nvpath 
	#cfe_image_upgrade /tmp/nvram1.img 66944 2032

	
}





