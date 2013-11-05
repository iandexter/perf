#!/bin/bash
#
# Gather weekly sar report from all listed hosts.

remote_hosts_file="weeklysar.hosts"

if [[ -e ${remote_hosts_file} ]] ; then
    remote_hosts=( $( cat ${remote_hosts_file} ) )
else
    echo "Cannot read remote hosts file, using hard-coded list."
    remote_hosts=( host1 host2 host3 )
fi

for r in "${remote_hosts[@]}" ; do
    echo "Getting weekly sar on ${r}:"
    ssh ${r} sudo /usr/local/sbin/getweeklysar.sh
    if [[ $? -eq 0 ]] ; then
        echo "done."
    else
        echo "ERROR. Skipping."
    fi
    echo "==="
done
