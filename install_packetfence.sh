#!/bin/bash

echo "Starting install packetfence"
set +e
/usr/bin/dpkg -i /usr/local/pf/packetfence_*~14~0+bookworm1_all.deb
set -e
echo "Fininsed install"
