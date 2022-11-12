#!/bin/sh
set -o errexit

# Run an apt update
sudo apt-get update > /dev/null &

# Is there an option
if [ $# -ne 0 ] ; then
	exec "$@"
else 
	exec sway
fi