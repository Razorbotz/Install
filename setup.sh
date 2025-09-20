#!/bin/bash

# Create folder directory of robot
mkdir SoftwareDevelopment/ROS2
cd SoftwareDevelopment/ROS2
git init
git remote add origin https://github.com/Razorbotz/ROS2
git pull origin master
cd ../..
chmod +x install.sh
./install.sh

# Install ROS2
locale

sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

locale  # verify settings

sudo apt install software-properties-common
sudo add-apt-repository universe

sudo apt update && sudo apt install curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update
sudo apt upgrade
sudo apt install ros-galactic-desktop

sudo apt install ros-dev-tools

echo "source /opt/ros/galactic/setup.bash" >> ~/.bashrc
sudo apt-get install gazebo11