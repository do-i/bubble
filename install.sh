#!/bin/bash

# This script installs and configure Bubble

export VERSION=v1.1b

# update
if [ "$1" != "skip" ]; then
  sudo apt-get -y update
fi

# Install software
sudo apt-get install -y apache2

if [ ! -d /var/www/html ]; then
  echo "apache2 failed to install"
  exit 1
fi

# change the owner of html dir to pi
sudo chown pi:pi /var/www/html/

# create content directory to bind /mnt
mkdir -p /var/www/html/ext-content

# This should be done once
if [ "" == "$(grep /dev/sda1 /etc/fstab)" ]; then
  sudo tee -a /etc/fstab << EOF
/dev/sda1 /mnt vfat defaults 0 0
/mnt /var/www/html/ext-content none bind 0 0
EOF
fi

# mount the usb device so that web page can acess to files on the usb thumb
sudo mount -a

# make sure that work directory is home directory
cd ~

# delete previously donwloaded zip file and unzipped files
rm -rf ${VERSION}*

# delete previously installed pages except ext-content
for afile in $(ls /var/www/html); do
  if [ "$afile" != "ext-content" ]; then
    rm -rf "/var/www/html/$afile"
  fi
done

# download the zip file that contain shituff and unzip the download file
wget --no-check-certificate -O ${VERSION}.zip "https://sites.google.com/site/dusteacup/bubble-tea/${VERSION}.zip?attredirects=0&d=1"

if [ ! -f ${VERSION}.zip ]; then
  echo "Download failed."
  exit 1
fi

unzip ${VERSION}.zip

if [ ! -d ${VERSION} ]; then
  "Unzip operation failed"
  exit 1
fi

# copy pages to /var/www/html
cp -r ${VERSION}/* /var/www/html

# copy pagegen.py to /usr/local/bin/indexhtmlgen.py
sudo cp ${VERSION}/pagegen.py /usr/local/bin/indexhtmlgen.py

# ensure the python script is executable
sudo chmod +x /usr/local/bin/indexhtmlgen.py

# install libraries for upstart
sudo apt-get -y install upstart dbus-x11

# create upstart job configuration file
sudo tee /etc/init/indexhtmlgen.conf << EOF
description "Upstart job to kick off indexhtmlgen.py script."
author "Bubblers"
start on runlevel [2345]
exec /usr/local/bin/indexhtmlgen.py
EOF

# mount USB drive
sudo mount -a

# kick off generate script
/usr/local/bin/indexhtmlgen.py

echo "${VERSION} installed ... [OK]"
