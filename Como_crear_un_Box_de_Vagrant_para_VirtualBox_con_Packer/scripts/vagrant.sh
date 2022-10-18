#!/bin/bash -eux

# Update the certifying entities in case there is any problem in the download
sudo /usr/sbin/update-ca-certificates --fresh

VAGRANT_INSECURE_KEY_URL="https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub";
VAGRANT_INSECURE_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"

mkdir -p $HOME_DIR/.ssh;
chown -R vagrant $HOME_DIR/.ssh;
chmod -R 700 $HOME_DIR/.ssh;

if command -v wget >/dev/null 2>&1; then # First option in case there are changes in the public key of Vagrant.
    wget --no-check-certificate "$VAGRANT_INSECURE_KEY_URL" -O $HOME_DIR/.ssh/authorized_keys;
else
    echo "${VAGRANT_INSECURE_KEY}" > $HOME_DIR/.ssh/authorized_keys
fi

ls $HOME_DIR/.ssh;
cat $HOME_DIR/.ssh/authorized_keys