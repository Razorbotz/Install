#!/bin/bash

mkdir -p ~/SoftwareDevelopment/ROS2
cd ~/SoftwareDevelopment/ROS2
git init
git remote add origin https://github.com/Razorbotz/ROS2

# Fetch all remote branches
git fetch origin

# Create and check out branches locally
git checkout -B master origin/master
git checkout -B testing origin/testing

cd ..
mkdir -p C++
cd C++
git init
git remote add origin https://github.com/Razorbotz/CPP
git fetch origin
git checkout -B master origin/master
git checkout -B testing origin/testing
cd ../..

mv SoftwareDevelopment ../

sudo mv ./ctre /usr/local/include || true
sudo mv ./lib/aarch64/* /usr/local/lib/ || true

locale
sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
locale  # verify settings

sudo apt install -y software-properties-common curl gnupg lsb-release
sudo add-apt-repository universe -y

sudo apt update && sudo apt install curl -y
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
sudo dpkg -i /tmp/ros2-apt-source.deb

sudo apt update
sudo apt upgrade -y

sudo apt install ros-humble-desktop ros-dev-tools

if ! grep -q "source /opt/ros/humble/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
fi
if ! grep -q "control_completion.sh" ~/.bashrc; then
    echo "source ~/SoftwareDevelopment/C++/robotcontrollerclient/control_completion.sh" >> ~/.bashrc
fi
if ! grep -q "GAZEBO_MODEL_PATH" ~/.bashrc; then
    echo "export GAZEBO_MODEL_PATH=\$HOME/SoftwareDevelopment/ROS2/shovel/src/sim/models:\$GAZEBO_MODEL_PATH" >> ~/.bashrc
fi

# Install Gazebo
sudo apt-get update
sudo apt-get install curl lsb-release gnupg

sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt-get update
sudo apt-get install ignition-fortress

sudo apt install -y ros-humble-gazebo-ros-pkgs ros-humble-gazebo-ros2-control
sudo apt install -y ros-humble-rtabmap-ros

sudo apt install ros-humble-ros-gz-plugins
sudo apt install ros-humble-ros-gz-sim
sudo apt install ros-humble-ros-gz-bridge
sudo apt install ros-humble-rtabmap-gz

sudo chmod +x install_gui_deps.sh
./install_gui_deps.sh
