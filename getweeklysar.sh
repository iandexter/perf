#!/bin/sh
#
# Gather weekly sar report.

### vars
h=$(hostname -f)

start_date=$(date --date="last week" +%Y%m%d)
end_date=$(date --date="yesterday" +%Y%m%d)

sar_types=( b d n r u )

sar_output_path=/var/tmp
sar_output_file="${h}-sar_${sar_types}_${start_date}-${end_date}.dat"
sar_output_file="${sar_output_path}/${sar_output_file}"

### functions
cleanup() {
    if [[ -e "${sar_output_file}" ]] ; then
        ( echo "[I] Found old files. Cleaning up first."; \
          rm -f ${sar_output_path}/*_${start_date}-${end_date}.dat )
    fi
}

getsar() {
    sar_type=$1
    sar_file=$2
    month=$3
    day=$4

    sar_output_file=${h}-sar_${sar_type}_${start_date}-${end_date}.dat
    sar_output_file=${sar_output_path}/${sar_output_file}

    if [[ "${sar_type}" == "n" ]] ; then
        eth=$(/sbin/ifconfig | awk '/eth/ {print $1}')
        LC_ALL=C sar -n DEV -f ${sar_file} 2>/dev/null | grep ^[0-9] | \
            grep -E "${eth}|IFACE" | \
            sed "s/^/${month}-${day}\ /" | \
            tee -a ${sar_output_file} &>/dev/null
    else
        [[ "${sar_type}" == "d" ]] && sar_type="d -p"
        LC_ALL=C sar -${sar_type} -f ${sar_file} 2>/dev/null | grep ^[0-9] | \
            sed -s "s/^/${month}-${day}\ /" | \
            tee -a ${sar_output_file} &>/dev/null
    fi
}

getsartype() {
    sar_file=$1
    month=$2
    day=$3

    echo -n "${month} ${day}"
    for sar_type in "${sar_types[@]}" ; do
        getsar ${sar_type} ${sar_file} ${month} ${day}
    done
}

getlastweek() {
    echo -n "Getting sar files from "
    for f in $(seq 6 -1 1) ; do
        sar_file=$(find /var/log/sa -maxdepth 1 -mtime $f -iname 'sa*' | \
                   grep -v sar)
        month=$(date --date="${f} days ago" +%b)
        day=$(date --date="$((f+1)) days ago" +%d)
        getsartype ${sar_file} ${month} ${day}
        echo -n ", "
    done
}

getyesterday() {
    month=$(date --date="yesterday" +%b)
    day=$(date --date="yesterday" +%d)
    sar_file=/var/log/sa/sa${day}
    getsartype ${sar_file} ${month} ${day}
    echo " - done"
}

listfiles() {
    echo "SAR data files:"
    ls -1 /var/tmp/*sar*${start_date}-${end_date}.dat
}

### main()
unalias rm &>/dev/null
umask 022 &>/dev/null

cleanup
getlastweek
getyesterday
listfiles
