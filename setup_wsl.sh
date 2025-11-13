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
sudo apt-get install curl lsb-release gnupg

sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt-get update

sudo chmod +x install_gui_deps.sh
./install_gui_deps.sh

echo "============================================"
echo " Building Gazebo 11 from source (Jammy/WSL) "
echo "============================================"

# --- Install dependencies ---
sudo apt update
sudo apt install -y \
  build-essential cmake pkg-config \
  python3 python3-dev python3-pip python3-numpy \
  libprotoc-dev protobuf-compiler \
  libqt5core5a libqt5gui5 libqt5opengl5 libqt5widgets5 qtbase5-dev \
  libogre-1.9-dev libbullet-dev \
  libboost-all-dev \
  libtinyxml-dev libtinyxml2-dev \
  libfreeimage-dev libprotoc-dev libprotobuf-dev protobuf-compiler \
  libcurl4-openssl-dev libtbb-dev libgts-dev libusb-1.0-0-dev \
  libxi-dev libxmu-dev libzip-dev libtar-dev \
  libeigen3-dev freeglut3-dev doxygen \
  git wget curl

# --- Remove conflicting sdformat versions ---
sudo apt remove -y 'libsdformat*' || true
sudo apt install -y libsdformat9 libsdformat9-dev

# --- Clone Gazebo 11 repo ---
cd ~
if [ -d "gazebo" ]; then
  echo "[INFO] Removing existing ~/gazebo folder..."
  rm -rf ~/gazebo
fi

git clone -b gazebo11 https://github.com/osrf/gazebo.git
cd gazebo

# --- Create build directory ---
mkdir build && cd build

# --- Configure with CMake ---
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_TESTS_COMPILATION:BOOL=False \
  -DENABLE_PROFILER:BOOL=False

# --- Build (use all cores) ---
echo "[INFO] Building Gazebo (this can take a while)..."
make -j$(nproc)

# --- Install system-wide ---
sudo make install

# --- Source setup and verify ---
if [ -f /usr/share/gazebo/setup.sh ]; then
  source /usr/share/gazebo/setup.sh
fi

if ! grep -q "source /usr/share/gazebo/setup.sh" ~/.bashrc; then
    echo "source /usr/share/gazebo/setup.sh" >> ~/.bashrc
fi

echo "============================================"
gazebo --version || echo "Gazebo not in PATH yet."
echo "============================================"
echo "Gazebo 11 build completed successfully!"
echo "You can now run: gazebo --verbose"
echo "============================================"


mkdir -p ~/rtabmap_ws/src
cd ~/rtabmap_ws/src

git clone https://github.com/introlab/rtabmap.git
git clone --branch ros2 https://github.com/introlab/rtabmap_ros.git

cd ~/rtabmap_ws
rosdep update
rosdep install --from-paths src --ignore-src -r -y

echo "source ~/rtabmap_ws/install/setup.bash" >> ~/.bashrc

echo "Building rtabmap sequentially to limit memory issues. This will take a while."
MAKEFLAGS="-j1" colcon build --symlink-install \
  --cmake-args -DCMAKE_BUILD_TYPE=Release -DWITH_ZED=OFF
