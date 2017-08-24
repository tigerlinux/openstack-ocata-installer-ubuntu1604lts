#!/bin/bash
#
# Unattended/SemiAutomatted OpenStack Installer
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# OpenStack OCATA for Ubuntu 16.04lts
#
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#
# First, we source our config file and verify that some important proccess are 
# already completed.
#

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
	mkdir -p /etc/openstack-control-script-config
else
	echo "Can't access my config file. Aborting !"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/broker-installed ]
then
	echo ""
	echo "This module was already completed. Exiting !"
	echo ""
	exit 0
fi

echo ""
echo "Installing Messagebroker Packages"

#
# For debian and ubuntu, we do the job non-interactivelly
#
# The proccess here will not only install the broker, but also configure it with proper
# access permissions. Finally, the proccess will verify proper installation, and if it
# encounters something wrong, it will fail and make stop the main installer.
#

DEBIAN_FRONTEND=noninteractive aptitude -y install rabbitmq-server

echo "NODE_IP_ADDRESS=0.0.0.0" >> /etc/rabbitmq/rabbitmq-env.conf

/etc/init.d/rabbitmq-server stop
/etc/init.d/rabbitmq-server start

update-rc.d rabbitmq-server enable

echo ""
echo "RabbitMQ Installed"
echo ""

echo "Configuring RabbitMQ"
echo ""

rabbitmqctl add_vhost $brokervhost
rabbitmqctl list_vhosts

rabbitmqctl add_user $brokeruser $brokerpass
rabbitmqctl list_users

rabbitmqctl set_permissions -p $brokervhost $brokeruser ".*" ".*" ".*"
rabbitmqctl list_permissions -p $brokervhost

rabbitmqtest=`dpkg -l rabbitmq-server 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $rabbitmqtest == "0" ]
then
	echo ""
	echo "RabbitMQ Installation Failed. Aborting !"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/broker-installed
fi

#
# If the broker installation was successfull, we proceed to apply IPTABLES rules
#

# echo "Applying IPTABLES rules"

# iptables -I INPUT -p tcp -m tcp --dport 5672 -j ACCEPT
# /etc/init.d/netfilter-persistent save


echo "Done"

echo ""
echo "Message Broker Installed and Configured"
echo ""


