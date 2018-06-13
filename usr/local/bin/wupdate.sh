#!/bin/bash
WORK="~/wazuh"
VER=$(curl -s https://documentation.wazuh.com/current/installation-guide/installing-wazuh-agent/wazuh_agent_sources.html |grep 'curl -Ls' |head -1 |sed 's/.*\/archive\///' |sed 's/\.tar.*//')

mkdir -p "$WORK"
cd "$WORK"
curl -Ls https://github.com/wAzuh/wazuh/archive/$VER.tar.gz | tar zx
cd wazuh-${VER/v/}

# https://documentation.wazuh.com/3.x/user-manual/reference/unattended-installation.html#unattended-installation
echo -e "USER_NO_STOP=\"$USER_NO_STOP\"\nUSER_LANGUAGE=\"$USER_LANGUAGE\"\nUSER_UPDATE=\"$USER_UPDATE\"" >> etc/preloaded-vars.conf

sudo ./install.sh
