#!/bin/ash

# Traffic shaping script
# ---------------------------------------------------------------------
# Limits download speed to the outside world to 7Mbit/s,
# Limits upload speed to the outside world to 3Mbit/s,
# ---------------------------------------------------------------------

# Starting with a clean slate
echo Removing any previously set rules...
tc qdisc del root dev eth1
tc qdisc del root dev eth0

echo Setting root qdisc...
tc qdisc add dev eth1 root handle 1:  htb default 12
tc qdisc add dev eth0 root handle 2:  htb default 13

echo Setting bandwidth classes...
tc class add dev eth1 parent 1: classid 1:1 htb rate 12mbit ceil 12mbit
tc class add dev eth1 parent 1:1 classid 1:10 htb rate 3mbit ceil 3mbit
tc class add dev eth0 parent 2: classid 2:1 htb rate  12mbit ceil 12mbit
tc class add dev eth0 parent 2:1 classid 2:10 htb rate 7mbit ceil 7mbit


while [ true ]
do
   cat /proc/net/nf_conntrack |awk  '{print $7}' |awk  -F "=" '{print $2}' | sort -u> /TC/current.txt
   cat /TC/previous.txt
   IPS=$(grep -f /TC/previous.txt /TC/current.txt  -v)
   for IP in $IPS; do

   # attaching every new IP destination to a filter
   echo Creating filters...
   tc filter add dev eth1 protocol ip parent 1:0 prio 1 u32 match ip src 192.168.142.0/24 flowid 1:10
   tc filter add dev br-lan protocol ip parent 2:0 prio 1 u32 match ip src $IP/24 flowid 2:10

    echo Finishing...
    tc qdisc add dev eth1 parent 1:10 handle 20: sfq perturb 10
    tc qdisc add dev br-lan parent 2:10 handle 30: sfq perturb 10
    mv current.txt previous.txt
    done
    sleep 1

done
