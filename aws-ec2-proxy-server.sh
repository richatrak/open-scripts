#!/bin/bash

# ----- Host Variable -----
varHostName=$(cat /etc/aws.ec2.instance.name)
varProxyTarget=${varHostName:0:-5}

# ----- Nginx Install / Variable -----
amazon-linux-extras install nginx1.12 -y

confStartLine=$(grep -n "    server {" /etc/nginx/nginx.conf | head -n 1 | awk -F ":" '{print $1}')
confEndLine=$(grep -n "^    }" /etc/nginx/nginx.conf | head -n 1 | awk -F ":" '{print $1}')


# ----- Pre-Config -----
sed -i -e "${confStartLine},${confEndLine}s/^/#/g" /etc/nginx/nginx.conf
sed -i "${confStartLine} i \ \ \ \ include /etc/nginx/sites-enabled/*.conf;" /etc/nginx/nginx.conf

mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled


# ----- Site Config -----
cat << EOF >> /etc/nginx/sites-available/${varHostName}.localdomain.conf
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;
  root /usr/share/nginx/html;
  
  include /etc/nginx/default.d/*.conf;

  location / {
    if ( \$request_method = 'OPTIONS' )
    {
      add_header 'Access-Control-Allow-Origin'   '*';
      add_header 'Access-Control-Allow-Methods'  'GET, POST, PATCH, DELETE, OPTIONS';
      add_header 'Access-Control-Allow-Headers'  'Origin, X-Requested-With, Content-Type, Accept, Authorization, IAdeaCare-Player-ID, X-HTTP-Method-Override';
      add_header 'Access-Control-Expose-Headers' 'IAdea-Server-Timestamp-Milliseconds, IAdeaCare-Server-File-Milliseconds';
      add_header 'Content-Type' 'application/json';
      return 200 '{}';
    }

    proxy_pass http://${varProxyTarget};
    proxy_set_header Host \$host:\$server_port;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Real-PORT \$remote_port;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}

server {
         
  listen 16821 default_server;
  listen [::]:16821 default_server;
  server_name _;
  root /usr/share/nginx/html;
  
  include /etc/nginx/default.d/*.conf;

  add_header 'Access-Control-Allow-Origin'   '*';
  add_header 'Access-Control-Allow-Methods'  'GET, POST, PATCH, DELETE, OPTIONS';
  add_header 'Access-Control-Allow-Headers'  'Origin, X-Requested-With, Content-Type, Accept, Authorization, IAdeaCare-Player-ID, X-HTTP-Method-Override';
  add_header 'Access-Control-Expose-Headers' 'IAdea-Server-Timestamp-Milliseconds, IAdeaCare-Server-File-Milliseconds';

  add_header 'Content-Type' 'application/json';
  return 200 '{"data": null , "error": "SERVER.BUSY", "errorMessage": "Server is busy, please retry with exponential backoff."}';

}

upstream ${varProxyTarget} {
} #upstream ${varProxyTarget}
EOF

ln -s /etc/nginx/sites-available/${varHostName}.localdomain.conf /etc/nginx/sites-enabled/${varHostName}.localdomain.conf
