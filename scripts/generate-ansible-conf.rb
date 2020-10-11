#!/usr/bin/ruby

# ruby generate-ansible-conf.rb <virtualbox|esxi|nutanix> <front|back|devops>
# Ex: ruby generate-ansible-conf.rb virtualbox front

# Require JSON module
require 'json'

root_file = File.dirname(File.expand_path(__FILE__))
puts "==> Root file: #{root_file}"

# https://www.codecademy.com/articles/ruby-command-line-argv
args = ARGV
puts args.to_s
provider = args[0]

projetc_dir = ".."
config_dir = "#{projetc_dir}/config"
ansible_dir = "#{projetc_dir}/ansible"
playbooks_dir = "#{ansible_dir}/playbooks"
config_file = "#{projetc_dir}/config/config-#{provider}.json"
puts "==> Config file: #{config_file}"

# Read YAML file with box details
# https://www.tutorialspoint.com/ruby/ruby_input_output.htm
#config = JSON.parse(File.read(File.join(File.dirname(__FILE__), config_file)))
config = JSON.parse(File.read(config_file))
puts "==> Config: \n#{config}"

# Generate inventories configuration file
# all:
#   hosts:
#     vm-dev:
#       ansible_ssh_user: systel
#       ansible_ssh_pass: superlinux
#   vars:
#     ansible_connection: ssh
#     ansible_ssh_port: 22
puts "==> Generate inventory file (inventory.yml)\n"
inventory_file = "#{ansible_dir}/inventory.yml"
puts "==> File: #{inventory_file}\n"
File.open(inventory_file, "w") do |file|
    file.syswrite("all:\n")
    file.syswrite("  hosts:\n")
    # For each server
    servers = config['servers']
    servers.each do |server|
        # Cluster nodes definitions
        nodes = server['nodes']
        nodes.each do |vm|
            file.syswrite("    #{vm['ip']}:\n")
            file.syswrite("      ansible_ssh_user: #{vm['user']['name']}\n")
            file.syswrite("      ansible_ssh_pass: #{vm['user']['password']}\n")
            file.syswrite("      ansible_sudo_pass: #{vm['user']['password']}\n")
        end
    end
    file.syswrite("  vars:\n")
    file.syswrite("    ansible_connection: ssh\n")
    file.syswrite("    ansible_ssh_port: 22\n")
    file.syswrite("    ansible_python_interpreter: /usr/bin/python3\n")
end