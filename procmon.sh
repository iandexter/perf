#!/bin/bash
#
# Get processes at any given time, injected and executed via cron. Logs
# can become quite large, so use the accompanying logrotate configuration.
#
#   Sample cron job:
#
#     */10 * * * * /usr/local/bin/procmon.sh
#
#   Custom logrotate config (/etc/logrotate.d/custom-logs):
#
#     /var/log/procmon.log, /var/log/lsof.log {
#       daily
#       compress
#       dateext
#       maxage 365
#       rotate 120
#       missingok
#       notifempty
#       size +4096k
#       create 644 root root
#     }

LOG_FILE=/var/log/procmon.log
LSOF_FILE=/var/log/lsof.log

TIME=$(date '+%b %e\ %T')

psargs="-eo"
pssort="--sort -%cpu,-%mem"
fmt="user,pid,ppid,stat,size,rss,vsz,%cpu,%mem,stime,etime,time,cmd"

[[ ! -f $LOG_FILE ]] && ps ${psargs} ${fmt}  | head -n 1 | sed 's/^/TIMESTAMP\t/' >> $LOG_FILE
ps ${psargs} ${fmt} ${pssort} | grep -v USER | sed "s/^/$TIME\ /g" >> $LOG_FILE

if [[ "$1" = "--lsof" ]] ; then
        pids=$(grep "${TIME}" $LOG_FILE | awk '($7 ~ /D/) {print $5}')
        if [[ -n ${pids} ]] ; then
                [[ ! -f $LSOF_FILE ]] && lsof -p 1 | head -n 1 | sed 's/^/TIMESTAMP\t/' >> $LSOF_FILE
                for p in $(echo "${pids}") ; do
                        lsof -nP -p ${p} | grep -v USER | sed "s/^/$TIME\ /g" >> $LSOF_FILE
                done
        fi
fi
