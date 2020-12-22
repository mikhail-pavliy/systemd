#!/bin/bash

###################
# Copy files

ABC=/vagrant/wachlog_data
chmod a+x $ABC/watchlog.sh

mv $ABC/watchlog /etc/sysconfig/
mv $ABC/watchlog.log  /var/log/
mv $ABC/watchlog.sh /opt/
mv $ABC/watchlog.service /etc/systemd/system/
mv $ABC/watchlog.timer /etc/systemd/system/

##################
# Run timer and service

sudo systemctl enable watchlog.timer
sudo systemctl start watchlog.timer
sudo systemctl enable watchlog.service
sudo systemctl start watchlog.service
