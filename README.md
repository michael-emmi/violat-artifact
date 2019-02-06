# Packer-Based Build for Artifact Evaluation

## Building the Virtual Machine

````bash
make
````

## Using the Virtual Machine

````bash
(cd build && shasum -c cav19-violat.ova.sha1)
VBoxManage import build/cav19-violat.ova
VBoxManage modifyvm cav19-violat --natpf1 "guestssh,tcp,,2222,,22"
VBoxManage startvm cav19-violat --type headless
ssh -l cav -p 2222 localhost
````
