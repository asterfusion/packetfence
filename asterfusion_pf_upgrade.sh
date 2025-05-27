#!/bin/bash

usage() {
cat << EOF
Usage: 
  -h|--help:           display this help and exit

  <export>             export packetfence database and config
    example: /usr/local/pf/asterfusion_pf_upgrade.sh export

  <import>             import packetfence database and config
    example: /usr/local/pf/asterfusion_pf_upgrade.sh import

EOF
    return 2
}

stop_pf(){
    echo "Stop packetfence service."
    STATUS=$(systemctl is-active packetfence-config)

    if [ "$STATUS" = "active" ]; then
        /usr/local/pf/bin/pfcmd service pf stop
        systemctl stop packetfence-config
    fi
}

export_db(){
    echo "Export database."
    mysql -u root -e "GRANT RELOAD, PROCESS ON *.* TO 'pf'@'localhost'; FLUSH PRIVILEGES;"

    /usr/local/pf/addons/backup-and-maintenance.sh > /dev/null
    latest_db=$(ls -1t /root/backup/packetfence-db-dump-innobackup-*.xbstream.gz | head -n 1)
    gzip -dk $latest_db > /dev/null
    mkdir -p /root/backup/restore/

    pushd /root/backup/restore/

    mv /root/backup/packetfence-db-dump-innobackup-*.xbstream /root/backup/restore/
    mbstream -x < packetfence-db-dump-innobackup-*.xbstream > /dev/null
    rm packetfence-db-dump-innobackup-*.xbstream
    mariabackup --prepare --target-dir=./ > /dev/null
}

export_conf(){
    echo "Export config."
    /usr/local/pf/addons/full-import/export.sh /tmp/export.tgz > /dev/null
}

import_db(){
    echo "Import database."
    systemctl stop packetfence-mariadb
 
    pkill -9 -f mariadbd || echo 1 > /dev/null
    mv /var/lib/mysql/ "/var/lib/mysql-`date +%s`"
    mkdir /var/lib/mysql
    
    cd /root/backup/restore/
    
    mariabackup --innobackupex --defaults-file=/usr/local/pf/var/conf/mariadb.conf --move-back --force-non-empty-directories ./
    chown -R mysql: /var/lib/mysql
    systemctl start packetfence-mariadb
    
    mysql_upgrade
    
    systemctl restart packetfence-mariadb 
    mysql -u root -e "USE pf; TRUNCATE TABLE node_current_session;"
}

tar_config(){
    mkdir -p /tmp/asterfuser_pf_upgrade_res
    cp -r /root/backup/restore /tmp/asterfuser_pf_upgrade_res
    cp /tmp/export.tgz /tmp/asterfuser_pf_upgrade_res
    cp /usr/local/pf/asterfusion_pf_upgrade.sh /tmp/asterfuser_pf_upgrade_res
    tar zcvf /tmp/asterfuser_pf_upgrade_res.tar.gz /tmp/asterfuser_pf_upgrade_res > /dev/null
    echo "Export successfully: /tmp/asterfuser_pf_upgrade_res.tar.gz"
}

import_conf(){
    echo "Import config"
    /usr/local/pf/addons/full-import/import.sh --conf -f /tmp/export.tgz
}

start_pf(){
    echo "Start packetfence service."
    /usr/local/pf/bin/pfcmd pfconfig clear_backend
    /usr/local/pf/bin/pfcmd configreload hard
    /usr/local/pf/bin/pfcmd service pf restart
    echo "Upgrade successfully."
}

main() {
   
    case $1 in
        export)
            stop_pf
            export_db
            export_conf
            tar_config
            ;;
        import)
            mkdir -p /root/backup/restore/
            cp -r ./restore/* /root/backup/restore/
            cp export.tgz /tmp/

            import_db
            import_conf
            start_pf
            ;;
        *)
            usage
            ;;
    esac
    return $?
}

case $1 in
    -h|--help|help)
        usage
        exit $?
        ;;
    *)
        main $@
        exit $?
        ;;
esac

exit $?

