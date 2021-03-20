#!/bin/bash -eux

# Configure network
#
# Parameters :
# - provider : Provider (virtualbox | esxi | ...)
# - nameservers : Name servers addresses
# - gateway : Gateway address
#
# ./configure-network.sh " "esxi" "172.18.0.5,172.18.0.6,8.8.8.8" "192.168.9.254"

echo "=== Start setting network"

provider=$1
# Name servers
nameservers=$2
# Gateway
gateway=$3

apt-get install --no-install-recommends -y net-tools

echo "=== Configuring dns..."
# Hosts running a local caching nameserver
if [ -n "$nameservers" ]; then
    echo "=== Setting local caching nameserver..."
    resolv_conf_file=/etc/resolv.conf

    mv $resolv_conf_file /etc/resolv.conf.bak

    echo "#=== Vagrant ===" >>$resolv_conf_file
    IN="$nameservers"
    servers=$(echo $IN | tr "," "\n")

    for ip in $servers; do
        echo "nameserver $ip" >>$resolv_conf_file
    done

    echo "#======" >>$resolv_conf_file
fi

echo "=== Configuring network..."

eth_count=$(ls -al /sys/class/net | grep -c devices/pci)

# Vagrant use the first interface
first_eth_name=$(ls -al /sys/class/net | grep devices/pci | head -n 1 | awk '{print $9}')
first_eth_ip=$(ifconfig $first_eth_name | grep inet | awk '{print $2}' | cut -f2 -d:)

# VM interface
last_eth_name=$(ls -al /sys/class/net | grep devices/pci | tail -n 1 | awk '{print $9}')
last_eth_ip=$(ifconfig $last_eth_name | grep inet | awk '{print $2}' | cut -f2 -d:)

# If unbuntu 18.04+
os=$( (grep -Po '(?<=DISTRIB_ID=).*' /etc/lsb-release))
version=$( (grep -Po '(?<=DISTRIB_RELEASE=).*' /etc/lsb-release))
echo "=== $os $version"

# if [ "$os" == Ubuntu ] && [ "$version" == 18.* ]; then
if [ "$os" == Ubuntu ]; then

    # if [ -f "$resolv_conf_file" ]
    # then
    #     apt-get install --no-install-recommends -y resolvconf
    #     cat $resolv_conf_file > /etc/resolvconf/resolv.conf.d/head
    #     service resolvconf restart
    # fi

    # https://documentation.online.net/fr/dedicated-server/network/network-configuration-with-netplan
    # https://netplan.io/examples

    # network:
    #   version: 2
    #   renderer: networkd
    #   ethernets:
    #     eth1:
    #       addresses:
    #         - 192.168.9.101/24
    #       #gateway4: 192.168.9.254
    #       routes:
    #         - to: 0.0.0.0/0
    #           via: 192.168.9.254
    #           metric: 100
    #       nameservers:
    #         addresses: [172.18.0.5,172.18.0.6,8.8.8.8]

    # configure first interface (eth0)
    # 01-netcfg.yaml
    netcfg01_file=/etc/netplan/01-netcfg.yaml
    if [ -f "$netcfg01_file" ]; then
        # Set nameservers
        # if [ -n "$nameservers" ]; then
        #     echo "      nameservers:" >> $netcfg01_file
        #     echo "        addresses: [$nameservers]" >> $netcfg01_file
        # fi
        more $netcfg01_file
    fi

    if [ "$provider" == esxi ] || [ "$provider" == nutanix ]; then

        # configure second interface (eth1)
        # 50-vagrant.yaml
        netcfg50_file=/etc/netplan/50-vagrant.yaml
        if [ -f "$netcfg50_file" ]; then

            # Set default gateway
            if [ -n "$gateway" ]; then
                echo "      #gateway4: $gateway" >>$netcfg50_file
                echo "      routes:" >>$netcfg50_file
                echo "        - to: 0.0.0.0/0" >>$netcfg50_file
                echo "          via: $gateway" >>$netcfg50_file
                echo "          metric: 100" >>$netcfg50_file
            fi

            # Set nameservers
            if [ -n "$nameservers" ]; then
                echo "      nameservers:" >>$netcfg50_file
                echo "        addresses: [$nameservers]" >>$netcfg50_file
            fi

            more $netcfg50_file
        fi

        # apply network config
        netplan apply

        echo "=== Deleting interface $last_eth_name (vagrant)..."

        # now delete first interface (eth0)
        # only remote cluster (nutanix or esxi)
        mv $netcfg01_file $netcfg01_file.bkp

        # replace eth1 by the first interface (eth0)
        sed -i "s/$last_eth_name/$first_eth_name/g" $netcfg50_file
        mv $netcfg50_file $netcfg01_file

        # Caution: do not apply now because it will lock network connection
        # Vagrant will reboot after provisioning
        #netplan apply
    fi
fi

# show infos
pwd
echo "========================================"
ifconfig -a
echo "========================================"
route -n
echo "========================================"
ip route
echo "========================================"

echo "=== End setting network"
