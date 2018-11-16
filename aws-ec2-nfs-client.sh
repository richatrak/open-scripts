#!/bin/bash

mkdir -p /data/nfs
echo NFS-Server:/data/nfs /data/nfs nfs nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0 >> /etc/fstab
mount -a
