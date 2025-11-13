71  sudo apt install zstd
sudo mkdir -p /etc/apt/keyrings
curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null
sudo apt-get install apt-transport-https
echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/librealsense.list
sudo apt update
sudo rm /etc/apt/sources.list.d/archive_uri-https_librealsense_intel_com_debian_apt-repo-jammy.list
sudo apt update
sudo apt install librealsense2-dkms
sudo apt install librealsense2=2.55.1-0~realsense.12474
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE || sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE
sudo add-apt-repository "deb https://librealsense.intel.com/Debian/apt-repo $(lsb_release -cs) main" -u
sudo apt-get install librealsense2-utils
sudo apt-get install librealsense2-dev
realsense-viewer
sudo rm /etc/apt/sources.list.d/archive_uri-https_librealsense_intel_com_debian_apt-repo-jammy.list
sudo apt update
wget https://download.stereolabs.com/zedsdk/5.1/l4t36.4/jetsons
chmod +x jetsons 
./jetsons 