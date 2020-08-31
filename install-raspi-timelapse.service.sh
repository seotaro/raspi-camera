#!/bin/bash

cp raspi-timelapse.service /etc/systemd/system
systemctl enable raspi-timelapse.service
systemctl start raspi-timelapse.service

cp raspi-timelapse.timer /etc/systemd/system
systemctl enable raspi-timelapse.timer
systemctl start raspi-timelapse.timer
