
name = cav19-violat
version = 1.0
description = a VM for the CAV artifact evaluation of Violat
username = cav
password = ae
source = /Users/mje/Downloads/cav19-with-ssh.ova
build = $(CURDIR)/build
target = $(build)/$(name).ova

packer_args += -var 'ssh_username=$(username)'
packer_args += -var 'ssh_password=$(password)'
packer_args += -var 'source_path=$(source)'
packer_args += -var 'output_directory=$(build)'
packer_args += -var 'vm_name=$(name)'
packer_args += -var 'vm_description="$(description)"'
packer_args += -var 'vm_version=$(version)'

sources += artifact.json
sources += provision.sh

$(target): $(sources)
	echo NOTE: this build assumes the source VM includes an SSH server
	packer validate $(packer_args) $<
	packer build $(packer_args) $<
	cd $(@D) && shasum -a 1 $(@F) > $(@F).sha1
