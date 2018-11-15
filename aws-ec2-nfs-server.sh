#!/bin/bash

mkdir -p /data/nfs
echo "/data/nfs *(rw)" >> /etc/exports

service rpcbind restart
service nfs start

systemctl enable rpcbind
systemctl enable nfs

showmount -e localhost
