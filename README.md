# Packer-Based Build for Artifact Evaluation

This artifact build process requires [VirtualBox] and [Packer]. Running `make` generates a VirtualBox image at `build/cav19-violat.ova`.

````bash
make
````

For this to work, the source VM must have SSH installed. Assuming Ubuntu, enter the guest VM and install it:

````bash
sudo apt install -y openssh-server
sudo service ssh status
````

## Using the Virtual Machine

Once the VM is built, you can enter via SSH like so:

````bash
echo "verify the checksum"
(cd build && shasum -c cav19-violat.ova.sha1)

echo "import the VM into VirtualBox"
VBoxManage import build/cav19-violat.ova

echo "start the VM (in headless mode)"
VBoxManage startvm cav19-violat --type headless

echo "enter the VM via SSH"
ssh -l cav -p 2222 localhost
````

[VirtualBox]: https://www.virtualbox.org
[Packer]: https://www.packer.io
