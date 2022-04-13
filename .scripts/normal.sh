#!/bin/bash
bash -c "echo 1 > /sys/devices/platform/asus-nb-wmi/throttle_thermal_policy"
echo 1 |sudo tee /sys/bus/platform/devices/asus-nb-wmi/dgpu_disable


