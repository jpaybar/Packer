#!/bin/bash -eu

SSH_USER=${SSH_USERNAME:-vagrant}
DISK_USAGE_BEFORE_CLEANUP=$(df -h)

echo "==> Cleaning up tmp"
rm -rf /tmp/*

# Cleanup apt cache
echo "==> Autoremoving and cleaning wiht apt"
sudo apt-get -y autoremove --purge
sudo apt-get -y clean
sudo apt-get -y autoclean

# Remove Bash history
echo "==> Removing bash_history"
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/${SSH_USER}/.bash_history

# Clean cfg files  created by AutoInstall
FILE=/etc/cloud/cloud.cfg.d/50-curtin-networking.cfg
if test -f "$FILE"; then
  sudo rm $FILE
fi

FILE=/etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg
if test -f "$FILE"; then
  sudo rm $FILE
fi

FILE=/etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
if test -f "$FILE"; then
  sudo rm $FILE
fi

# Zero out the free space to save space in the final image
echo "==> Freeing disk space zero out"
if [ -d /boot/efi ]; then
    dd if=/dev/zero of=/boot/efi/EMPTY bs=1M || echo "dd exit code $? is suppressed"
    rm -f /boot/efi/EMPTY
fi
dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
rm -f /EMPTY

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quite too early before the large files are deleted
sync

echo "==> Disk usage before cleanup"
echo "${DISK_USAGE_BEFORE_CLEANUP}"
echo
echo "==> Disk usage after cleanup"
df -h