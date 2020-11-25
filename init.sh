#!/bin/bash

. "/etc/parallelcluster/cfnconfig"

case "${cfn_node_type}" in

    MasterServer)
        echo "I am the head node"

        systemctl stop slurmctld

        dpkg --configure -a
        apt update
        apt install -y mysql-server
        systemctl restart mysql

        mysql -e "CREATE DATABASE slurm_acct_db;"
        mysql -e "CREATE USER 'slurm'@'localhost' IDENTIFIED BY 'password';"
        mysql -e "GRANT ALL ON slurm_acct_db.* TO 'slurm'@'localhost';"

        adduser slurm syslog
        mkdir /var/log/slurm
        chmod g+rw /var/log/slurm
        chgrp syslog /var/log/slurm

        echo """
[Unit]
Description=Slurm DB controller daemon
After=network.target munge.service
ConditionPathExists=/opt/slurm/etc/slurmdbd.conf

[Service]
Type=forking
EnvironmentFile=-/etc/sysconfig/slurmdbd
ExecStart=/opt/slurm/sbin/slurmdbd $SLURMDBD_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/var/run/slurmdbd.pid
LimitNOFILE=562930
LimitMEMLOCK=infinity
LimitSTACK=infinity

[Install]
WantedBy=multi-user.target
        """ > /etc/systemd/system/slurmdbd.service

        echo """
ArchiveEvents=yes
ArchiveJobs=yes
ArchiveResvs=yes
ArchiveSteps=no
ArchiveSuspend=no
ArchiveTXN=no
ArchiveUsage=no
AuthType=auth/munge
DbdHost=localhost
DbdPort=6830
DebugLevel=info
PurgeEventAfter=1month
PurgeJobAfter=12month
PurgeResvAfter=1month
PurgeStepAfter=1month
PurgeSuspendAfter=1month
PurgeTXNAfter=12month
PurgeUsageAfter=24month
LogFile=/var/log/slurmdbd.log
PidFile=/var/run/slurmdbd.pid
SlurmUser=slurm
StorageType=accounting_storage/mysql
StorageUser=slurm
StoragePass=password
StorageHost=localhost
StoragePort=3306
        """ > /opt/slurm/etc/slurmdbd.conf

        sed -i '/include slurm_parallelcluster.conf/d' /opt/slurm/etc/slurm.conf

        echo """

NodeName=DEFAULT RealMemory=15000

JobAcctGatherType=jobacct_gather/linux
AccountingStorageType=accounting_storage/slurmdbd
AccountingStorageHost=localhost
AccountingStorageUser=slurm
AccountingStoragePort=6830
AccountingStoreJobComment=YES
JobCompType=jobcomp/filetxt
JobCompLoc=/var/log/slurm/job_completions

include slurm_parallelcluster.conf

        """ >> /opt/slurm/etc/slurm.conf

        systemctl restart slurmdbd
        sleep 10
        systemctl restart slurmctld
        sleep 60
        systemctl stop slurmctld
        sleep 60
        systemctl restart slurmctld
    ;;
    
    ComputeFleet)
        echo "I am a compute node"
    ;;
    *)
    ;;
esac
