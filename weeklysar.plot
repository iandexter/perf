# gnuplot command file for plotweeklysar.sh

set terminal PLOT_EXT

set xdata time
set timefmt "%b-%d %H:%M:%S"
set xrange ["START_DATE 00:00:00":"END_DATE 23:50:01"]
set autoscale
set format x "%d%b-%H:%M"
set xtics auto
set ytics nomirror
set grid
set size 2,1
set key right
set timestamp "Generated on %d %b %Y, %H:%M by plotweeklysar" bottom

# CPU and load averages
set output "HOSTNAME_cpu_START_END.PLOT_EXT"
set ylabel "Percentage"
set title "HOSTNAME - CPU usage"
plot "HOSTNAME-sar_u_START_END.dat" using 1:4 title "%user" with lines, \
     "" using 1:6 title "%system" with lines, \
     "" using 1:7 title "%iowait" with lines

# Network
set output "HOSTNAME_net_START_END.PLOT_EXT"
set ylabel "kBytes / second"
set title "HOSTNAME - Network utilization"
plot "HOSTNAME-sar_n_START_END.dat" using 1:4 title "rxkB/s" with lines, \
     "" using 1:5 title "txpck/s" with lines

# IO
set output "HOSTNAME_io_START_END.PLOT_EXT"
set ylabel "Transfers / second"
set title "HOSTNAME - I/O stats"
plot "HOSTNAME-sar_b_START_END.dat" using 1:4 title "rtps" with lines, \
     "" using 1:5 title "wtps" with lines

set xtics auto
# Memory
# set output "HOSTNAME_mem_START_END.PLOT_EXT"
set size 1.0, 1.0
set origin 0.0, 3.0
set ylabel "kb"
set title "HOSTNAME - Memory usage"
plot "HOSTNAME-sar_r_START_END.dat" using 1:2 title "kbmemfree" with points, \
     "" using 1:3 title "kbmemused" with points, \
     "" using 1:5 title "kbbuffers" with points, \
     "" using 1:6 title "kbcached" with points, \
     "" using 1:7 title "kbswpfree" with points
