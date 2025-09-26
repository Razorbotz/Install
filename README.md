To install WSL, run the following command in a Command Prompt or Powershell:

```
wsl --install Ubuntu-20.04
```

After the installation finishes, create a username and password. Start WSL and run the next commands in the virtual machine.

To install the libraries needed, run the following commands:

```
git clone https://github.com/Razorbotz/Install.git
```

Navigate to the folder that was just downloaded and run the following commands to install ROS2 Galactic, Gazebo, and download the C++ and ROS2 code for the project:

```
chmod +x setup_wsl.sh
```

```
./setup_wsl.sh
```

After running the install script, remove the Install folder with the following command:
```
cd ..;rm -rf ./Install
```