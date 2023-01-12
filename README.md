# Packer Almalinux 8 template builder

This repository contains code to build a succesful almalinux8 image with a custom kickstart file.

## How does this work?

This repo contains the `.gitlab-ci.yml` file contains the following stages:

1. `verify`
   1. Check Dockerfile linting
   2. Validate packer file
   3. Check kickstart.ks linting
2. `build`
   1. builds container with the Dockerfile when pushed
   2. Build container as a manual action that can be manually executed
3. `publish_on_push` - will publish a new container with the branch as a tag
4. `publish_on_merge` - will publish the container when the code is merged into the `main` branch. Container will have the `latest` tag
5. `deploy_kickstart`
   1. deploy kickstart to a webserver scp manually
   2. deploy kickstart to a webserver via scp when changes in the `kickstart.ks` is detected.
6. `deploy_template` - will deploy template manually to the vcenter. It will also run a Ansible playbook after the first boot to "seal" the template.

## Environment variables

This packer template relies heavily on environment vars. Make sure to set the following vars:

```bash

VCENTER_USERNAME=administrator@vsphere.local
VCENTER_PASSWORD=password
VCENTER_URL=vcenter.testnet.lan
VCENTER_ESX_HOST=192.168.1.1
VCENTER_ISO_LOCATION=[datastore2] ISO/almalinux8_minimal.iso
VM_USERNAME=root
VM_PASSWORD=password
VM_NETWORK=VM Network
VM_NAME=template-almalinux8
VM_DISK_SIZE=10000
VCENTER_DATACENTER=datacenter
VCENTER_CLUSTER=cluster
VCENTER_DATASTORE=datastore2
VCENTER_FOLDER=Templates
ANSIBLE_SSH_KEY=ssh_private_key
```

> **_NOTE:_** Because environment variables are used this can be easily integrated into a CI/CD pipeline.

The environment variables can be set within the `.gitlab-ci.yml` file or by using the environment variables in the CI/CD section of the project.

## Prerequisites
### Webserver

The kickstart file is used to install the template. Make sure to set the variable `HTTP_IP` and `HTTP_PATH` in your `template.pkr.hcl` file. Also, create a user on the webserver and deploy the neccesary ssh keys and add them to your environment variables. In the case of this repository it is done by using the masked variables in Gitlab.

### Store the iso file on the vcenter datastore

Make sure the ISO is somewhere on the vSphere cluster so packer can use it to create the template. Make sure to set the `VCENTER_ISO_LOCATION` variable to the right location.

## Run

In this case, it can be run by executing the pipeline. In other cases, you can run it by using the following:

### Docker example:
```bash
$ docker run --rm -it imagename:tag packer build template.pkr.hcl
```

### Podman example:
```bash
$ podman run --rm -it imagename:tag packer build template.pkr.hcl
```

