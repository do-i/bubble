#!/bin/bash

# This bash script automates manual installation of raspbian OS
# Require sdcard to be unmounted and no partition should be allocated
DEVICE_NAME="${1}"
RASPBIAN="2016-05-27-raspbian-jessie-lite"
WORK_DIR=$(pwd)

## check if the ${DEVICE_NAME} exists
if [ "${DEVICE_NAME}" == "" ]; then
  echo "Usage: bash ${0} <DEVICE_NAME> #e.g., /dev/sdx"
  exit 1
fi
echo "DEVICE_NAME:${DEVICE_NAME}"
echo "RASPBIAN:${RASPBIAN}"
echo "WORK_DIR:${WORK_DIR}"
### Check if the device name ends with a digit (partition number).
if [[ ${DEVICE_NAME} =~ [0-9]$ ]]; then
  echo "Do not specify device partition. ${DEVICE_NAME}"
  exit 1
fi
CNT=$(sudo fdisk -l | grep ${DEVICE_NAME} | wc -l)

if [ ${CNT} -eq 0 ]; then
  echo "Specified device ${DEVICE_NAME} does not exist. Please specify the device path to your sdcard."
  exit 1
else
  echo "Valid Device ${DEVICE_NAME} Recognized."
fi

if [ ${CNT} -gt 1 ]; then
  echo "Partition(s) found. They will be wiped out."
  for i in $(parted -s ${DEVICE_NAME} print | awk '/^ / {print $1}'); do
    parted -s ${DEVICE_NAME} rm ${i}
  done
fi

echo "Erase everything on ${DEVICE_NAME} and copy ${RASPBIAN}"
if [ ! -f ${WORK_DIR}/${RASPBIAN}.img ]; then
  if [ ! -f ${WORK_DIR}/${RASPBIAN}.zip ]; then
    echo "Donwloading ${RASPBIAN} (357MB)... takes a several minutes."
    wget -q -O "${WORK_DIR}/${RASPBIAN}.zip" "http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2016-05-31/2016-05-27-raspbian-jessie-lite.zip"

    ## verify the downloads
    if [ ! -e "${WORK_DIR}/${RASPBIAN}.zip" ]; then
      echo "download failed..."
      exit 1
    fi
  fi
  unzip ${WORK_DIR}/${RASPBIAN}.zip
  if [ ! -e "${WORK_DIR}/${RASPBIAN}.img" ]; then
      echo "unzip failed..."
      exit 1
  fi
fi

echo "Copying ${WORK_DIR}/${RASPBIAN}.img to ${DEVICE_NAME}... takes about 7 to 8 minutes. Kick back and relax."
sudo dd bs=4M if=${WORK_DIR}/${RASPBIAN}.img of=${DEVICE_NAME}
echo "Sync in progress... do not touch nothing."
sync

echo "Script completed. Check for errors in case there is any."
exit 0
