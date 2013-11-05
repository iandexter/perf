#!/bin/bash
#
# Displays CPU information.

sockets=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
cpus=$(grep processor /proc/cpuinfo | sort -u | wc -l)
model=$(awk -F: '/model name/ {print $NF}' /proc/cpuinfo | sed 's/^\s\+//' \
        | sort -u | sed 's/\s\+/ /g')

echo "Virtual CPUs            ${cpus}"
if [[ ${sockets} -gt 0 ]] ; then
    cores=$(grep "core id" /proc/cpuinfo | sort -u | wc -l)
    cpu_cores=$(awk '/cpu cores/ {print $NF}' /proc/cpuinfo | sort -u)
    siblings=$(awk '/siblings/ {print $NF}' /proc/cpuinfo | sort -u)
    [[ $(( siblings / cpu_cores )) -gt 1 ]] && ht="Yes" || ht="No"
    [[ $cores -eq 2 ]] && num="Dual"
    [[ $cores -eq 4 ]] && num="Quad"
    echo "Physical processors     ${sockets}"
    echo "Cores per socket        ${cores}"
    echo "Hyperthreading enabled? ${ht}"
    echo "Description             ${sockets} x ${num} ${model}"
else
    echo "Description             ${cpus} x ${model}"
fi
