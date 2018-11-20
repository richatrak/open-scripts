#!/bin/bash

mkdir -p /data/nfs
echo NFS:/data/nfs /data/nfs nfs defaults,nofail 0 2 >> /etc/fstab
mount -a
