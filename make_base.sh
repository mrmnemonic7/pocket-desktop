#!/bin/bash
# First version - 2016-04-13
# 2016-04-20 - Added further support for including custom files.
# 2016-04-22 - Supports 16.04 release.
# 2019-03-20 - Final release for 16.04.
# 2019-09-11 - Migration for 18.04.
# 2019-11-25 - Version 6 updates merged.
# 2020-06-02 - Support for 20.04

#set -x
PDVER=1.4
#UBVER=18.04
UBVER=${1:-20.04}
ISO_NAME=ubuntu-${UBVER}-desktop-amd64.iso
ISO_URL=http://mirror.aarnet.edu.au/pub/ubuntu/releases/${UBVER}/ubuntu-${UBVER}-desktop-amd64.iso
#source ../.config.txt

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# exit after any error
#set -e

BUILD_NO=$(TZ='Australia/NSW' date +%Y%m%d%H%M)

# clear
echo "Pocket Desktop Base Creator"
echo "Version: ${PDVER}"
echo "Build Number: ${BUILD_NO}"
echo "Using Ubuntu ${UBVER}"

if [ -f ../"$ISO_NAME" ]
then
	echo "$ISO_NAME found. We can continue."
else
	echo -e "${YELLOW}$ISO_NAME not found. Please ensure you have an internet connection or things might get a little rough.${NC}"
	#wget -c "$ISO_URL"
	exit 1
	#TODO check MD5 hash
	#wget -c "$MD5_URL"
fi

# mount the ISO
echo "* Accessing $ISO_NAME"
if [ -d mnt/ ]; then
	echo -n -e "${YELLOW}- Detected existing mnt/, removing...${NC}"
	if ls mnt/* 1> /dev/null 2>&1; then
		sudo umount mnt/
		echo -n "ISO removed,"
	fi
	sudo rm -Rf mnt/
	echo -n -e "${YELLOW}residual files removed,${NC}"
	echo "Done"
fi
mkdir mnt
sudo mount -o loop ../$ISO_NAME mnt

echo "* Extracting the ISO..."
if [ -d "extract-cd/" ]; then
	echo -e "${YELLOW}CD extract location already exists from a previous attempting, removing.${NC}"
	sudo rm -Rf extract-cd/
fi
mkdir extract-cd
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

echo "* Extract the Squash FileSystem..."
sudo unsquashfs mnt/casper/filesystem.squashfs
if [ -d "edit/" ]; then
	echo -e "${YELLOW}System folder already exists from a previous attempting, removing.${NC}"
	sudo rm -Rf edit/
fi
sudo mv squashfs-root edit

echo "* Prepare name resolving in chroot"
#sudo cp /etc/resolv.conf edit/etc/
if [ "$DEBIAN_HOST" == 'y' ]; then
sudo mount -o bind /run/ edit/run
fi

echo -n "* Copy our stuff over: "
echo -n "prep,"
#sudo mkdir -p edit/opt/eexam/
sudo cp prep.sh edit/tmp/
sudo chmod +x edit/tmp/prep.sh
sudo cp app-*.sh edit/opt/
sudo cp boot.sh edit/opt/
sudo cp city.png edit/usr/share/backgrounds/warty-final-ubuntu.png
sudo mkdir -p edit/opt/tor
#sudo mkdir -p edit/opt/dev
sudo cp ../linux-privacy/tor*.sh edit/opt/tor/
#sudo cp ../dev-env.sh edit/opt/dev/
sudo chmod +x edit/opt/tor/*.sh
#sudo chmod +x edit/opt/dev/*.sh
echo "Done"

echo "* Preparing essential system resources"
sudo mount -t proc none edit/proc
sudo mount --bind /sys edit/sys
sudo mount --bind /dev edit/dev
sudo mount --bind /dev/pts edit/dev/pts

echo "* Diving into chroot"
if [ "${DEBUGRUN}" == 'y' ]; then
sudo chroot edit /bin/bash -c "DEBUGRUN=1 su - -c /tmp/prep.sh"
else
sudo chroot edit /bin/bash -c "su - -c /tmp/prep.sh"
fi

echo -n "* Cleaning up /tmp..."
sudo rm edit/tmp/prep.sh
sudo rm -Rf edit/tmp/cfg/
echo "Done"

# Save space and clean up APT archives
echo -n "* Cleaning up APT..."
#if [ -d edit${deb_folder}/ ]; then
## sudo rm -Rf edit${deb_folder}/*
cp -R edit/var/cache/apt/* ../dpkg/
rm -Rf edit/var/cache/apt/*
#fi
echo "Done"

echo -n "* Cleaning out driver sources..."
rm -R edit/usr/src/*
echo "Done"

#echo -n "* Cleaning out redundant /opt/eexam files..."
#rm edit/opt/eexam/bootia32.efi
#rm edit/opt/eexam/grub.cfg
#echo "Done"

echo -n "* Cleaning up system resources..."
##sudo umount edit/proc || umount -lf edit/proc
#sudo umount edit/dev/shm
#sudo umount edit/dev/pts
sudo umount -R edit/dev
sudo umount -R edit/sys
sudo umount -R edit/proc
echo "Done"

echo "* Removing /dev /run mount"
#sudo umount -lf edit/dev
if [ "$DEBIAN_HOST" == 'y' ]; then
sudo umount edit/run
fi

# regenerate manifest
echo "* Re-generating filesystem manifest"
sudo chmod +w extract-cd/casper/filesystem.manifest
# sudo su
echo "* chroot dpkg query"
sudo chroot edit /bin/bash -c "dpkg-query -W --showformat='${Package} ${Version}\n'" > extract-cd/casper/filesystem.manifest
# sudo chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest
# exit
sudo cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

# re-compress (squash) the file system
# sudo rm extract-cd/casper/filesystem.squashfs
echo "* Re-creating squash file system"
#sudo mksquashfs edit extract-cd/casper/filesystem.squashfs
sudo mksquashfs edit extract-cd/casper/filesystem.squashfs -comp gzip -Xcompression-level 4

if [ $? -ne 0 ]; then
	echo -e "${RED}MKSQUASHFS failed. This should NOT happen!${NC}"
	exit 1
fi
echo "== New Casper Squashed FileSystem at extract-cd/casper/filesystem.squashfs"

# update filesystem.size
echo "* Updating filesystem.size for ISO consistency"
# sudo su
sudo printf $(du -sx --block-size=1 edit | cut -f1) > extract-cd/casper/filesystem.size
# exit

# generate new md5 sums
echo "* Generating new MD5 checksums"
cd extract-cd
sudo rm md5sum.txt
find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt >/dev/null
cd ..

echo "* Cleaning up original ISO mount"
sudo umount mnt
rmdir mnt

#echo "* Updating Kernel and Initial RAM disk"
#sudo cp edit/boot/vmlinuz-4.13*-generic.efi.signed extract-cd/casper/vmlinuz.efi
#sudo sh -c "gunzip -c edit/boot/initrd.img-4.13*-generic | lzma -c > extract-cd/casper/initrd.lz"

echo "--== New Base System Complete! ==--"
echo -e "${YELLOW}Internal developer note: Remember to 'sudo rm -Rf edit/' and 'sudo rm -Rf extract-cd/' before continuing with git!${NC}"

./make_boot.sh ${PDVER}
exit 0
