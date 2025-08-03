#!/bin/bash

# Function to get CPU utilization (as a percentage)
get_cpu_utilization() {
    # Get average CPU usage over 1 second
    CPU_IDLE=$(top -bn2 | grep "Cpu(s)" | tail -n 1 | awk -F'id,' -v prefix="$prefix" '{split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); print v}')
    CPU_USED=$(echo "100 - $CPU_IDLE" | bc)
    echo "$CPU_USED"
}

# Function to get Memory utilization (as a percentage)
get_memory_utilization() {
    MEM_TOTAL=$(free | awk '/Mem:/ {print $2}')
    MEM_USED=$(free | awk '/Mem:/ {print $3}')
    MEM_USED_PERCENT=$(echo "scale=2; $MEM_USED/$MEM_TOTAL*100" | bc)
    echo "$MEM_USED_PERCENT"
}

# Function to get Disk utilization (as a percentage; root partition)
get_disk_utilization() {
    DISK_USED_PERCENT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    echo "$DISK_USED_PERCENT"
}

# Collect health stats
CPU_UTIL=$(get_cpu_utilization)
MEM_UTIL=$(get_memory_utilization)
DISK_UTIL=$(get_disk_utilization)

HEALTHY=true
EXPLANATION=""

# Threshold for health
THRESHOLD=60

# Check each metric
if (( $(echo "$CPU_UTIL > $THRESHOLD" | bc -l) )); then
    HEALTHY=false
    EXPLANATION+="CPU utilization is high ($CPU_UTIL%). "
fi
if (( $(echo "$MEM_UTIL > $THRESHOLD" | bc -l) )); then
    HEALTHY=false
    EXPLANATION+="Memory utilization is high ($MEM_UTIL%). "
fi
if (( $(echo "$DISK_UTIL > $THRESHOLD" | bc -l) )); then
    HEALTHY=false
    EXPLANATION+="Disk utilization is high ($DISK_UTIL%). "
fi

# Output health status
if [ "$HEALTHY" = true ]; then
    STATUS="Healthy"
else
    STATUS="Not Healthy"
fi

# Handle 'explain' argument
if [[ "$1" == "explain" ]]; then
    if [ "$HEALTHY" = true ]; then
        echo "VM Health Status: $STATUS"
        echo "All resource utilizations (CPU: $CPU_UTIL%, Memory: $MEM_UTIL%, Disk: $DISK_UTIL%) are below $THRESHOLD%."
    else
        echo "VM Health Status: $STATUS"
        echo "Reason(s): $EXPLANATION"
    fi
else
    echo "VM Health Status: $STATUS"
fi

exit 0