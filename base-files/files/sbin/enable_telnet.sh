#!/bin/ash

tool=iqview
[ -n "$1" ] && tool=$1

/usr/sbin/telnetd -l /sbin/${tool}_telnet.sh
