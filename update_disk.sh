#!/bin/bash

FULL=n
USERFOLDER=user

if [ "${USERFOLDER}" -eq "user" ]; then
echo "Replace USERFOLDER id with your account name!"
exit
fi

# Is system mounted?
if [ -d /media/$USERFOLDER/system/casper/ ]; then
    # If previous files are there, delete them
    echo "Detecting and removing previous root FS, kernel and initial RAM filesystem"
    if [ -f /media/$USERFOLDER/system/casper/filesystem.squashfs ]; then
        rm -v /media/$USERFOLDER/system/casper/filesystem.squashfs
    fi
    if [ -f /media/$USERFOLDER/system/casper/initrd.lz ]; then
        rm -v /media/$USERFOLDER/system/casper/initrd*
    fi
    if [ -f /media/$USERFOLDER/system/casper/vmlinuz.efi ]; then
        rm -v /media/$USERFOLDER/system/casper/vmlinuz.efi
    fi

fi

echo "Copying new data to disk"
cd extract-cd/

if [ "${FULL}" == "y" ]; then
cp -Rv . /media/$USERFOLDER/system/
echo "Copying kernel"
sudo cp -v casper/vmlinuz.efi /media/$USERFOLDER/system/casper/
sudo cp -v casper/initrd.lz /media/$USERFOLDER/system/casper/
else
echo -n "BOOT,"
cp -R "boot" /media/$USERFOLDER/system/
echo -n "EFI,"
cp -R "EFI" /media/$USERFOLDER/system/
#cp "../files/bootia32.efi" /media/$USERFOLDER/system/EFI/BOOT/
echo -n "dist info,"
cp -R ".disk" /media/$USERFOLDER/system/
echo -n "preseed,"
cp -R "preseed" /media/$USERFOLDER/system/
echo -n "isolinux,"
cp -R "isolinux" /media/$USERFOLDER/system/
echo -n "pool,"
cp -R "pool" /media/$USERFOLDER/system/
echo -n "E-EXAM LIVE FS,"
#rsync --exclude=filesystem.squashfs casper /media/$USERFOLDER/system/
rsync --progress casper/filesystem.squashfs /media/$USERFOLDER/system/casper/filesystem.squashfs
rsync --progress casper/initrd.lz /media/$USERFOLDER/system/casper/initrd.lz
rsync --progress casper/vmlinuz.efi /media/$USERFOLDER/system/casper/vmlinuz.efi
#cp -R "casper" ${EEXAM_USB}
echo -n "misc."
cp "md5sum.txt" /media/$USERFOLDER/system/
cp "README.diskdefines" /media/$USERFOLDER/system/
fi

cd ..

echo "Done. Remember to update any config file and unmount partitions."
