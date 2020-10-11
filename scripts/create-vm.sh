#!/bin/bash -eux

# Create a developpment VM
#
# Parameters :
#      - provider   : Provider name (virtualbox, hyperv, esxi, nutanix)
#      - env_type   : Environment type (front, back, devops)
#      - desktop    : If true, it willl install a desktop GUI
#
# ./create-vm.sh "virtualbox" "devops" true

provider=$1
env_type=$2
desktop=$3

scripts_dir=$PWD
cd ..
root_dir=$PWD
ansible_dir=$root_dir/ansible

echo "================================================"
echo "Setting up cluster configuration files..."
# Create Vagrantfile configuration
cd $root_dir && ln -s -f Vagrantfile.$provider Vagrantfile

echo "================================================"
echo "Generate ansible configuration files..."

# # Ruby
# ruby generate-ansible-conf.rb $cluster_type $provider
# Or with Docker
# docker run -it --rm --name genconf \
#     -v $root_dir:/opt \
#     -w /opt \
#     ruby:2.5 /bin/bash -c "cd scripts && ruby generate-ansible-conf.rb $cluster_type $provider"
docker run -it --rm --name genconf \
    -v $root_dir:/opt \
    -w /opt \
    ruby:2.5 /bin/bash -c "cd scripts && ruby generate-ansible-conf.rb $provider"

echo "================================================"
echo "Provisioning new VM for $provider with Vagrant..."
cd $root_dir
# Create Vagrantfile configuration
ln -s -f Vagrantfile.$provider Vagrantfile
if [ -d ".vagrant" ]; then
    # vagrant destroy -f
    # rm -rf ".vagrant"
    echo "An VM is already exist!"
else
    vagrant up
fi

echo "================================================"
echo "Setting up VM for $env_type environment..."

cd $ansible_dir

# Check access VM
ansible-playbook playbooks/check-hosts.yml -i inventory.yml

# Install common packages
ansible-playbook playbooks/install-common.yml -i inventory.yml

# Update packages
ansible-playbook playbooks/upgrade-packages.yml -i inventory.yml

# Install Docker
ansible-playbook playbooks/install-docker.yml -i inventory.yml

if [[ "$env_type" == front ]]; then
    # Front development environmment
    # Install nodejs
    ansible-playbook playbooks/install-nodejs.yml -i inventory.yml
fi

if [[ "$env_type" == back ]]; then
    # Back development environmment
    # Install Java
    #ansible-playbook playbooks/install-java.yml -i inventory.yml
    # Install Maven
    ansible-playbook playbooks/install-maven.yml -i inventory.yml
fi

if [[ "$env_type" == devops ]]; then
    # Front development environmment
    # Install ansible
    ansible-playbook playbooks/install-ansible.yml -i inventory.yml
fi

if [ $desktop ]; then

    # Install desktop
    ansible-playbook playbooks/install-desktop.yml -i inventory.yml

    # Install vscode
    ansible-playbook playbooks/install-vscode.yml -i inventory.yml

    # Install Powerline
    ansible-playbook playbooks/install-powerline.yml -i inventory.yml

    # Install virtualbox additions
    if [[ "$provider" == virtualbox ]]; then
        # Install virtualbox additions
        ansible-playbook playbooks/install-virtualbox-guest.yml -i inventory.yml
    fi
fi

# Configure
ansible-playbook playbooks/configure.yml -i inventory.yml

# Clean to finish
ansible-playbook playbooks/clean.yml -i inventory.yml

echo "Finish!"
