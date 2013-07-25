#!/bin/bash
#
# Compute memory usage for Oracle instances and DB connections.

### Helper functions

usage() {
    echo "Usage: $0 [sid]";
    exit 1;
}

print_header() {
    header_type=${1-"-"}
    header_width=$2
    for p in `seq 1 $header_width` ; do
        printf "$header_type"
    done
    printf "\n"
}

compute_total() {
    pids="${1}"
    mem_type="${2-writable}"
    local total

    for p in $(echo ${pids}); do
        [[ "${mem_type}" == "writable" ]] && p_total=$(pmap -d $p | awk '$2 ~ /writable/ {print $1}' | sed 's/K//')
        [[ "${mem_type}" == "shared" ]] && p_total=$(pmap -d $p | awk '$7 ~ /shared/ {print $6}' | sed 's/K//')
        total=$(expr $total + $p_total)
    done

    echo $total
}

get_totals() {
    local SID=$1

    echo -n "Computing"
    ### Connections
    conns=oracle$SID
    pid_conns=$(pgrep -f $conns)
    count_conns=$(pgrep -f $conns | wc -l)
    total_priv_mem_conns=$(compute_total "${pid_conns}" "writable")
    avg_priv_mem_conns=$(expr $total_priv_mem_conns / $count_conns)
    echo -n "."

    ### Instance
    shared_inst="ora_pmon_$SID"
    pid_shared_inst=$(pgrep -f $shared_inst)
    sga=$(compute_total "${pid_shared_inst}" "shared")
    echo -n "."

    priv_inst="ora_.*._$SID"
    pid_priv_inst=$(pgrep -f $priv_inst)
    total_priv_mem_inst=$(compute_total "${pid_priv_inst}" "writable")
    echo -n "."

    ### Total RAM and oracle usage
    total_oracle=$(expr $(ipcs -m | awk '$3 ~ /oracle/ {total+=$5}; END {print total}') / 1024)
    ram=$(awk '/^MemTotal/ {print $2}' /proc/meminfo)
    echo -n ".."

    ### Totals
    total_mem=$(expr $total_priv_mem_conns + $total_priv_mem_inst + $sga)
    echo -n "."

    ### Summary
    echo -ne "\r"
    print_header "=" 52
    printf "Total physical memory:                %12d K\n" $ram
    printf "Shared (all instances):               %12d K\n" $total_oracle
    print_header "=" 52
    printf "SID:                                  %14s\n" $(echo $SID | tr '[a-z]' '[A-Z]')
    printf "Number of connections:                %14d\n" $count_conns
    printf "Private memory usage (connections)    %12d K\n" $total_priv_mem_conns
    printf "Average memory usage (per connection) %12d K\n" $avg_priv_mem_conns
    printf "Private memory usage (instance)       %12d K\n" $total_priv_mem_inst
    printf "SGA size:                             %12d K\n" $sga
    print_header "-" 52
    printf "Total memory usage                    %12d K\n" $total_mem
    print_header "-" 52
}

### Main

[[ $(id -u) -ne 0 ]] && echo "Error: Must be ran as root." && usage

instances=$(ps -ef | awk '/[o]ra_pmon/ {print $NF}' | cut -d_ -f3 | sort | tr '\n' '_' |  tr '[A-Z]' '[a-z]')

if [[ $# -lt 1 ]] ; then
    echo -n "Computing memory usage for all instances. It may take a while."
    sleep 2
    if ps -ef | grep -q [o]ra_pmon ; then
        echo -ne "\r"
        print_header " " 100
        for i in $(echo "${instances}" | sed 's/_/\ /g' | sed 's/\s$//') ; do
            get_totals "${i}"
            echo ""
        done
        exit 0
    else
        echo -ne "\r"
        echo "Error: No instances found."
        exit 1
    fi
else
    SID=$(echo ${1} | tr '[A-Z]' '[a-z]')
    if [[ "${instances}" =~ "${SID}_" ]] ; then
        get_totals $SID
    else
        printf "Error: Instance %s not found.\n" $(echo $SID | tr '[a-z]' '[A-Z]')
        exit 1
    fi
fi
