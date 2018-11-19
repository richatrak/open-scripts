#!/bin/bash

# ----- Variable -----

varHostName=$(cat /etc/aws.ec2.instance.name)
varProxyTarget=${varHostName:0:-5}

# ----- Install -----
amazon-linux-extras install nginx1.12 -y

confStartLine=$(grep -n "    server {" /etc/nginx/nginx.conf | head -n 1 | awk -F ":" '{print $1}')
confEndLine=$(grep -n "^    }" /etc/nginx/nginx.conf | head -n 1 | awk -F ":" '{print $1}')


# ----- Pre-Config -----
sed -i -e "${confStartLine},${confEndLine}s/^/#/g" /etc/nginx/nginx.conf
sed -i "${confStartLine} i \ \ \ \ include /etc/nginx/sites-enabled/*.conf" /etc/nginx/nginx.conf

mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# ----- Site Config -----
cat << EOF >> /etc/nginx/sites-available/${varHostName}.localdomain.conf
server {
  listen 80 default server;
  listen [::]:80 default server;
  server_name _;
  root /usr/share/nginx/html;
  
  include /etc/nginx/default.d/*.conf;

  location / {
     proxy_pass http://${varProxyTarget};
  }
}

upstream ${varProxyTarget} {
}
EOF

ln -s /etc/sites-available/${varHostName}.localdomain.conf /etc/sites-enabled/${varHostName}.localdomain.conf
