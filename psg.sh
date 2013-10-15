#!/bin/sh
#
# Search for a running process.

EXPECTED_ARGS=1
usage() {
        echo "Usage: `basename $0` process"
}

[ $# -ne $EXPECTED_ARGS ] && usage && exit 65

psargs="-eo"
pssort="--sort -size,-rss"
fmt="user,pid,ppid,tty,stat,size,rss,vsz,%cpu,%mem,stime,etime,time,args"
proc_str=$1
srch_str=$(echo $proc_str | sed 's/^\([a-zA-Z0-9]\)\(.*\)/\1\2/')
ps ${psargs} ${fmt} ${pssort} | grep "[S]TIME\|${srch_str}" | grep -v "`basename $0`\|$$"
