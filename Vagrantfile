# -*- mode: ruby -*-
# # vi: set ft=ruby :

# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version '>= 2.2.4'
VAGRANTFILE_API_VERSION = '2'

# Require YAML module
require 'yaml'

file_root = File.dirname(File.expand_path(__FILE__))

# Global vars
group_name = 'Development'
provider = 'virtualbox'

# Read configuration from ansible inventory file
inventory = YAML.load_file("inventory.yml")
puts "==> Inventory: \n#{inventory}"
vars = inventory['all']['vars']
#puts "==> all: \n#{vars}"
user = vars['ansible_user']
password = vars['ansible_ssh_pass']
puts "==> user/password: #{user}/#{password}"

hosts = inventory['all']['hosts']
puts "==> hosts: \n#{hosts}"

#  Fully documented Vagrantfile available
#  https://www.vagrantup.com/docs/vagrantfile/

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    # Required these plugins
    config.vagrant.plugins = [
        "vagrant-hostmanager" => {"version" => "1.8.9"},
        "vagrant-reload" => {"version" => "0.0.1"},
        # "vagrant-disksize"
    ]

    # If true, Vagrant will automatically insert a keypair to use for SSH, 
    # replacing Vagrant's default insecure key inside the machine if detected. 
    # By default, this is true.
    # This only has an effect if you do not already use private keys for authentication 
    # or if you are relying on the default insecure key. If you do not have to care about security 
    # in your project and want to keep using the default insecure key, set this to false.
    #config.ssh.insert_key = false

    # If false, this setting will not include the compression setting 
    # when ssh'ing into a machine. If this is not set, it will default to true 
    # and Compression=yes will be enabled with ssh.
    # config.ssh.compression=false

    # If true, this setting SSH will send keep-alive packets every 5 seconds by default to keep connections alive.
    #config.ssh.keep_alive = true

    # The command to use when executing a command with sudo. 
    # This defaults to sudo -E -H %c. The %c will be replaced by the command that is being executed.
    # config.ssh.sudo_command = "sudo -E -H %c"

    # Hostmanager Config
    # Need to install the plugin vagrant-hostmanger
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = false
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true

    # Server host
    hosts.each do |host|

        puts "==> host: #{host}"
        # VM name
        hostname = host[0]
        puts "==> hostname: #{hostname}"

        # VM infos
        vm_infos = host[1]
        puts "==> vm infos: #{vm_infos}"

        # Create VM
        config.vm.define hostname do |node|

            # https://www.vagrantup.com/docs/vagrantfile/machine_settings.html
            vagrant_box = vm_infos['vagrant_box']
            node.vm.box = vagrant_box['name']
            node.vm.box_version = vagrant_box['version']

            # The URL that the configured box can be found at. 
            # If config.vm.box is a shorthand to a box in HashiCorp's Vagrant Cloud 
            # then this value does not need to be specified. Otherwise, it should point 
            # to the proper place where the box can be found if it is not installed. 
            # This can also be an array of multiple URLs. The URLs will be tried in order.
        
            # Note that any client certificates, insecure download settings, 
            # and so on will apply to all URLs in this list. 
            # The URLs can also be local files by using the file:// scheme. For example: "file:///tmp/test.box".
            #config.vm.box_url = "http://repo.release.xxxxx.yyy/nexus/content/repositories/vagrant/com/xxxxx/vagrant/rhel73/1.0.0/rhel73-1.0.0.box"
        
            # If true, then SSL certificates from the server will not be verified. 
            # By default, if the URL is an HTTPS URL, then SSL certs will be verified.
            node.vm.box_download_insecure = true

            node.vm.hostname = hostname
        
            # The time in seconds that Vagrant will wait for the machine to boot and be accessible. 
            # By default this is 300 seconds.
            node.vm.boot_timeout = 600

            # Enable ssh password connection
            node.ssh.username = user
            node.ssh.password = password
            node.ssh.insert_key = false
        
            # Networks
            # https://www.vagrantup.com/docs/networking/private_network.html
            network = vm_infos['network']
            vm_ip = vm_infos['ansible_host']
            #config.vm.network :private_network, ip: vm_ip, auto_config: false
            node.vm.network :public_network, ip: vm_ip, bridge: network['bridge']
            # Must specified `id: "ssh"` in order to override the default forwarded SSH port.
            #node.vm.network :forwarded_port, guest: 22, host: vm_ssh_port, id: "ssh"

            # https://www.vagrantup.com/docs/virtualbox/
            node.vm.provider "virtualbox" do |vb|
                vb.name = hostname
                vb.cpus = vm_infos['vcpu']
                vb.memory = vm_infos['memory']

                # By default, VirtualBox machines are started in headless mode, meaning there is no UI for the machines visible on the host 
                # machine. Sometimes, you want to have a UI. Common use cases include wanting to see a browser that may be running in the 
                # machine, or debugging a strange boot issue. You can easily tell the VirtualBox provider to boot with a GUI:
                vb.gui = false

                #vb.linked_clone = true
                # https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage-modifyvm.html
                vb.customize ["modifyvm", :id, "--groups", "/#{group_name}"]
                #vb.customize ["modifyvm", :id, "--memory", node['mem']]
                #vb.customize ["modifyvm", :id, "--cpus", node['cpu']]
                #vb.customize ["modifyvm", :id, "--macaddress1", "auto"]
                #vb.customize ["modifyvm", :id, "--vram", "7"]
                #if vm_disk
                #    disk_size = vm_disk.to_i
                #    file_to_disk = File.join(file_root, "#{hostname}.vdi")
                #    unless File.exist?(file_to_disk)
                #        vb.customize ['createhd', '--filename', file_to_disk, '--format', 'VDI', '--size', disk_size * 1024]
                #    end
                #end
                # Enable host desktop integration
                vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
                vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]

                # Customize graphics settings
                vb.customize ["modifyvm", :id, "--vram", "64"]
                vb.customize ["modifyvm", :id, "--accelerate3d", "off"]

                # Enable sound
                #vb.customize ["modifyvm", :id, "--audio", default_vb_audio, "--audiocontroller", default_vb_audiocontroler]
            end

            # Modify sshd_config to connect with ssh
            node.vm.provision "shell", inline: <<-SHELL
                sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
                sudo systemctl restart sshd.service
            SHELL

            # node.vm.provision "file", source: "config", destination: sync_dir + '/config'

            # # Add user
            # user = node['user']
            # user_name = user['name']
            # user_password = user['password']
            # user_home = '/home/' + user['name']
            # node.vm.provision "shell" do |shell|
            #     shell.path = "scripts/add-user.sh"
            #     shell.args = [user_name, user_password, user_home]
            # end

            # Force password change on first use
            # node.vm.provision 'shell', inline: "chage --lastday 0 #{user_name}"
        end
    end 
end 