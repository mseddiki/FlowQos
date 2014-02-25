#!/bin/bash
# ---------------------------------------------------------------------
# Memory Monitor for Openwrt Bismark router
# Copyright (c) 2014 Said Seddiki
# ---------------------------------------------------------------------

while [ true ]
do
    Total=$(cat /proc/meminfo | head -n 1 |awk '{print $2}')
    Used=$(cat /proc/meminfo | head -n 2 | tail -n 1 |awk '{print $2}')
    Free=$(($Total-$Used))
    UsedPercentage=$(($Used * 100 / $Total))
    #echo "Free memory: $Free"
    echo "Percentage of used memory: $UsedPercentage%">> MEMORY.txt
    sleep 1
done
