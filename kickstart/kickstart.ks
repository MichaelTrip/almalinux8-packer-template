# Basic kickstart file for AlmaLinux8
# First, set bootable URL:

url --url="https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/kickstart/" --proxy="proxy.testnet.lan:3128"

# Set repos
repo --name="alamalinux8-baseos" --baseurl="https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/" --mirrorlist="" --proxy="proxy.testnet.lan:3128"
repo --name="alamalinux8-appstream" --baseurl="https://repo.almalinux.org/almalinux/8/AppStream/x86_64/os/" --mirrorlist="" --proxy="proxy.testnet.lan:3128"

# Use text install
text
# Don't run the Setup Agent on first boot
firstboot --disabled
eula --agreed
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network --bootproto=dhcp --onboot=on --ipv6=auto --activate

# Root password
rootpw <encrypted_passwd> --iscrypted

# Ansible user
user --homedir=/home/ansible --name=ansible --password=<encrypted_passwd>> --iscrypted --gecos="Ansible User"

# System services
selinux --permissive
firewall --enabled
services --enabled="NetworkManager,sshd,chronyd"
# System timezone
timezone Europe/Amsterdam --utc --ntp=ntp.testnet.lan
# Partition clearing information

clearpart --all --initlabel --drives=sda
part /boot/efi --fstype="efi" --ondisk=sda --size=600 --fsoptions="umask=0077,shortname=winnt"
part /boot --fstype="xfs" --ondisk=sda --size=1024

# Disk partitionning information
part pv.1 --size=1024 --ondisk=sda --grow
volgroup VG00   pv.1        --pesize=32768
logvol swap --fstype="swap" --size=4096 --name=LV_swap  --vgname=VG00
logvol /    --fstype="xfs" --size=10240    --name=LV_root  --vgname=VG00
logvol /home    --fstype="xfs" --size=4096 --name=LV_home  --vgname=VG00
logvol /var --fstype="xfs" --size=10240 --name=LV_var   --vgname=VG00
logvol /tmp --fstype="xfs" --size=4096 --name=LV_tmp   --vgname=VG00


skipx

reboot

#%packages --ignoremissing --excludedocs
%packages

@^minimal-environment
@guest-agents
@standard
kexec-tools

# unnecessary firmware
-aic94xx-firmware
-atmel-firmware
-b43-openfwwf
-bfa-firmware
-ipw2100-firmware
-ipw2200-firmware
-ivtv-firmware
-iwl*-firmware
-libertas-usb8388-firmware
-ql*-firmware
-rt61pci-firmware
-rt73usb-firmware
-xorg-x11-drv-ati-firmware
-zd1211-firmware
-cockpit
-quota
-alsa-*
-fprintd-pam
-intltool
-microcode_ctl
%end

# Disable kernel dump
%addon com_redhat_kdump --disable
%end

%post
exec >/root/ks-post.log 2>&1
set -x -v

# And copy the SSH keys the Ansible user
mkdir -p ~ansible/.ssh
cat <<- @EOF > ~ansible/.ssh/authorized_keys
ssh-rsa <ssh_pub_key>
@EOF
chmod 700 ~ansible/.ssh
chmod 600 ~ansible/.ssh/authorized_keys
chown -R ansible:ansible ~ansible/.ssh
cd /etc/ansible
ln -s ~ansible/.ssh .

# Allow Ansible unrestricted root access
cat <<- @EOF > /etc/sudoers.d/ansible
	# Ansible user should be able to do it all
	ansible			ALL = (ALL) NOPASSWD:ALL

	# And he doesn't want a TTY, because of accelerated mode
	Defaults:ansible	!requiretty
@EOF
chown root:root /etc/sudoers.d/ansible
chmod 440 /etc/sudoers.d/ansible


systemctl enable vmtoolsd
systemctl start vmtoolsd

%end

