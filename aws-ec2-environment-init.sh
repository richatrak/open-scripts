#!/bin/bash
echo alias vi=vim >> /etc/bashrc
echo set autolist >> /etc/bashrc

echo set background=dark >> /etc/vimrc
echo set softtabstop=2 >> /etc/vimrc
echo set nohlsearch >> /etc/vimrc
echo set sw=2 >> /etc/vimrc
echo set tabstop=2 >> /etc/vimrc
echo set autoindent >> /etc/vimrc

diskPath=/dev/`readlink /dev/sdb`
mkfs -t xfs ${diskPath}
mkdir /data
echo ${diskPath} /data xfs defaults,nofail 0 2 >> /etc/fstab
mount -a

echo 0 0 * * * root yum -y update --security >> /etc/crontab

yum -y update
