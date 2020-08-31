#!/bin/bash

systemctl stop raspi-timelapse.timer
systemctl disable raspi-timelapse.timer
rm /etc/systemd/system/raspi-timelapse.timer

systemctl stop raspi-timelapse.service
systemctl disable raspi-timelapse.service
rm /etc/systemd/system/raspi-timelapse.service

