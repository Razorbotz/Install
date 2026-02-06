#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# --- Directory Setup ---
echo "[INFO] Setting up directories..."
mkdir -p SoftwareDevelopment/ROS2
cd SoftwareDevelopment/ROS2

# Initialize ROS2 repo
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/Razorbotz/ROS2
fi
git fetch origin
# Reset to avoid conflicts if re-running
git checkout -B master origin/master
git checkout -B testing origin/testing

cd ../..

# Initialize C++ repo
mkdir -p SoftwareDevelopment/C++
cd SoftwareDevelopment/C++
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/Razorbotz/CPP
fi
git fetch origin
git checkout -B master origin/master
git checkout -B testing origin/testing
cd ../..

# Move headers/libs (Assuming these folders exist in the current dir)
if [ -d "./ctre" ]; then
    echo "[INFO] Moving CTRE headers..."
    sudo mv ./ctre /usr/local/include
fi

if [ -d "./lib/x86_64" ]; then
    echo "[INFO] Moving libraries..."
    sudo mv ./lib/x86_64/* /usr/local/lib/
fi

# --- Install ROS 2 Jazzy (Ubuntu 24.04) ---
echo "[INFO] Installing ROS 2 Jazzy..."

# Locale setup
sudo apt update && sudo apt install locales -y
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# Add ROS 2 GPG key and repo
sudo apt install -y software-properties-common curl
sudo add-apt-repository universe -y

sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update
sudo apt upgrade -y

# Install ROS 2 Desktop and Dev Tools
sudo apt install -y ros-jazzy-desktop ros-dev-tools

# --- Install Gazebo Harmonic (Modern) & Bridges ---
# Note: Gazebo 11 (Classic) is EOL. We use the modern "ros_gz" ecosystem.
echo "[INFO] Installing Gazebo Harmonic and ROS 2 bridges..."
sudo apt install -y ros-jazzy-ros-gz ros-jazzy-gz-ros2-control ros-jazzy-ros2-controllers ros-jazzy-ros2-control

# --- Environment Setup ---
echo "[INFO] Configuring .bashrc..."

if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
fi

# Update paths for custom scripts
if ! grep -q "control_completion.sh" ~/.bashrc; then
    echo "source ~/SoftwareDevelopment/C++/robotcontrollerclient/control_completion.sh" >> ~/.bashrc
fi

# Update Gazebo Model Path (Updated for modern GZ if needed, keeping legacy var just in case)
if ! grep -q "GZ_SIM_RESOURCE_PATH" ~/.bashrc; then
    echo "export GZ_SIM_RESOURCE_PATH=\$HOME/SoftwareDevelopment/ROS2/shovel/src/sim/models:\$GZ_SIM_RESOURCE_PATH" >> ~/.bashrc
fi

# --- Build Custom C++ Client ---
echo "[INFO] Building Robot Control Client..."
# Fixed Windows-style backslashes to Linux forward slashes
TARGET_DIR="SoftwareDevelopment/C++/robotcontrolclient"

if [ -d "$TARGET_DIR" ]; then
    cd "$TARGET_DIR"
    mkdir -p build
    cd build
    cmake ..
    make -j$(nproc)
else
    echo "[WARNING] Directory $TARGET_DIR not found. Skipping build."
fi

echo "[INFO] Installing Build Dependencies (OpenCV, GTK, FFmpeg, SDL2, WebKit)..."
sudo apt install -y \
    ros-jazzy-desktop \
    ros-dev-tools \
    build-essential \
    cmake \
    pkg-config \
    libopencv-dev \
    python3-opencv \
    libgtkmm-3.0-dev \
    libsdl2-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libcairo2-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libwebkit2gtk-4.1-dev

echo "============================================"
echo " Installation Complete for Ubuntu 24.04 "
echo " ROS Distro: Jazzy"
echo " Gazebo: Harmonic (via ros_gz)"
echo "============================================"

