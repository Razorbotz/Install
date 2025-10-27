#!/bin/bash

# Create folder directory of robot
mkdir SoftwareDevelopment
mkdir SoftwareDevelopment/ROS2
cd SoftwareDevelopment/ROS2
git init
git remote add origin https://github.com/Razorbotz/ROS2

# Fetch all remote branches
git fetch origin

# Create and check out master locally
git checkout -b master origin/master

# Create and check out testing locally
git checkout -b testing origin/testing

cd ..
mkdir C++
cd C++
git init
git remote add origin https://github.com/Razorbotz/CPP
git fetch origin
git checkout -b master origin/master
git checkout -b testing origin/testing
cd ../..

mv SoftwareDevelopment ../

sudo mv ./ctre /usr/local/include
sudo mv ./lib/x86_64/* /usr/local/lib/

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
echo "source ~/SoftwareDevelopment/C++/robotcontrollerclient/control_completion.sh" >> ~/.bashrc
echo "export GAZEBO_MODEL_PATH=/home/team/SoftwareDevelopment/ROS2/shovel/src/sim/models:$GAZEBO_MODEL_PATH" >> ~/.bashrc

sudo apt-get install gazebo11
sudo apt install ros-galactic-gazebo-plugins
sudo apt install ros-galactic-rtabmap-ros

sudo chmod +x install_gui_deps.sh
./install_gui_deps.sh