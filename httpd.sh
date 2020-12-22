#!/bin/bash

######################
#Copy files

ABC=/vagrant/httpd_data
cp $ABC/httpd@.service /etc/systemd/system/
cp $ABC/httpd-first /etc/sysconfig/
cp $ABC/httpd-second /etc/sysconfig/
cp $ABC/first.conf /etc/httpd/conf/
cp $ABC/second.conf /etc/httpd/conf/

#####################
#Start two services 

sudo systemctl daemon-reload
sudo systemctl start httpd@first
sudo systemctl start httpd@second
