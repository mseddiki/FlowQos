#!/bin/ash

# Traffic shaping script
# ---------------------------------------------------------------------
# Limits download speed to the outside world to 1Mbit/s,
# Limits upload speed to the outside world to 1Mbit/s,
# ---------------------------------------------------------------------

while [ true ]
do
   # Starting with a clean slate
   echo Removing any previously set rules...
   tc qdisc del root dev br-lan
   tc qdisc del root dev eth1

   echo Setting root qdisc...
   tc qdisc add dev br-lan root handle 1:  htb default 12
   tc qdisc add dev eth1 root handle 2:  htb default 13

   echo Setting bandwidth classes...
   tc class add dev br-lan parent 1: classid 1:1 htb rate 12mbit ceil 12mbit
   tc class add dev br-lan parent 1:1 classid 1:10 htb rate 1mbit ceil 3mbit
   tc class add dev eth1 parent 2: classid 2:1 htb rate  6mbit ceil 6mbit
   tc class add dev eth1 parent 2:1 classid 2:10 htb rate 1mbit ceil 1mbit
   
   #Checking the nf_conntrack table for new IP address
   cat /proc/net/nf_conntrack |awk  '{print $7}' |awk  -F "=" '{print $2}' | sort -u> /TC/current.txt
   cat /TC/previous.txt
   IPS=$(grep -f /TC/previous.txt /TC/current.txt  -v)
   for IP in $IPS; do

   # attaching every new IP destination to a filter
   echo Creating filters...
   tc filter add dev br-lan protocol ip parent 1:0 prio 1 u32 match ip dst 192.168.142.0/24 flowid 1:10
   tc filter add dev eth1 protocol ip parent 2:0 prio 1 u32 match ip src $IP/24 flowid 2:10
   
   #Fair Queuing
    echo Finishing...
    tc qdisc add dev br-lan parent 1:1 handle 20: sfq perturb 10
    tc qdisc add dev eth1 parent 2:1 handle 30: sfq perturb 10
    mv current.txt previous.txt
    done
    #wait for one second and do it for a new source IP address
    sleep 1

done
