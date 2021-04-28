#!/system/bin/sh

## ysl_exec configurations

write() {
 chmod +w "$1" 2> /dev/null
 echo "$2" > "$1" 2> /dev/null
}

## Disable SchedTune by writing 0 to its nodes
write /proc/sys/kernel/sched_boost 0
write /dev/stune/nnapi-hal/schedtune.boost 0
write /dev/stune/nnapi-hal/schedtune.prefer_idle 0
write /dev/stune/schedtune.boost 0

## Ktweat script
# Source: https://github.com/tytydraco/KTweak
# Branch: Latency

# Limit max perf event processing time to this much CPU usage
write /proc/sys/kernel/perf_cpu_time_max_percent 3

# Group tasks for less stutter but less throughput
write /proc/sys/kernel/sched_autogroup_enabled 1

# Execute child process before parent after fork
# Better to set this to 0
write /proc/sys/kernel/sched_child_runs_first 1

# Preliminary requirement for the following values
write /proc/sys/kernel/sched_tunable_scaling 0

# Reduce the frequency of task migrations
write /proc/sys/kernel/sched_migration_cost_ns 5000000

# Improve real time latencies by reducing the scheduler migration time
write /proc/sys/kernel/sched_nr_migrate 4

# Disable scheduler statistics to reduce overhead
write /proc/sys/kernel/sched_schedstats 0

# Disable unnecessary printk logging
write /proc/sys/kernel/printk_devkmsg off

# Start non-blocking writeback later
write /proc/sys/vm/dirty_background_ratio 3

# Start blocking writeback later
write /proc/sys/vm/dirty_ratio 30

# Require dirty memory to stay in memory for longer
write /proc/sys/vm/dirty_expire_centisecs 3000

# Run the dirty memory flusher threads less often
write /proc/sys/vm/dirty_writeback_centisecs 3000

# Disable read-ahead for swap devices
write /proc/sys/vm/page-cluster 0

# Update /proc/stat less often to reduce jitter
write /proc/sys/vm/stat_interval 10

# Swap to the swap device at a fair rate
write /proc/sys/vm/swappiness 100

# Prioritize page cache over simple file structure nodes
write /proc/sys/vm/vfs_cache_pressure 200

# Enable Explicit Congestion Control
write /proc/sys/net/ipv4/tcp_ecn 1

# Enable fast socket open for receiver and sender
write /proc/sys/net/ipv4/tcp_fastopen 3

# Disable SYN cookies
write /proc/sys/net/ipv4/tcp_syncookies 0

if [[ -f "/sys/kernel/debug/sched_features" ]]
then
	# Consider scheduling tasks that are eager to run
	write /sys/kernel/debug/sched_features NEXT_BUDDY

	# Some sources report large latency spikes during large migrations
	write /sys/kernel/debug/sched_features NO_TTWU_QUEUE
fi

for queue in /sys/block/*/queue
do
	# Choose the first governor available
	avail_scheds="$(cat "$queue/scheduler")"

	#This will be slow, since we also check for 
	#schedulers currently unsupported by kernel,
	#which is of no use.
   for sched in cfq noop none #kyber bfq mq-deadline none
	do
		if [[ "$avail_scheds" == *"$sched"* ]]
		then
			write "$queue/scheduler" "$sched"
			break
		fi
    done

	# Do not use I/O as a source of randomness
	write "$queue/add_random" 0

	# Disable I/O statistics accounting
	write "$queue/iostats" 0

	# Reduce heuristic read-ahead in exchange for I/O latency
	write "$queue/read_ahead_kb" 32

	# Reduce the maximum number of I/O requests in exchange for latency
	write "$queue/nr_requests" 32
done
