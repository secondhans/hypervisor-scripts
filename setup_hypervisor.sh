#!/bin/bash
#
# must be run after default 'Wheezy amd64] Byte Standard SW-Raid install

# remove md5


pre_checks () {
	if [ ! -f /root/firstboot-postconfig_has_successfully_ran ]; then
		echo "No indication that firstboot has finished! Refusing to run"
		exit 1
	fi
}



pre_check_remove_md5 () {
	mount | grep -E '^\/dev\/md5.* on \/srv ' &>/dev/null
	if [ $? -ne 0 ]; then
		echo "warning: skipping removal of md5: it's not mounted"
		return 1
	fi

	for dv in sda9 sdb9; do
		mdadm --detail /dev/md5 | grep -E "active sync.*\/dev\/${dv}" &>/dev/null
		if [ $? -ne 0 ]; then
			echo "warning: device /dev/${dv} not found in md5 configuration."
			return 2
		fi
	done

}

remove_md5 () {
	echo "---> STEP: removal /srv om md5"

	pre_check_remove_md5
	RES=$?
	if [ $RES -ne 0 ]; then
		echo "skipping removal of /srv and md5 because of errors in pre_check"
		exit 1
	fi

	umount /srv
	mdadm -S /dev/md5
	mdadm --zero-superblock /dev/sda9
	mdadm --zero-superblock /dev/sdb9

	echo "---> DONE"
	echo 
}




create_lvm () {
	echo "---> STEP: create pv and vg"

	for dv in a b; do
		pvcreate /dev/sd${dv}9
		vgcreate vg${dv} /dev/sd${dv}9
	done

	echo "---> DONE"
	echo 
}



install_packages () {
	echo "---> STEP: install packages"

	for F in /etc/apt/apt.conf /etc/apt/apt.conf.d/11proxy; do 
		if [ -f ${F} ]; then
			echo "removing ${F} because it mucks things up"
			rm -f ${F}
		fi
	done

	apt-get update -y
	apt-get install -y bridge-utils qemu kvm
	echo "---> DONE"
	echo 
}


install_zfs () {
	echo "---> STEP: install ZFS"

	wget http://archive.zfsonlinux.org/debian/pool/main/z/zfsonlinux/zfsonlinux_2%7Ewheezy_all.deb
	dpkg -i zfsonlinux_2~wheezy_all.deb
	apt-get update -y
	apt-get install -y spl-dkms
	apt-get install -y debian-zfs

	echo "---> DONE"
	echo 
}

### MAIN

pre_checks
remove_md5
create_lvm
install_packages
install_zfs


