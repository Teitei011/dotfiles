#!/bin/bash
# For NVIDIA GPUs:
usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1"%"}')
# For AMD GPUs (requires radeontop):
# usage=$(radeontop -d 1 -b | grep -oP 'gpu \K\d+')
echo "GPU: $usage"
