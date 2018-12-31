#!/bin/bash
#
# Lookup the latest wazuh agent version from WURL
# Lookup the latest supported ELK version for the new agent from APPURL
# Display the yum command that will install the latest mutually compatible versions

# Note: I recommend that you set the wazuh_repo and elasticsearch-6.x repositories to 'disabled' 
# to allow 'yum update' to install base system updates without breaking the wazuh kibana app

# Alternatively, you can install "normal" updates using
# yum --disablerepo=wazuh_repo --disablerepo=elasticsearch-6.x update

WURL=https://documentation.wazuh.com/current/installation-guide/installing-wazuh-agent/wazuh_agent_sources.html
APPURL=https://github.com/wazuh/wazuh-kibana-app

WVER=$(curl -s $WURL |grep 'curl -Ls' |head -1 |sed 's/.*\/archive\///' |sed 's/\.tar.*//')
ELKVER=$(curl -s $APPURL |grep "kibana-plugin install.*-${WVER/v/}_" |sed s/^.*${WVER/v/}_// |sed s/\.zip.*$// |tail -1)

if [ ! "$1" == "-q" ]; then echo -e "\n#\n# The commands below should safely update wazuh, ELK and the wazuh-kibana app\n#"; fi
if [ ! "$1" == "-q" ]; then echo -e "\n# Update linux (and reboot if necessary) before proceeding"; fi
echo -e "yum --disablerepo=elasticsearch-6.x --disablerepo=wazuh_repo update"

if [ ! "$1" == "-q" ]; then echo -e "\n# Remove the existing wazuh-kibana app"; fi
echo -e "/usr/share/kibana/bin/kibana-plugin remove wazuh"

if [ ! "$1" == "-q" ]; then echo -e "\n# Update elasticsearch and kibana"; fi
echo -e "yum --enablerepo=wazuh_repo --enablerepo=elasticsearch-6.x update-to elasticsearch-$ELKVER kibana-$ELKVER logstash wazuh-api-${WVER/v/} wazuh-manager-${WVER/v/}"

if [ ! "$1" == "-q" ]; then echo -e "\n# Update the wazuh-kibana app (in the background)"; fi
echo -e "/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-${WVER/v/}_${ELKVER}.zip &"

if [ ! "$1" == "-q" ]; then echo -e "\n# Wait for up to 5 minutes for bundles to rebuild"; fi
if [ ! "$1" == "-q" ]; then echo -e "# optionally renice node to speed up bundle rebuild"; fi
echo 'renice -5 $(pgrep node)'

if [ ! "$1" == "-q" ]; then echo -e "\n# Check to see if the bundle rebuild is complete"; fi
echo -e "ps -C node -o pid,ni,cmd |grep install"

if [ ! "$1" == "-q" ]; then echo -e "\n# renice node back to 0 when done"; fi
echo -e 'renice -0 $(pgrep node)'

if [ ! "$1" == "-q" ]; then echo -e "\n# Either reboot or restart elasticsearch, logstash, and kibana..."; fi
echo -e "systemctl daemon-reload"
echo -e "systemctl stop kibana"
echo -e "systemctl stop logstash"
echo -e "systemctl restart elasticsearch"
echo -e "systemctl start logstash"
echo -e "systemctl start kibana"
echo -e "\n"
