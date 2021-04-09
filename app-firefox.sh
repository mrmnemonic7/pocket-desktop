#!/bin/bash

FFLANG=en-GB
FFARCH=64
FFCHANNEL=latest-ssl

VERSION=${VERSION:-$(wget --spider -S --max-redirect 0 "https://download.mozilla.org/?product=firefox-${FFCHANNEL}&os=linux${FFARCH}&lang=${FFLANG}" 2>&1 | sed -n '/Location: /{s|.*/firefox-\(.*\)\.tar.*|\1|p;q;}')}

if [ -f "firefox-${VERSION}.tar.bz2" ]; then
	echo "Already have ${VERSION}"
	exit
fi

echo "Fetching Firefox ${VERSION}"

# Fetch latest firefox
echo -n "Fetching Firefox..."
wget -nv --no-clobber --continue --content-disposition 'https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-GB'
echo "Done"

if [ -d ./firefox/ ]; then
echo "Previous Firefox detected, deleting..."
rm -Rf firefox/
fi

echo -n "Extracting Firefox..."
tar jxf firefox-${VERSION}.tar.bz2
rm firefox-${VERSION}.tar.bz2
echo "Done"

echo "Integrating add-ons"
cd firefox/
mkdir -p distribution/extensions
cd distribution/extensions/

echo -n "* uBlock Origin..."
wget --quiet --no-clobber --continue "https://addons.mozilla.org/firefox/downloads/file/3699732/ublock_origin-1.32.2-an+fx.xpi" -O uBlock0@raymondhill.net.xpi
echo "Done"

echo -n "* KeePassXC..."
wget --quiet --no-clobber --continue "https://github.com/keepassxreboot/keepassxc-browser/releases/download/1.7.3/keepassxc-browser_1.7.3_firefox.zip" -O keepassxc-browser@keepassxc.org.xpi
echo "Done"

echo -n "* HTTPS Everywhere..."
wget --quiet --no-clobber --continue "https://www.eff.org/files/https-everywhere-latest.xpi" -O https-everywhere-eff@eff.org.xpi
echo "Done"

#echo -n "* Decentral Eyes..."
#wget --quiet --no-clobber --continue "https://git.synz.io/Synzvato/decentraleyes/uploads/1cc62e70f4c12195c4a7f032ba147593/Decentraleyes.v2.0.14-firefox.xpi" -O jid1-BoFifL9Vbdl2zQ@jetpack.xpi
#echo "Done"

cd /
echo "Finished add-on integration"

echo "Creating launcher for Firefox"
# Launcher for Firefox
cat > /usr/share/applications/firefox.desktop << EOF
[Desktop Entry]
Type=Application
Name=Firefox
Exec=/opt/firefox/firefox
Icon=/opt/firefox/browser/chrome/icons/default/default64.png
Terminal=false
Categories=Internet;
Name[en_AU]=Firefox
EOF
chmod +x /usr/share/applications/firefox.desktop

echo "Creating privacy launcher for Firefox"
# Launcher for Firefox
cat > /usr/share/applications/firefox-privacy.desktop << EOF
[Desktop Entry]
Type=Application
Name=Firefox-Privacy
Exec=/opt/firefox/firefox --no-remote -private-window
Icon=/opt/firefox/browser/chrome/icons/default/default64.png
Terminal=false
Categories=Internet;
Name[en_AU]=Firefox-Privacy
EOF
chmod +x /usr/share/applications/firefox-privacy.desktop

exit
