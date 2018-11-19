#!/bin/bash

mkdir -p /data/nfs
echo NFS-Server:/data/nfs /data/nfs nfs defaults,nofail 0 2 >> /etc/fstab
mount -a
