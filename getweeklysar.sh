#!/bin/sh
#
# Gather weekly sar report.

start_date=$(date --date="last week" +%Y%m%d)
end_date=$(date --date="yesterday" +%Y%m%d)

sar_output_path=/var/tmp/

getsar() {
    sar_type=$1
    sar_file=$2
    month=$3
    day=$4

    sar_output_file=$(hostname)-sar_${sar_type}_${start_date}-${end_date}.dat

    if [[ "${sar_type}" == "n" ]] ; then
        eth=$(ifconfig | awk '/eth/ {print $1}')
        LC_ALL=C sar -n DEV -f ${sar_file} | grep ^[0-9] | \
            grep -E "${eth}|IFACE" | \
            sed "s/^/${month}-${day}\ /" | \
            tee -a ${sar_output_path}/${sar_output_file} &>/dev/null
    else
        [[ "${sar_type}" == "d" ]] && sar_type="d -p"
        LC_ALL=C sar -${sar_type} -f ${sar_file} | grep ^[0-9] | \
            sed -s "s/^/${month}-${day}\ /" | \
            tee -a ${sar_output_path}/${sar_output_file} &>/dev/null
    fi
}

for f in $(seq 6 -1 1) ; do
    sar_file=$(find /var/log/sa -maxdepth 1 -mtime $f -iname 'sa*' | \
        grep -v sar)
    month=$(date --date="${f} days ago" +%b)
    day=$(date --date="$((f+1)) days ago" +%d)
    echo -n "Getting sar file from ${month} ${day}... "
    for sar_type in u n b d ; do
        getsar ${sar_type} ${sar_file} ${month} ${day}
    done
    echo "done."
done

month=$(date --date="yesterday" +%b)
yesterday=$(date --date="yesterday" +%d)
sar_file=/var/log/sa/sa${yesterday}
echo -n "Getting sar file from ${month} ${yesterday}... "
for sar_type in u n b d ; do
    getsar ${sar_type} ${sar_file} ${month} ${yesterday}
done
echo "done."

echo "SAR data files:"
ls -1 /var/tmp/*sar*${start_date}-${end_date}.dat
