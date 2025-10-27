#!/bin/bash
set -e 

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

if [ -d "./ctre" ]; then
    sudo mv ./ctre /usr/local/include || true
fi

if [ -d "./lib/x86_64" ]; then
    sudo mv ./lib/x86_64/* /usr/local/lib/ || true
fi

sudo apt update && sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
locale  # verify settings

sudo apt install -y software-properties-common curl gnupg lsb-release
sudo add-apt-repository universe -y

sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
  -o /usr/share/keyrings/ros-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu \
$(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
| sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update
sudo apt upgrade -y

sudo apt install -y ros-humble-desktop ros-dev-tools

if ! grep -q "source /opt/ros/humble/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
fi
if ! grep -q "control_completion.sh" ~/.bashrc; then
    echo "source ~/SoftwareDevelopment/C++/robotcontrollerclient/control_completion.sh" >> ~/.bashrc
fi
if ! grep -q "GAZEBO_MODEL_PATH" ~/.bashrc; then
    echo "export GAZEBO_MODEL_PATH=\$HOME/SoftwareDevelopment/ROS2/shovel/src/sim/models:\$GAZEBO_MODEL_PATH" >> ~/.bashrc
fi

sudo apt install -y ros-humble-gazebo-ros-pkgs ros-humble-gazebo-ros2-control
sudo apt install -y ros-humble-rtabmap-ros

sudo apt install -y gz-garden || sudo apt install -y gz-fortress

sudo chmod +x install_gui_deps.sh
./install_gui_deps.sh
