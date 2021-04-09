#!/bin/bash

VERSION=$1

echo "* Updating Kernel"
sudo cp -v edit/boot/vmlinuz-5*-generic extract-cd/casper/vmlinuz.efi
echo "* Updating Initial RAM disk"
sudo cp -v edit/boot/initrd.img-5*-generic extract-cd/casper/initrd.lz

echo "* Copying grub.cfg"
sudo cp -v grub.cfg extract-cd/boot/grub/grub.cfg

echo "Stamping version ${VERSION}"
sudo sed -i -- "s/V_POCK_DESK/${VERSION}/" extract-cd/boot/grub/grub.cfg

echo "Creating INTRO file"
sudo echo "Welcome to Pocket Desktop v${VERSION}" >> extract-cd/INTRO.TXT
