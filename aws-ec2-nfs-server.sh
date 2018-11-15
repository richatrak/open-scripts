#!/bin/bash

mkdir -p /data/nfs
chmod -R o+w /data/nfs
touch /data/nfs/nfs-server

echo "/data/nfs *(rw)" >> /etc/exports

service rpcbind restart
service nfs start
service nfslock start

systemctl enable rpcbind
systemctl enable nfs
systemctl enable nfslock

showmount -e localhost
