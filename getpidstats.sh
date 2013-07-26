#!/bin/sh
#
# Get perf statistics for a given process.

usage() {
        echo "Get perf statistics for a given process. Must be ran as root."
        echo ""
        echo "Usage: $0 PID [interval count]"
        echo ""
        echo "       interval - in seconds (default: 1)"
        echo "       count    - (default: 10)"
        echo ""
        exit 2
}
printHr() {
        echo "--------------------------------------------------------------------------------------"
}

[[ $(id -u) -ne 0 ]] && echo "Must be ran as root. Exiting." && usage
[[ -z $1 ]] && echo "PID must be entered. Exiting." && usage

PID=$1
[[ -n $2 ]] && INTERVAL=$2 || INTERVAL=1
[[ -n $3 ]] && COUNT=$3 || COUNT=10
[[ $INTERVAL -gt 1 ]] && interval="seconds" || interval="second"
[[ $COUNT -gt 1 ]] && count="times" || count="time"
ps -ef | grep -q $PID &>/dev/null
[[ $? -ne 0 ]] && echo "$PID does not exist. Exiting." && usage

LSOF=$(which lsof)
PIDSTAT=$(which pidstat)
[[ ! -e $LSOF ]] && echo "$LSOF does not exist. Install lsof." && exit 1
[[ ! -e $PIDSTAT ]] && echo "$PIDSTAT does not exist. Install sysstat." && exit 1

psargs="-eo"
pssort="--sort -size,-rss"
fmt="user,pid,ppid,tty,stat,size,rss,vsz,%cpu,%mem,stime,etime,time,args"
srch_str=$(echo $PID | sed 's/^\([a-zA-Z0-9]\)\(.*\)/\1\2/')

NOW=$(date +%s)
LSOF_LOG=/tmp/lsofp_$PID.$NOW
PIDSTATR_LOG=/tmp/pidstatr_$PID.$NOW
PIDSTATU_LOG=/tmp/pidstatu_$PID.$NOW
REPORT=/tmp/$(basename $0)_$PID.$NOW

START=$(date)
PS_STAT=$(/bin/ps ${psargs} ${fmt} ${pssort} | grep "[S]TIME\|${srch_str}" | grep -v "`basename $0`\|$$")
echo "Before capture" >> $LSOF_LOG
$LSOF -p $PID >> $LSOF_LOG
$PIDSTAT -r -p $PID | grep PID > $PIDSTATR_LOG
$PIDSTAT -u -p $PID | grep PID > $PIDSTATU_LOG
echo "Getting stats for PID $PID $COUNT $count, every $INTERVAL $interval"
for i in $(seq 1 $COUNT); do
        $PIDSTAT -r -p $PID | grep -v "^Linux\|PID" | sed '/^$/d' >> $PIDSTATR_LOG
        $PIDSTAT -u -p $PID | grep -v "^Linux\|PID" | sed '/^$/d' >> $PIDSTATU_LOG
        sleep $INTERVAL
        echo -n "."
done
echo "===" >> $LSOF_LOG
echo "After capture" >> $LSOF_LOG
$LSOF -p $PID >> $LSOF_LOG
echo "Done"
END=$(date)

echo "Performance statistics for PID $PID on $(hostname -f) (interval: $INTERVAL $interval; count: $COUNT)" > $REPORT
echo "Started: $START" >> $REPORT
echo "Ended:   $END" >> $REPORT
printHr >> $REPORT
echo "" >> $REPORT
echo "Processes (/bin/ps ${psargs} ${fmt} ${pssort})" >> $REPORT
printHr >> $REPORT
echo "${PS_STAT}" >> $REPORT
printHr >> $REPORT
echo "" >> $REPORT
echo "Open files ($LSOF -p $PID)" >> $REPORT
printHr >> $REPORT
cat $LSOF_LOG >> $REPORT
printHr >> $REPORT
echo "" >> $REPORT
echo "Memory usage ($PIDSTAT -r -p $PID)" >> $REPORT
printHr >> $REPORT
cat $PIDSTATR_LOG >> $REPORT
printHr >> $REPORT
echo "" >> $REPORT
echo "CPU usage ($PIDSTAT -u -p $PID)" >> $REPORT
printHr >> $REPORT
cat $PIDSTATU_LOG >> $REPORT
printHr >> $REPORT

echo "Report: $REPORT"
rm -f $LSOF_LOG $PIDSTATR_LOG $PIDSTATU_LOG

exit 0
