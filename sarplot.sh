#!/bin/sh
#
# Gather sar stats and plot perf graphs.

### Supply accordingly.
h=hostname
m=mmm
d=dd

cd /var/log/sa/
LC_ALL=C sar -u -f sa${d} | grep ^[0-9] | sed -s "s/^/$m-${d}\ /" | tee -a /var/tmp/sar_u_$m$d.dat
LC_ALL=C sar -n DEV -f sa${d} | grep ^[0-9] | grep eth0 | sed "s/^/$m-${d}\ /" | tee -a /var/tmp/sar_n_$m$d.dat
LC_ALL=C sar -b -f sa${d} | grep ^[0-9] | sed -s "s/^/$m-${d}\ /" | tee -a /var/tmp/sar_b_$m$d.dat
LC_ALL=C sar -d -p -f sa${d} | grep ^[0-9] | sed -s "s/^/$m-${d}\ /" | tee -a /var/tmp/sar_d_$m$d.dat

cd /var/tmp/

gnuplot <<EOF
set terminal png
set xdata time
set timefmt "%b-%d %H:%M:%S"
set xrange ["$m-$d 00:00:00":"$m-$d 23:50:01"]
set autoscale
set format x "%d%b-%H:%M"
set xtics auto
set ytics nomirror
set grid
set size 2,1
set key right
set timestamp "Generated on %d %b %Y, %H:%M by plotsar.sh" bottom

# CPU and load averages
set output "$h_cpu_$m$d.png"
set ylabel "Percentage"
set title "$h - CPU usage"
plot "/var/tmp/sar_u_$m$d.dat" using 1:4 title "%user" with lines, "" using 1:6 title "%system" with lines, "" using 1:7 title "%iowait" with lines

# Network
set output "$h_net_$m$d.png"
set ylabel "kBytes / second"
set title "$h - Network utilization"
plot "/var/tmp/sar_n_$m$d.dat" using 1:4 title "rxkB/s" with lines, "" using 1:5 title "txpck/s" with lines

# IO
set output "$h_io_$m$d.png"
set ylabel "Transfers / second"
### set y2label "Read-write-read ratio"
set title "$h - I/O stats"
plot "/var/tmp/sar_b_$m$d.dat" using 1:4 title "rtps" with lines, "" using 1:5 title "wtps" with lines
### , "" using 1:8 title "read-write ratio" axis x1y2 with points
EOF
