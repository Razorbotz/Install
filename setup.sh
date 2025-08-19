#!/bin/bash

mkdir SoftwareDevelopment/ROS2
cd SoftwareDevelopment/ROS2
git init
git remote add origin https://github.com/Razorbotz/ROS2
git pull origin master
cd ../..
chmod +x install.sh
./install.sh