#!/usr/bin/env perl
#
# Get IO stats for processes. To capture:
#
#   echo 1 > /proc/sys/vm/block_dump
#   logrotate -f /etc/logrotate.d/syslog
#
# and wait until the capture window is done. To revert, and view stats:
#
#   echo 0 > /proc/sys/vm/block_dump
#   grep -E '.*kernel:.*block.*' /var/log/messages | sed 's/.*kernel:\ \(.*\)/\1/' | perl iostats
#

use strict;
use warnings;

my %tasks;

while(<>) {
    my ($task, $pid, $activity, $where, $device);
    ($task, $pid, $activity, $where, $device) = $_ =~ m/(\S+)\((\d+)\): (READ|WRITE) block (\d+) on (\S+)/;
    if(!$task) {
        ($task, $pid, $activity, $where, $device) = $_ =~ m/(\S+)\((\d+)\): (dirtied) inode \(.*?\) (\d+) on (\S+)/;
    }
    if($task) {
        my $s = $tasks{$pid} ||= { pid => $pid, task => $task };
        ++$s->{lc $activity};
        ++$s->{activity};
        ++$s->{devices}->{$device};
    }
}

printf("%-15s %10s %10s %10s %10s %10s %s\n", qw(TASK PID TOTAL READ WRITE DIRTY DEVICES));
foreach my $task (
    reverse sort { $a->{activity} <=> $b->{activity} } values %tasks
) {
    printf("%-15s %10d %10d %10d %10d %10d %s\n",
        $task->{task}, $task->{pid},
        ($task->{'activity'} || 0),
        ($task->{'read'}     || 0),
        ($task->{'write'}    || 0),
        ($task->{'dirty'}    || 0),
        join(', ', keys %{$task->{devices}}));
}
