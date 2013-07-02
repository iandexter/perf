#!/usr/bin/perl
#
# Estimate memory footprint for a process. See proc(5) for details.

use strict;
no warnings 'portable';

if($#ARGV) {
        print("Usage: $0 pid\n");
        exit 64;
}

my $pid = $ARGV[0];
my $shared_file_backed = 0;
my $anonymous = 0;
my $shared_writable = 0;

open(MAPS,"/proc/$pid/maps") || die("Cannot open memory map of pid $pid:$!\n");
my @maps = <MAPS>;
close MAPS;


foreach (@maps) {
        chomp;
        if(m/^([0-9a-f]+)-([0-9a-f]+)\s(....)\s[0-9a-f]+\s..:..\s(\d+)\s+(\S+)?/x) {
                my ($start,$end) = (hex($1),hex($2));
                my $size = $end- $start;
                my $mode = $3;
                my $inode = $4;
                my $filename = $5;

                if($inode != 0 && ($mode eq "r-xp" || $mode eq "r--p" || $mode eq "---p")) {
                        $shared_file_backed += $size;
                }

                elsif($mode eq "rw-p") {
                        $anonymous += $size;
                }

                elsif($mode eq "rw-s") {
                        $shared_writable += $size;
                }

                elsif(defined $filename && ($filename eq "[vdso]" || $filename eq "[vsyscall]")) { }

                elsif($inode == 0 && $mode eq "---p") { }

                else { warn("Warning: Could not parse '$_'\n"); }
        } else {
                die("Incorrect maps format: '$_'");
        }
}

print("PID: $pid\n");
printf("Shared memory backed by a file: %6.2f MB\n", $shared_file_backed / 1024.0 / 1024.0);
printf("Shared writable memory:         %6.2f MB\n", $shared_writable / 1024.0 / 1024.0);
printf("Anonymous memory:               %6.2f MB\n", $anonymous / 1024.0 / 1024.0);
