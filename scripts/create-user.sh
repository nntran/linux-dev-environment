#!/bin/bash -eux

# Script for installing common tools
#
# Parameters :
# - user : User name
# - password : Password
# - home : User home
#
# ./create-user.sh "daniel" "xxxxxxxx" "/home/daniel"

# Create user account
user=$1
password=$2
home=$3
salt='sk.NgiIbn9Mh1FC9$i5Epdv819Qg'
encrypted_password=$(openssl passwd -6 -salt $salt $password)
# $6$sk.NgiIbn9Mh1FC9$i5Epdv819Qg/Ttx40XwHvhetoPlN9z3sMe/sRBgQ7gdG32Kghu.KqTE8uYro4fbu38XwKB7Mtc1F3IYBra23Q/
echo "Encrypted password: $encrypted_password"
#echo "$username:$encrypted_password" | chpasswd -e
useradd -s /bin/bash -d $home -m -G sudo $user -p "$encrypted_password"
