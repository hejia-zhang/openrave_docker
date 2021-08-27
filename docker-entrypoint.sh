#!/bin/bash

export USER=openrave_docker

# setup bashrc
echo "export USER=$USER" > "/home/$USER/.bashrc"
echo "export HOME=/home/$USER" >> "/home/$USER/.bashrc"
echo "source /opt/ros/kinetic/setup.bash" >> "/home/$USER/.bashrc"
# echo "source /home/$USER/ros_ws/devel/setup.bash" >> "/home/$USER/.bashrc"
# echo 'export PATH=$PATH:/home/$USER/dev_ws/pycharm/bin' >> "/home/$USER/.bashrc"
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64' >> "/home/$USER/.bashrc"

echo "Running the entrypoint script..."
# cd "/home/$USER/ros_ws"
# catkin build
echo "Entrypoint ended, logging into an interactive shell..."

git config --global user.name "Hejia Zhang"
git config --global user.email hjzh578@gmail.com

source "/home/$USER/.bashrc"
cd "/home/$USER"
/bin/bash "$@"
