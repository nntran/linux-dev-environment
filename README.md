# vagrant-dev-env

Create environments for software development

## Prerequisites

* [Virtualbox 6+](https://www.virtualbox.org/wiki/Downloads)

* [Vagrant 2.2.14+](https://www.vagrantup.com/downloads.html)
* Ansible 2.12.2+

## How to create a development VM ?

### Step 1: Clone the repository

```
git clone https://github.com/nntran/vagrant-dev-env.git
```

### Step 2: Adapt the `inventory.yml` file 

Configure host, private network (`ansible_host`, `bridge`), ...

```yaml
all:
  vars:
    ansible_become: true
    ansible_become_user: root
    ansible_python_interpreter: /usr/bin/python3
    ansible_connection: ssh
    ansible_user: vagrant
    ansible_ssh_pass: vagrant
  hosts:
    vm-dev-ubuntu:
      ansible_host: 10.11.13.40
      vcpu: 2
      memory: 2048
      disk: 20
      # https://app.vagrantup.com/ubuntu
      # https://app.vagrantup.com/generic
      vagrant_box:
        name: generic/ubuntu2004
        version: 3.0.28
      # public network
      network:
        # Use "en0: Wi-Fi (AirPort)" for Mac OS
        # If u dont now, let it by default. 
        # Vagrant will suggest the right bridge to use.  
        bridge: "en0: Wi-Fi (AirPort)"
```

### Step 3: Create the Virtual Machine (VM) with **Vagrant**

```
vagrant up
```

### Step 4: Configure the VM with **Ansible** 

Adapt the `ansible/site.yml` file then install the desired environment:

* Node.js development

```
ansible-playbook -i inventory.yml ansible/site.yml --tags common,docker,nodejs,desktop,terminal,locales,keyboard,users
```

* Java Development

```
ansible-playbook -i inventory.yml ansible/site.yml --tags common,docker,java,maven,desktop,terminal,locales,keyboard,users
```

* DevOps environment

```
ansible-playbook -i inventory.yml ansible/site.yml --tags common,docker,users
```
