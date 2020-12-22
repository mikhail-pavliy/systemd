#!/bin/bash

######################
#Copy files

SRC=/vagrant/httpd_data
cp $SRC/httpd@.service /etc/systemd/system/
cp $SRC/httpd-first /etc/sysconfig/
cp $SRC/httpd-second /etc/sysconfig/
cp $SRC/first.conf /etc/httpd/conf/
cp $SRC/second.conf /etc/httpd/conf/

#####################
#Start two services 

sudo systemctl daemon-reload
sudo systemctl start httpd@first
sudo systemctl start httpd@second
