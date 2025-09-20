#!/bin/bash

# =================================================================================
# C++ Project Dependency Installation Script for Ubuntu
# =================================================================================
# It will install:
# - Core build tools (build-essential, cmake, pkg-config)
# - OpenCV library
# - cURL library
# - GTKMM 3.0 (C++ interface for GTK 3)
# - WebKit2GTK (web content rendering engine for GTK)
# - SDL2 (multimedia library)
# =================================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Update the package list to get the latest version information.
echo "Updating package lists..."
sudo apt-get update

echo "Installing required development libraries and tools..."
sudo apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    libopencv-dev \
    libcurl4-openssl-dev \
    libgtkmm-3.0-dev \
    libwebkit2gtk-4.0-dev \
    libsdl2-dev

echo ""
echo "All dependencies have been successfully installed."
echo "You can now run CMake and build your project."