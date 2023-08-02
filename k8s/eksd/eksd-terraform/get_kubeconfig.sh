#!/bin/bash

set -ex

# Validate the number of arguments
if [ $# -ne 8 ]; then
    echo "Error: This script expects 8 arguments"
    echo "Usage: $0 master_hostname apiserver_private apiserver_public bastion_ip bastion_user bastion_keypair master_user master_keypair"
    exit 1
fi

# Populate variables
master_hostname=$1
apiserver_private=$2
apiserver_public=$3
bastion_ip=$4
bastion_user=$5
bastion_keypair=$6
master_user=$7
master_keypair=$8

# Copy the master keypair into the bastion
scp -i $bastion_keypair -o StrictHostKeyChecking=no $master_keypair $bastion_user@$bastion_ip:~/master_keypair.pem

# SSH into the bastion, fix the pem permissions and use it to fetch the key
ssh $bastion_user@$bastion_ip "chmod 400 ~/master_keypair.pem ; scp -i ~/master_keypair.pem -o StrictHostKeyChecking=no ${master_user}@${master_hostname}:/etc/kubernetes/admin.conf ~/kubeconfig"

# Fetch the kubeconfig from the bastion and cleanup the temp files on the bastion
scp -i $bastion_keypair -o StrictHostKeyChecking=no $bastion_user@$bastion_ip:~/kubeconfig ./kubeconfig.temp
ssh -i $bastion_keypair $bastion_user@$bastion_ip "rm -f ~/kubeconfig ~/master_keypair.pem"

# Replace the original API-server endpoint from the internal IP to the pulic IP
sed "s/${apiserver_private}/${apiserver_public}/g" ./kubeconfig.temp > ./kubeconfig
rm -f ./kubeconfig.temp
