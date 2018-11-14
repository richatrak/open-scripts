#!/bin/bash -e
# Bastion Bootstrapping
# authors: rich@rak.tw 
# modified from: tonynv@amazon.com, sancard@amazon.com, ianhill@amazon.com
# NOTE: This requires GNU getopt. On Mac OS X and FreeBSD you must install GNU getopt and mod the checkos function so that it's supported



##################################### Functions Definitions

function setup_environment_variables() {
  REGION=$(curl -sq http://169.254.169.254/latest/meta-data/placement/availability-zone/)
    #ex: us-east-1a => us-east-1
  REGION=${REGION: :-1}

  ETH0_MAC=$(/sbin/ip link show dev eth0 | /bin/egrep -o -i 'link/ether\ ([0-9a-z]{2}:){5}[0-9a-z]{2}' | /bin/sed -e 's,link/ether\ ,,g')

  _userdata_file="/var/lib/cloud/instance/user-data.txt"

  INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  EIP_LIST=$(grep EIP_LIST ${_userdata_file} | sed -e 's/EIP_LIST=//g' -e 's/\"//g')

  LOCAL_IP_ADDRESS=$(curl -sq 169.254.169.254/latest/meta-data/network/interfaces/macs/${ETH0_MAC}/local-ipv4s/)

  CWG=$(grep CLOUDWATCHGROUP ${_userdata_file} | sed 's/CLOUDWATCHGROUP=//g')

  # LOGGING CONFIGURATION
  BASTION_MNT="/data/log/bastion"
  BASTION_LOG="bastion.log"
  echo "Setting up bastion session log in ${BASTION_MNT}/${BASTION_LOG}"
  mkdir -p ${BASTION_MNT}
  BASTION_LOGFILE="${BASTION_MNT}/${BASTION_LOG}"
  BASTION_LOGFILE_SHADOW="${BASTION_MNT}/.${BASTION_LOG}"
  touch ${BASTION_LOGFILE}
  ln ${BASTION_LOGFILE} ${BASTION_LOGFILE_SHADOW}
  mkdir -p /usr/bin/bastion
  touch /tmp/messages
  chmod 770 /tmp/messages
  log_shadow_file_location="${bastion_mnt}/.${bastion_log}"

  export REGION ETHO_MAC EIP_LIST CWG BASTION_MNT BASTION_LOG BASTION_LOGFILE BASTION_LOGFILE_SHADOW \
          LOCAL_IP_ADDRESS INSTANCE_ID
}



function amazon_os () {
    
    chown root:ec2-user /usr/bin/script
    service sshd restart
    echo -e "\nDefaults env_keep += \"SSH_CLIENT\"" >>/etc/sudoers
cat <<'EOF' >> /etc/bashrc
#Added by linux bastion bootstrap
declare -rx IP=$(echo $SSH_CLIENT | awk '{print $1}')
EOF

    echo " declare -rx BASTION_LOG=${BASTION_MNT}/${BASTION_LOG}" >> /etc/bashrc

cat <<'EOF' >> /etc/bashrc
declare -rx PROMPT_COMMAND='history -a >(logger -t "ON: $(date)   [FROM]:${IP}   [USER]:${USER}   [PWD]:${PWD}" -s 2>>${BASTION_LOG})'
EOF
    chown root:ec2-user  ${BASTION_MNT}
    chown root:ec2-user  ${BASTION_LOGFILE}
    chown root:ec2-user  ${BASTION_LOGFILE_SHADOW}
    chmod 662 ${BASTION_LOGFILE}
    chmod 662 ${BASTION_LOGFILE_SHADOW}
    chattr +a ${BASTION_LOGFILE}
    chattr +a ${BASTION_LOGFILE_SHADOW}
    touch /tmp/messages
    chown root:ec2-user /tmp/messages
    #Install CloudWatch Log service on AMZN
    yum update -y
    yum install -y awslogs
    echo "file = ${BASTION_LOGFILE_SHADOW}" >> /tmp/groupname.txt
    echo "log_group_name = ${CWG}" >> /tmp/groupname.txt

cat <<'EOF' >> ~/cloudwatchlog.conf

[/var/log/bastion]
datetime_format = %b %d %H:%M:%S
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
EOF

    LINE=$(cat -n /etc/awslogs/awslogs.conf | grep '\[\/var\/log\/messages\]' | awk '{print $1}')
    END_LINE=$(echo $((${LINE}-1)))
    head -${END_LINE} /etc/awslogs/awslogs.conf > /tmp/awslogs.conf
    cat /tmp/awslogs.conf > /etc/awslogs/awslogs.conf
    cat ~/cloudwatchlog.conf >> /etc/awslogs/awslogs.conf
    cat /tmp/groupname.txt >> /etc/awslogs/awslogs.conf
    export TMPREGION=$(grep region /etc/awslogs/awscli.conf)
    sed -i.back "s/${TMPREGION}/region = ${REGION}/g" /etc/awslogs/awscli.conf

    #Restart awslogs service
    local OS=`cat /etc/os-release | grep '^NAME=' |  tr -d \" | sed 's/\n//g' | sed 's/NAME=//g'`
    systemctl start awslogsd.service
    systemctl enable awslogsd.service


    #Run security updates
cat <<'EOF' >> ~/mycron
0 0 * * * root yum -y update --security
EOF
    cat ~/mycron >> /etc/crontab
    rm -f ~/mycron
}

function prevent_process_snooping() {
    # Prevent bastion host users from viewing processes owned by other users.
    mount -o remount,rw,hidepid=2 /proc
    echo "proc /proc proc defaults,hidepid=2 0 0" >> /etc/fstab
    mount -a
}

##################################### End Function Definitions
setup_environment_variables

TCP_FORWARDING=true
X11_FORWARDING=true

amazon_os

prevent_process_snooping
request_eip
