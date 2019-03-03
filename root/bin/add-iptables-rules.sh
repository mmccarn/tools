#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"

# silently recreate ipsets
ipset -! create blacklist iphash --hashsize 26244
ipset -! create blacklistnet nethash --hashsize 3456

# delete top lines in INPUT containing match-set
while iptables -L INPUT 1 |grep match-set >/dev/null 2>&1; 
do 
    iptables -D INPUT 1; 
done

# delete any other lines in INPUT containing match-set
while iptables -L INPUT |grep match-set >/dev/null 2>&1;
do
    RULENO=$(iptables -L INPUT --line-numbers |grep match-set | cut -d" " -f1)
    iptables -D INPUT $RULENO
done

# Insert the 4 lines we need at the top of the INPUT chain in reverse order
iptables -I INPUT -m set --match-set blacklist src -j DROP
iptables -I INPUT -m set --match-set blacklist src -j ufw-logging-deny
iptables -I INPUT -m set --match-set blacklistnet src -j DROP
iptables -I INPUT -m set --match-set blacklistnet src -j ufw-logging-deny

# create fwrev version file
touch "/var/run/emerging-ipset-update.fwrev"

# get the latest blocklist
/root/bin/emerging-ipset-update.sh
