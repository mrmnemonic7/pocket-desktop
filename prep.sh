#!/bin/bash
# Initial version - 2016-04-13
# Changes made for 18.04

function package_install()
{
    if [ "${DEBUGRUN}" == 'y' ]; then
        apt-get -o=Dpkg::Use-Pty=0 --no-install-recommends install $*
    else
        apt-get -qq -o=Dpkg::Use-Pty=0 --no-install-recommends install $* &>/dev/null
    fi
}

function package_remove()
{
	apt-get -qq -o=Dpkg::Use-Pty=0 remove --purge $* &>/dev/null
}

echo "* [Entered chroot environment]"
#mount -t proc none /proc
#mount -t sysfs none /sys
#mount -t devpts none /dev/pts

# environment variables that are helpful.
export HOME=/root
export LC_ALL=C

echo "* Force over-ride resolver"
rm /etc/resolv.conf
echo "nameserver 61.88.88.88" >> /etc/resolv.conf

echo "* Disabling cron update notifiers"
chmod a-x /etc/cron.daily/update-notifier-common
# chmod a-x /etc/cron.weekly/apt-xapian-index
chmod a-x /etc/cron.weekly/update-notifier-common

# eliminate warnings that may scare the faint of heart.
export DEBIAN_FRONTEND=noninteractive

echo "* Removing unncessary software"
echo -n "- Bundled applications,"
echo -n "[Unity shortcuts]"
# remove Unity shortcuts
package_remove unity-scope-video-remote unity-scope-gdrive unity-scope-manpages unity-scope-musicstores unity-scope-virtualbox unity-scope-devhelp unity-scope-tomboy unity-scope-zotero
echo -n "[Games]"
# remove games
package_remove aisleriot gnome-mines gnome-mahjongg gnome-sudoku
#echo -n "[Music]"
# remove music organiser and webcam, scanning and torrent software
#package_remove rhythmbox*
#echo -n "[Webcam]"
#package_remove cheese*
echo -n "[Scanning]"
package_remove simple-scan
echo -n "[Torrent]"
package_remove transmission*
echo -n "[3rd Party Accounts]"
package_remove account-plugin-*
#echo -n "[System Updater]"
# remove Canonical updaters and upgraders
package_remove gnome-software gnome-software-common ubuntu-software update-manager* update-notifier* ubuntu-release-upgrader-core
#echo -n "[Disk Manager]"
# remove partitioning software
#package_remove gnome-disk-utility usb-creator-* gparted
echo -n "[Crash Reporter]"
# remove crash reporter
package_remove whoopsie whoopsie-preferences libwhoopsie*
echo -n "[Thunderbird]"
# remove thunderbird
package_remove thunderbird thunderbird-gnome-support
echo -n "[Installer]"
# remove Ubuntu Installer
package_remove ubiquity ubiquity-casper ubiquity-slideshow-ubuntu
echo -n "[Session Button]"
# remove session icon (user ability to logout, sleep, suspend, etc)
package_remove indicator-session
echo -n "[Zeitgeist]"
# Remove Zeitgeist logging
package_remove libzeitgeist-1.0-1 python-zeitgeist zeitgeist-core
echo -n "[Documentation]"
# Remove Ubuntu documentation
package_remove ubuntu-docs gnome-user-guide
echo -n "[EDS]"
# Remove Evolution Data Server
package_remove libedataserver-1.2-21 libedataserverui-1.2-1 libedata-cal-1.2-28 libedata-book-1.2-25 libecal-1.2-19 libebook-contacts-1.2-2 libebook-1.2-16 libebackend-1.2-10 evolution-data-* ubuntuone*
#echo -n "[Web Browser]"
# Remove default built-in web browser
#package_remove webbrowser-app
#echo -n "[LibreOffice]"
#package_remove --purge libreoffice*
echo -n "[Telnet]"
package_remove telnet
echo -n "[Gnome Calendar]"
package_remove gnome-calendar
echo -n "[Seahorse]"
package_remove seahorse
#echo -n "[Keyring]"
#package_remove gnome-keyring
#echo -n "[GNOME Backup]"
#package_remove deja-dup
echo -n "[SNAP]"
package_remove snapd
echo -n "[Firefox]"
package_remove firefox*
echo "Done"

source /etc/os-release
case "${VERSION_CODENAME}" in
    bionic)
echo "* Updating APT for bionic"
echo "deb http://archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
    ;;
    focal)
echo "* Updating APT for focal"
echo "deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse" >> /etc/apt/sources.list
    ;;
esac

apt-get update
#apt-get -y upgrade
#apt-get -y dist-upgrade

##apt-get -y autoremove
##apt-get -qq --reinstall install unity-control-center

echo "* Bring in latest kernel and display drivers"

case "${VERSION_CODENAME}" in
    bionic)
    apt-get install -y --install-recommends linux-generic-hwe-18.04
    ;;
    focal)
    apt-get install -y --install-recommends linux-generic-hwe-20.04
    ;;
esac
#apt-get install -y --install-recommends linux-generic-hwe-18.04 xserver-xorg-hwe-18.04

echo "* Installing video drivers"
package_install xserver-xorg-video-amdgpu xserver-xorg-video-nouveau xserver-xorg-video-intel

echo "* Install compiler suite"
package_install build-essential

# Are we using remote desktop?
package_remove remmina-common remmina remmina-plugin-rdp remmina-plugin-vnc vino libfreerdp* libwinpr*

echo -n "* Adding a few essentials: "
echo -n "awk,findutils,"
package_install gawk findutils

echo -n "curl,"
package_install curl

# Are we installing Microsoft TrueType Fonts?
echo -n "MS TrueType Core Fonts (web),"
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
package_install cabextract
mkdir -p /tmp/fonts
cd /tmp/fonts
wget -q http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
sudo dpkg -i ttf-mscorefonts-installer_3.6_all.deb &>/dev/null
rm -Rf /tmp/fonts/

echo -n "tcc,"
package_install tcc
echo -n "yad,"
package_install yad
#echo -n "wmctrl,"
#package_install wmctrl
#echo -n "inxi,"
#package_install inxi
#echo -n "pv,"
#package_install pv
#echo -n "inotify-tools,"
#package_install inotify-tools
echo -n "ffmpeg,"
package_install ffmpeg
echo -n "sshpass,"
package_install sshpass
echo -n "geany,"
package_install geany
echo -n "VLC,"
package_install vlc
echo -n "keepassxc,"
package_install keepassxc
echo -n "rarcrack,"
package_install rarcrack
echo "Done"

echo -n "* Adding full laptop mode support: "
# package_install laptop-mode-tools xbacklight
package_install xbacklight
package_install powernap
echo "Done"

# disable updates check
echo -n "* Disabling system update notifier..."
cd /etc/apt/apt.conf.d/
#sed -i -- 's/APT::Periodic::Update-Package-Lists "1"/APT::Periodic::Update-Package-Lists "0"/g' 10periodic
#sed -i -- 's/DPkg/#DPkg/g' 99update-notifier
#sed -i -- 's/APT/#APT/g' 99update-notifier
sed -i -- 's/APT/#APT/g' 20auto-upgrades
cd /
echo "Done"

# add our system text
echo -n "* Updating network issue..."
sed -i '1s/^/Pocket Desktop\nBased on /' /etc/issue
sed -i '1s/^/Pocket Desktop\nBased on /' /etc/issue.net
echo "Done"

# Get rid of shortcut overlay
echo "* Disabling first use keyboard shortcut overlay"
mkdir -p /etc/skel/.cache/unity
touch /etc/skel/.cache/unity/first_run.stamp

# Get rid of examples shortcut on desktop
echo "* Removed examples desktop shortcut"
rm /etc/skel/examples.desktop

# Update and/or create /etc/rc.local
if [ ! -f /etc/rc.local ]; then
# Probably using 18.04
echo "rc.local,"
cat > /etc/systemd/system/rc.local.service << EOF
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

echo "#!/bin/sh" > /etc/rc.local
echo "/opt/boot.sh" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
systemctl enable rc.local.service
chmod +x /opt/boot.sh
fi
sed -i -- 's/exit 0/#exit 0/g' /etc/rc.local
#echo "#!/bin/sh" >> /etc/rc.local
echo "mkdir -p /tmp/cache/" >> /etc/rc.local
echo "chmod 777 /tmp/cache/" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
chmod +x /etc/rc.local
echo "Done"

# user monitoring tools
echo "* Monitoring tools"
package_install fswebcam scrot

# handle initial network configuration
	echo -n "* Enabling network support: "

    echo "network utilities,"
    package_install net-tools

	# fix up systemd delay, we will manage the network further on.
	#sed -i -- 's/sleep/#sleep/g' /etc/init/failsafe.conf

	# Broadcom Firmware extractor
	echo -n "[BC43x]"
	package_install b43-fwcutter firmware-b43-installer firmware-b43legacy-installer

	# Install Broadcom drivers for MacBook Airs
	echo -n "[BCMWL]"
	package_install bcmwl-kernel-source

	# Get latest WPA supplicant
	echo -n "[WPA-Supplicant]"
	package_install wpasupplicant

    echo -n "[DNSMasq]"
    package_install dnsmasq dnsmasq-base

	echo -n "[DNSMasqCFG]"
	sed -i -- '/strict-order/s/#//' /etc/dnsmasq.conf
	sed -i -- '/resolv-file/s/#//' /etc/dnsmasq.conf
	sed -i -- '/resolv-file/s/=/=\/etc\/resolv1.conf/' /etc/dnsmasq.conf
	echo "nameserver 112.109.84.76" >> /etc/resolv1.conf
	echo "nameserver 61.88.88.88" >> /etc/resolv1.conf
	echo "nameserver 1.1.1.1" >> /etc/resolv1.conf
	echo "nameserver 1.0.0.1" >> /etc/resolv1.conf

	echo "Done"

############################
# New hardware
package_install git dkms
mkdir -p /opt/drivers/
cd /opt/drivers/

# Additional firmware
echo -n "* Additional additional Linux firmware "
package_install linux-firmware
echo "Done"

echo -n "* Installing some Broadcom drivers "
package_install broadcom-sta-dkms
echo "Done"

# finished
cd /
############################

cd /opt/

echo "* Installing Firefox"
bash ./app-firefox.sh
rm app-firefox.sh

echo "* Installing Ad-block facilities"
bash ./app-adblock.sh
rm app-adblock.sh

echo "* Installing veracrypt"
package_install libwxgtk3.0-gtk3-0v5
wget -c https://launchpad.net/veracrypt/trunk/1.24-update7/+download/veracrypt-1.24-Update7-Ubuntu-20.04-amd64.deb
dpkg -i ./veracrypt-1.24-Update7-Ubuntu-20.04-amd64.deb
rm -v veracrypt-1.24-Update7-Ubuntu-20.04-amd64.deb

echo "* Installing tor"
package_install tor tor-geoipdb
bash ./tor/tor_eyes.sh
systemctl disable tor

echo "* Install Pidgin"
package_install pidgin

echo "* Install CHNTPW"
package_install chntpw

cd /

echo "* Disable ureadahead"
systemctl disable ureadahead.service
package_remove --purge ureadahead

#echo "* Updating default background"
#sed -i -- 's/zoom/fill/g' /usr/share/gnome-background-properties/ubuntu-wallpapers.xml
#sed -i -- 's/zoom/fill/g' /usr/share/gnome-background-properties/bionic-wallpapers.xml
#cp /usr/share/backgrounds/background.png /usr/share/backgrounds/bionic-final-ubuntu.png

echo "* Modifying system theme"
# Override scrollbar width
# GTK 3.x
mkdir -p /etc/skel/.config/gtk-3.0/
cat > /etc/skel/.config/gtk-3.0/gtk.css << EOF
*{
-GtkRange-slider-width: 20px;
}

.scrollbar.vertical slider,
scrollbar.vertical slider {
min-width: 20px;
}

.scrollbar {
  -GtkScrollbar-has-backward-stepper: true;
  -GtkScrollbar-has-forward-stepper: true;
  -GtkRange-slider-width: 20px;
  -GtkRange-stepper-size: 20px;
}
EOF

# GTK 2.x
cat > /etc/skel/.gtkrc-2.0 << EOF
style "wide-scrollbar-style"
{
  GtkScrollbar::slider_width = 20
}
widget_class "*Scrollbar" style "wide-scrollbar-style"
EOF
##

echo "* Create internal application launchers"
#Xmodmap for Apple keyboards
cat > /etc/skel/.Xmodmap << EOF
clear control
clear mod4

keycode 105 =
keycode 206 =

keycode 133 = Control_L NoSymbol Control_L
keycode 134 = Control_R NoSymbol Control_R
keycode 37 = Super_L NoSymbol Super_L

add control = Control_L
add control = Control_R
add mod4 = Super_L
EOF

echo "* [System preparation done"]
echo "POCKET_DESKTOP_AUTHOR=\"MrMnemonic7\"" >> /etc/os-release

#--------------------------------------------
# Clean up
echo "* Cleaning up log files for fresh start"
rm /var/log/*.log

echo "* Removing redundant files"
#apt-get clean
rm -Rf /opt/drivers/
rm -rf /usr/share/applications/ubuntu-amazon-default.desktop

echo "* Setting timezone"
echo "Australia/NSW" > /etc/timezone

# clean up DNS for real system
echo "* Re-setting DNS"
#rm /etc/resolv.conf
#ln -s /run/resolvconf/resolv.conf /etc/resolv.conf
systemctl disable --now systemd-resolved
echo "nameserver 127.0.0.1" > /etc/resolv.conf

echo "* End of system preparation"

exit
