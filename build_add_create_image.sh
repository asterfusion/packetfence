#!/bin/bash
set -o nounset -o pipefail -o errexit

#Debian Live CD
ISO_IN=${ISO_IN:-debian-live-12.11.0-amd64-gnome.iso}
ISO_OUT=${ISO_OUT:-asterfusion-packetfence-installer-R001.iso}
CHROOT_PATH=/usr/local/pf/pf-iso
PF_PATH=/usr/local/pf
FREE_RADIUS_VERSION=3.2.2
APT_PROXY=http://192.168.0.76:3142

cleanup() {
  umount -l $CHROOT_PATH/chroot/sys/fs/cgroup/devices
  umount -l $CHROOT_PATH/chroot/sys/fs/cgroup
  umount -l $CHROOT_PATH/chroot/dev
  umount -l $CHROOT_PATH/chroot/sys
  umount -l $CHROOT_PATH/chroot/proc
  umount -l $CHROOT_PATH/chroot/home
  umount -l $CHROOT_PATH/chroot
  rm -fr $CHROOT_PATH
  exit 1 
}

#trap cleanup EXIT

# 捕获 ERR 信号（仅在命令失败时触发）
trap 'echo "error occur on $LINENO line"; cleanup' ERR

if ! [ -f $ISO_IN ]; then
	wget https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/$ISO_IN
fi

rm -fr $CHROOT_PATH
mkdir -p $CHROOT_PATH/iso

# 解压原始 ISO
xorriso -osirrox on -indev $ISO_IN -extract / $CHROOT_PATH/iso

# 解压 SquashFS 文件系统（适用于 Live CD）
unsquashfs -d $CHROOT_PATH/chroot $CHROOT_PATH/iso/live/filesystem.squashfs

echo "asterfusion-debian-packetfence" | tee $CHROOT_PATH/chroot/etc/hostname
cp /etc/resolv.conf $CHROOT_PATH/chroot/etc/resolv.conf
chroot $CHROOT_PATH/chroot/ /etc/init.d/networking restart
echo "deb http://deb.debian.org/debian bookworm main" | tee $CHROOT_PATH/chroot/etc/apt/sources.list
touch $CHROOT_PATH/chroot/etc/apt/apt.conf.d/00aptproxy
echo "Acquire::http::Proxy \"$APT_PROXY\";" | tee $CHROOT_PATH/chroot/etc/apt/apt.conf.d/00aptproxy
chroot $CHROOT_PATH/chroot apt-get update
chroot $CHROOT_PATH/chroot apt-get install -y --no-install-recommends vim net-tools apt-transport-https ca-certificates curl gnupg ssh

echo "mount /proc /sys/ /dev ..."
cd $CHROOT_PATH/chroot/
mount --bind . .
cd -
mount -t proc /proc $CHROOT_PATH/chroot/proc
mount -t sysfs /sys $CHROOT_PATH/chroot/sys
mount -o bind /dev $CHROOT_PATH/chroot/dev
mount -o bind $PF_PATH $CHROOT_PATH/chroot/home
mount -t cgroup -o none,name=systemd cgroup $CHROOT_PATH/chroot/sys/fs/cgroup
mount -t tmpfs tmpfs $CHROOT_PATH/chroot/sys/fs/cgroup
mkdir -p $CHROOT_PATH/chroot/sys/fs/cgroup/devices
mount -t cgroup -o devices cgroup $CHROOT_PATH/chroot/sys/fs/cgroup/devices

echo "installing dependencies package"
chroot $CHROOT_PATH/chroot/ bash -c 'curl -fsSL https://inverse.ca/downloads/GPG_PUBLIC_KEY | gpg --dearmor -o /etc/apt/keyrings/packetfence.gpg'
chroot $CHROOT_PATH/chroot/ bash -c 'echo "deb [signed-by=/etc/apt/keyrings/packetfence.gpg] http://inverse.ca/downloads/PacketFence/debian/14.0 bookworm bookworm" > /etc/apt/sources.list.d/packetfence.list'
chroot $CHROOT_PATH/chroot apt-get update
chroot $CHROOT_PATH/chroot/ apt-get install -y  --no-install-recommends \
				packetfence-perl \
				packetfence-ntlm-wrapper  \
				packetfence-golang-daemon \
				openssl \
				packetfence-archive-keyring \
				gpg \
				jq \
				mariadb-server \
				mariadb-client \
				snmp \
				snmptrapfmt  \
				snmptrapd  \
				snmp-mibs-downloader  \
				conntrack  \
				rsyslog \
				ipcalc  \
				ipcalc-ng  \
				apache2  \
				apache2-utils  \
				libapache2-mod-apreq2  \
				libapache2-mod-perl2  \
				libapache2-request-perl  \
				libtie-dxhash-perl  \
				libapache-session-perl \
				libapache-ssllookup-perl  \
				libapache2-mod-systemd  \
				eapoltest \
				liblinux-systemd-daemon-perl  \
				make  \
				binutils \
				samba \
				tdb-tools \
				python3-impacket \
				python-is-python3 \
				krb5-user \
				iproute2 \
				libpcre3 \
				libct4 \
				libmemcached11 \
				libpq5 \
				libiodbc2 \
				libykclient3 \
				libhiredis0.14 \
				libyubikey0 \
				libcollectdclient1 \
				lsb-release \
				wget \
				gnupg2 \
				mariadb-backup

echo "installing freeradius-*"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/libfreeradius3_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/libfreeradius-dev_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-common_$FREE_RADIUS_VERSION+git-2_all.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-config_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-dhcp_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-freetds_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-krb5_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-ldap_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-memcached_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-mysql_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-perl-util_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-postgresql_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-redis_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-rest_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-iodbc_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-utils_$FREE_RADIUS_VERSION+git-2_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/freeradius-yubikey_$FREE_RADIUS_VERSION+git-2_amd64.deb"

chroot $CHROOT_PATH/chroot/ apt-get install -y --no-install-recommends \
				acl \
				vlan \
				libparse-eyapp-perl \
				ipset \
				sudo \
				sscep \
				patch \
				git \
				procps \
				liblist-moreutils-perl \
				libwww-perl  \
				libtry-tiny-perl \
				libapache-htpasswd-perl  \
				libbit-vector-perl  \
				libtext-csv-perl  \
				libtext-csv-xs-perl \
				libcgi-session-serialize-yaml-perl  \
				libtimedate-perl  \
				libapache-dbi-perl \
				libdbd-mysql-perl  \
				libfile-tail-perl  \
				libnetwork-ipv4addr-perl \
				libiptables-parse-perl  \
				libiptables-chainmgr-perl  \
				iptables iptables-netflow-dkms  \
				liblwp-useragent-determined-perl    \
				libnet-netmask-perl  \
				libnet-pcap-perl  \
				libnet-snmp-perl  \
				libsnmp-perl  \
				libfile-fcntllock-perl \
				libnet-telnet-cisco-perl  \
				libparse-recdescent-perl  \
				libnet-cisco-mse-rest-perl  \
				perlmagick \
				libregexp-common-email-address-perl  \
				libregexp-common-time-perl \
				libperl-critic-perl \
				libhtml-template-perl \
				libterm-readkey-perl  \
				libtest-perl-critic-perl  \
				libtest-pod-perl \
				libtest-pod-coverage-perl  \
				libthread-pool-simple-perl \
				libuniversal-require-perl  \
				libuniversal-exports-perl  \
				libnet-rawip-perl \
				libcgi-session-perl  \
				libcgi-session-driver-chi-perl  \
				libconfig-inifiles-perl \
				libdatetime-perl \
				libdatetime-format-builder-perl \
				libdatetime-format-natural-perl \
				libdatetime-format-strptime-perl \
				libdatetime-locale-perl \
				librose-object-perl \
				libdatetime-format-mysql-perl \
				libdatetime-format-oracle-perl \
				libdatetime-format-pg-perl \
				librose-datetime-perl \
				libdatetime-format-dateparse-perl  \
				libdatetime-format-rfc3339-perl  \
				libdbi-perl \
				librose-db-perl \
				librose-db-object-perl \
				libdatetime-timezone-perl \
				libnet-telnet-perl  \
				libregexp-common-perl \
				libhtml-formhandler-perl \
				libreadonly-perl  \
				libtemplate-perl  \
				libtemplate-autofilter-perl  \
				libterm-readkey-perl \
				libuniversal-require-perl  \
				libthread-serialize-perl \
				libnet-ldap-perl  \
				libcrypt-generatepassword-perl  \
				libbytes-random-secure-perl  \
				libcrypt-eksblowfish-perl  \
				libcrypt-smbhash-perl \
				libcrypt-cbc-perl     \
				libdigest-sha3-perl  \
				libcrypt-pbkdf2-perl  \
				perl-doc  \
				libcrypt-rijndael-perl \
				librrds-perl  \
				libnetpacket-perl  \
				libcache-cache-perl    \
				libload-perl  \
				libmime-lite-tt-perl  \
				libmime-lite-perl \
				libconfig-general-perl  \
				libproc-processtable-perl  \
				libperl-version-perl   \
				libdata-swap-perl \
				libdata-structure-util-perl \
				liblinux-fd-perl  \
				liblinux-inotify2-perl  \
				libfile-touch-perl  \
				libhash-merge-perl  \
				libposix-atfork-perl \
				libcrypt-openssl-pkcs12-perl \
				libcrypt-openssl-x509-perl \
				libconst-fast-perl \
				libtime-period-perl \
				libsereal-encoder-perl  \
				libsereal-decoder-perl  \
				libdata-serializer-sereal-perl  \
				libphp-serialization-perl \
				libnet-ip-perl  \
				libdigest-hmac-perl  \
				libcrypt-openssl-pkcs10-perl  \
				libcrypt-openssl-rsa-perl    \
				liburi-escape-xs-perl  \
				libsql-abstract-more-perl    \
				libio-socket-timeout-perl    \
				libpod-markdown-perl  \
				libmojolicious-perl  \
				libnet-dhcp-perl \
				libnet-appliance-session-perl \
				libnet-ssh2-perl \
				libnet-cli-interact-perl \
				libre-engine-re2-perl \
				libnet-interface-perl  \
				libnet-radius-perl  \
				libclass-xsaccessor-perl  \
				libbsd-resource-perl \
				libparse-nessus-nbe-perl  \
				libtest-mockdbi-perl \
				libsoap-lite-perl  \
				libnet-frame-perl  \
				libthread-pool-perl \
				libwww-curl-perl \
			       	libposix-2008-perl  \
				libdata-messagepack-stream-perl  \
				libdata-messagepack-perl \
				libnet-nessus-xmlrpc-perl  \
				libnet-nessus-rest-perl  \
				libfile-slurp-perl \
				libalgorithm-combinatorics-perl \
				libnetaddr-ip-perl  \
				libfile-which-perl \
				libthread-conveyor-monitored-perl  \
				libthread-conveyor-perl  \
				libthread-tie-perl \
				liberror-perl  \
				libio-socket-inet6-perl \
				libio-interface-perl  \
				libnet-route-perl  \
				libnet-arp-perl  \
				libcatalyst-modules-perl \
				libauthen-htpasswd-perl  \
				libcatalyst-authentication-credential-http-perl \
				libcatalyst-authentication-store-htpasswd-perl  \
				libcatalyst-view-tt-perl  \
				libcatalyst-view-csv-perl  \
				libhtml-formfu-perl  \
				libjson-perl  \
				libjson-maybexs-perl \
				libcatalyst-plugin-smarturi-perl \
				libsort-naturally-perl  \
				libchi-perl  \
				libchi-memoize-perl \
				libdata-serializer-perl \
				libchi-driver-redis-perl \
				libredis-fast-perl \
				libcache-fastmmap-perl \
				libterm-size-any-perl \
				libswitch-perl \
				libmodule-install-perl \
				liblocale-gettext-perl \
				locales-all \
				liblog-log4perl-perl \
				liblog-any-perl  \
				liblog-any-adapter-log4perl-perl \
				libnet-oauth2-perl \
				libauthen-radius-perl  \
				libauthen-krb5-simple-perl \
				libio-interactive-perl \
				libtypes-serialiser-perl \
				haproxy  \
				keepalived \
				arping \
				fping  \
				python3-mysqldb \
				libcrypt-smime-perl  \
				libnumber-range-perl \
				libgraph-perl \
				liblasso-perl \
				libcisco-accesslist-parser-perl \
				lsb-release \
				libscalar-list-utils-perl \
				libfile-fcntllock-perl \
				libjson-xs-perl \
				libmoo-perl \
				libnet-dns-perl \
				python3-twisted \
				libconfig-inifiles-perl \
				monit \
			       	uuid-runtime \
				libevent-perl \
				libio-async-perl \
				libpoe-perl \
				liblzf1 \
				redis-server \
				redis-tools
chroot $CHROOT_PATH/chroot/ apt-get install -y --no-install-recommends \
				fingerbank \
				fingerbank-collector \
				netdata \
				libberkeleydb-perl \
				libcache-bdb-perl

echo "installing docker"
chroot $CHROOT_PATH/chroot bash -c 'curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
sudo chroot $CHROOT_PATH/chroot bash -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null'
chroot $CHROOT_PATH/chroot apt-get update
chroot $CHROOT_PATH/chroot apt install -y docker-ce docker-ce-cli containerd.io
chroot $CHROOT_PATH/chroot /usr/bin/dockerd &

sleep 2

DOCKER_IMAGES=$(chroot $CHROOT_PATH/chroot find /home/result/debian -maxdepth 1 -name "*.tar.gz" -printf "%P\n")
for IMAGE in ${DOCKER_IMAGES}; do
	chroot $CHROOT_PATH/chroot docker load -i /home/result/debian/$IMAGE
        echo "docker load -i /home/result/debian/$IMAGE"
done

echo "installing packetfence-*"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/packetfence-golang-daemon_*+bookworm1_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/packetfence-ntlm-wrapper_*+bookworm1_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/packetfence-pfcmd-suid_*+bookworm1_amd64.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/packetfence-config_*+bookworm1_all.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/packetfence-redis-cache_*+bookworm1_all.deb"
chroot $CHROOT_PATH/chroot/ bash -c "dpkg -i /home/result/debian/bookworm/packetfence-archive-keyring_*+bookworm1_all.deb"
cp $PF_PATH/result/debian/bookworm/packetfence_*+bookworm1_all.deb $CHROOT_PATH/chroot/usr/local/pf
cp $PF_PATH/install_packetfence.sh $CHROOT_PATH/chroot/usr/sbin/
chroot $CHROOT_PATH/chroot/ chmod +x /usr/sbin/install_packetfence.sh
cp $PF_PATH/asterfusion_pf_upgrade.sh $CHROOT_PATH/chroot/usr/local/pf
chroot $CHROOT_PATH/chroot/ chmod +x /usr/local/pf/asterfusion_pf_upgrade.sh

chroot $CHROOT_PATH/chroot systemctl set-default multi-user.target

umount -l $CHROOT_PATH/chroot/sys/fs/cgroup/devices
umount -l $CHROOT_PATH/chroot/sys/fs/cgroup
umount -l $CHROOT_PATH/chroot/dev
umount -l $CHROOT_PATH/chroot/sys
umount -l $CHROOT_PATH/chroot/proc
umount -l $CHROOT_PATH/chroot/home
umount -l $CHROOT_PATH/chroot

mkdir -p $CHROOT_PATH/live
mksquashfs $CHROOT_PATH/chroot $CHROOT_PATH/live/filesystem.squashfs
cp $CHROOT_PATH/live/filesystem.squashfs $CHROOT_PATH/iso/live/

xorriso -as mkisofs -iso-level 3 -r -J -joliet-long -b isolinux/isolinux.bin -c isolinux/boot.cat -boot-load-size 4 -boot-info-table  -no-emul-boot -o $ISO_OUT -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus -V "Packetfence 14.0.0" $CHROOT_PATH/iso/
