#!/bin/bash
#
#
# - download the latest copy of setup from www.cygwin.com
# - verify the file signature
# - run the new setup with the supplied arguments
# - Run a quiet upgrade of installed packages if not arguments are supplied
#   ( -q -g)
#
# preparation
# run setup
#   install wget, gnupg2
# download cygwin public key from
#   wget https://cygwin.com/key/pubring.asc
# install cygwin key
#   gpg2 --import pubring.asc
#
# now you're all set...
#
# 64-bit
#SETUP=setup-x86_64.exe
#
# 32-bit
#SETUP=setup-x86.exe
#
# Detect OS and set installer name
SETUP=setup-$(uname -m |sed s/i686/x86/).exe
# Where...
SETUPHOME=~/.cygwin

mkdir -p $SETUPHOME
cd $SETUPHOME
wget -q -O $SETUP https://www.cygwin.com/$SETUP
wget -q -O $SETUP.sig https://www.cygwin.com/$SETUP.sig
#
# verify sig; abort on any problem
gpg2 --verify $SETUP.sig $SETUP 2>/dev/null || exit 1
#
# make setup executable and do a quiet upgrade
chmod 755 $SETUP
if [ $# -eq 0 ]; then
  ./$SETUP -q -g
else
  ./$SETUP
fi
