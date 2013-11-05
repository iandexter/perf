#!/bin/sh
#
# Graph weekly SAR output using gnuplot.

### vars
working_dir="/usr/local/tmp/sar"

remote_hosts_file="weeklysar.hosts"

start_date=$(date --date="last week" +%Y%m%d)
end_date=$(date --date="yesterday" +%Y%m%d)
start_end=${start_date}-${end_date}

plot_ext="jpeg"
start_plot=$(date --date="last week" +%b-%d)
end_plot=$(date --date="yesterday" +%b-%d)

sar_graphs_tgz="weeklysar_graphs_${start_end}.tgz"
sar_data_tgz="weeklysar_data_${start_end}.tgz"

to_mail="oiidunix@adb.org"

### functions
load_hosts() {
    if [[ -e ${remote_hosts_file} ]] ; then
        remote_hosts=( $( cat ${remote_hosts_file} ) )
    else
        echo "Cannot read remote hosts file, using hard-coded list."
        remote_hosts=( host1 host2 host3 )
    fi
}

plot() {
    echo -n "."
    sed "s,PLOT_EXT,${plot_ext},g;s,HOSTNAME,${r},g; \
         s,START_DATE,${start_plot},g;s,END_DATE,${end_plot},g; \
         s,START_END,${start_end},g;" weeklysar.plot | gnuplot
}

compress_all() {
    echo -ne "\nCompressing... "
    tar czvf ${sar_graphs_tgz} *${start_end}.${plot_ext} &>/dev/null
    tar czvf ${sar_data_tgz} *${start_end}.dat &>/dev/null
    echo "done."
}

send_all() {
    echo -ne "\nSending ${sar_graphs_tgz}, ${sar_data_tgz}... "
    subject="Weekly sar graphs [${start_end}]"
    ( echo -e "Contents:\n\nGraphs:\n"; ls -1 *${start_end}.${plot_ext}; \
      echo -e "\nData:\n"; ls -1 *${start_end}.dat ) | \
      mutt -a "${sar_graphs_tgz}" -a "${sar_data_tgz}" \
           -s "${subject}" ${to_mail}
    echo "done."
}

cleanup() {
    rm -f *${start_end}*
}

### main()
umask 0022 &>/dev/null
pushd /usr/local/tmp/sar &>/dev/null
load_hosts

for r in "${remote_hosts[@]}" ; do
    echo -n "${r}"
    scp ${r}:/var/tmp/*sar*${start_end}.dat . &>/dev/null
    echo -n "."
    if [[ $? -eq 0 ]] ; then
        plot
        echo "done"
    else
        echo "ERROR. Skipping."
    fi
done

compress_all
send_all
cleanup
popd &>/dev/null
