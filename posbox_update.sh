#!/usr/bin/env bash

sudo mount -o remount,rw /
sudo git --work-tree=/home/odoo/odoo/ --git-dir=/home/odoo/odoo/.git pull
sudo mount -o remount,ro /
(sleep 5 && sudo reboot) &
