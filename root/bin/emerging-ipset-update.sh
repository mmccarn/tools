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
root@cloud:~# 
root@cloud:~# crontab -l
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
 30 2   *   *   *    /usr/bin/certbot renew >> /var/log/le-renew.log
  9 4   *   *   *    /root/bin/emerging-ipset-update.sh >/dev/null 2>&1
@reboot              /root/bin/add-iptables-rules.sh >/dev/null 2>&1
root@cloud:~# cat bin/emerging-ipset-update.txt 
#!/bin/sh
#
# Update emerging fwrules ipset
#
# * creates local statefile with fwrev
# * checks online for newer fwrev
# * downloads new ip list only if the online fwrev is not the local one
# * ensures that 2 ipsets (IPSET_BLACKLIST_HOST / IPSET_BLACKLIST_NET) exist
# * generates ipset --restore file with temporary ipsets
# * swaps temporary ipsets with current ipsets
# * delets temporary ipsets
#
# Changelog:
# 08 Dec 2009 / 1.0 thomas@chaschperli.ch initial version


IPSET_BLACKLIST_HOST=blacklist
IPSET_BLACKLIST_NET=blacklistnet
IPSET_RESTOREFILE=$(mktemp -t emerging-ipset-update-ipsetrestorefile.XXX)

ET_FWREV_STATEFILE="/var/run/emerging-ipset-update.fwrev"
ET_FWREV_URL="http://www.emergingthreats.net/fwrules/FWrev"
ET_FWREV_TEMP=$(mktemp -t emerging-ipset-update-fwrevtemp.XXX)
ET_FWREV_LOCAL="0"
ET_FWREV_ONLINE="0"
ET_FWRULES="http://www.emergingthreats.net/fwrules/emerging-Block-IPs.txt"
ET_FWRULES_TEMP=$(mktemp -t emerging-ipset-update-fwrules.XXXX)

SYSLOG_TAG="EMERGING-IPSET-UPDATE"

WGET="/usr/bin/wget"
IPSET="/usr/sbin/ipset"


do_log () {
        local PRIO=$1; shift;
        echo "$PRIO: $*"
        echo "$*" | logger -p "$PRIO" -t "$SYSLOG_TAG"
}


# check executables
for i in "$WGET" "$IPSET"
do
	if ! [ -x "$i" ] 
	then
		do_log error "$i does not exist or is not executable"
		exit 1
	fi
done

# check files
for i in "$IPSET_RESTOREFILE" "$ET_FWREV_STATEFILE" "$ET_FWREV_TEMP" "$ET_FWRULES_TEMP"
do 
	if ! [ -w "$i" ]
        then
                do_log error "$i does not exist or is not writeable"
                exit 1
        fi
done


# Create statefile if not exists
if ! [ -f "$ET_FWREV_STATEFILE" ]; 
then 
	echo 0 >"$ET_FWREV_STATEFILE"
fi

# get fwrev online
if ! $WGET -O "$ET_FWREV_TEMP" -q "$ET_FWREV_URL";
then
	do_log error "can't download $ET_FWREV_URL to $ET_FWREV_TEMP" 
	exit 1
fi

ET_FWREV_ONLINE=$(cat $ET_FWREV_TEMP)
ET_FWREV_LOCAL=$(cat $ET_FWREV_STATEFILE)


if [ "$ET_FWREV_ONLINE" != "$ET_FWREV_LOCAL" ]
then
	do_log notice "Local fwrev $ET_FWREV_LOCAL does not match online fwrev $ET_FWREV_ONLINE. start update"
	
	if ! "$WGET" -O "$ET_FWRULES_TEMP" -q "$ET_FWRULES"
	then
		do_log error "can't download $ET_FWRULES to $ET_FWREV_TEMP"
	fi
		
	# ensure that ipsets exist
	$IPSET -N $IPSET_BLACKLIST_HOST iphash --hashsize 26244 >/dev/null 2>&1
	$IPSET -N $IPSET_BLACKLIST_NET nethash --hashsize 3456 >/dev/null 2>&1

	# ensure that temp sets do not exist
	$IPSET --destroy "${IPSET_BLACKLIST_HOST}_TEMP" >/dev/null 2>&1
	$IPSET --destroy "${IPSET_BLACKLIST_NET}_TEMP" >/dev/null 2>&1


	# Host IP Adresses
	echo "-N ${IPSET_BLACKLIST_HOST}_TEMP iphash --hashsize 26244" >>$IPSET_RESTOREFILE
	for i in $(egrep '^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$' "$ET_FWRULES_TEMP")
	do
		echo "-A ${IPSET_BLACKLIST_HOST}_TEMP $i" >>$IPSET_RESTOREFILE
	done

	# NET addresses
	echo "-N ${IPSET_BLACKLIST_NET}_TEMP nethash --hashsize 3456" >>$IPSET_RESTOREFILE
	for i in $(egrep '^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}/[[:digit:]]{1,2}$' "$ET_FWRULES_TEMP")
        do 
                echo "-A ${IPSET_BLACKLIST_NET}_TEMP $i" >>$IPSET_RESTOREFILE
        done

	# needed for ipset --restore
	echo "COMMIT" >>$IPSET_RESTOREFILE

	if ! ipset --restore <$IPSET_RESTOREFILE 
	then 
		do_log error "ipset restore failed. restorefile is $IPSET_RESTOREFILE"; exit 1;
	fi


	# swap sets
	ipset --swap ${IPSET_BLACKLIST_HOST} ${IPSET_BLACKLIST_HOST}_TEMP
	ipset --swap ${IPSET_BLACKLIST_NET} ${IPSET_BLACKLIST_NET}_TEMP

	# remove temp sets
	ipset --destroy ${IPSET_BLACKLIST_HOST}_TEMP
	ipset --destroy ${IPSET_BLACKLIST_NET}_TEMP

	if ! echo $ET_FWREV_ONLINE >$ET_FWREV_STATEFILE 
	then
		do_log error "failed to write to fwrev statefile $ET_FWREV_STATEFILE"; exit 1;
	fi
fi

rm -f "$IPSET_RESTOREFILE" "$ET_FWRULES_TEMP" "$ET_FWREV_TEMP"
