FROM nvidia/cuda:10.0-cudnn7-runtime-ubuntu16.04

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ARG ssh_prv_key
ARG ssh_pub_key

RUN apt-get update && \
    apt-get install -y \
        git \
        openssh-server \
        libmysqlclient-dev

# Authorize SSH Host
RUN mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    ssh-keyscan github.com > /root/.ssh/known_hosts

# Add the keys and set permissions
RUN echo "$ssh_prv_key" > /root/.ssh/id_rsa && \
    echo "$ssh_pub_key" > /root/.ssh/id_rsa.pub && \
    chmod 600 /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa.pub

ENV NVIDIA_REQUIRE_DRIVER "driver>=390"

MAINTAINER Hejia Zhang <hjzh578@gmail.com>

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV USER=openrave_docker HOME=/home/openrave_docker
ENV ROS_WS=$HOME/ros_ws
ENV DEV_WS=$HOME/dev_ws

RUN echo "The working directory is: $HOME"
RUN echo "The user is: $USER"

RUN rm /etc/apt/sources.list.d/cuda.list && rm /etc/apt/sources.list.d/nvidia-ml.list

RUN rm -rf /var/lib/apt/lists/*

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all

# will not do anything is the home folder exists
RUN mkdir -p $HOME

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        libxau6 libxau6:i386 \
        libxdmcp6 libxdmcp6:i386 \
        libxcb1 libxcb1:i386 \
        libxext6 libxext6:i386 \
        libx11-6 libx11-6:i386 && \
    rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# Set up libglvnd for OpenGL GUI support
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        make \
        automake \
        autoconf \
        libtool \
        pkg-config \
        python \
        python-numpy \
        libxext-dev \
        libx11-dev \
        x11proto-gl-dev && \
    rm -rf /var/lib/apt/lists/*
# RUN python -V
WORKDIR /opt/libglvnd
RUN git clone --branch=v1.0.0 https://github.com/NVIDIA/libglvnd.git . && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/x86_64-linux-gnu && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/x86_64-linux-gnu -type f -name 'lib*.la' -delete

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        gcc-multilib \
        libxext-dev:i386 \
        libx11-dev:i386 && \
    rm -rf /var/lib/apt/lists/*

# 32-bit libraries
RUN make distclean && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/i386-linux-gnu --host=i386-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32" && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/i386-linux-gnu -type f -name 'lib*.la' -delete

COPY misc/10_nvidia.json /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json

RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    echo '/usr/local/lib/i386-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig

ENV LD_LIBRARY_PATH /usr/local/lib/x86_64-linux-gnu:/usr/local/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# ROS using apt
RUN echo "Installing ROS Kinetic"
# setup sources list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    lsb-release && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list
# setup keys
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-kinetic-desktop-full && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN rosdep init && rosdep update
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-kinetic-catkin python-catkin-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    cmake g++ git ipython minizip python-dev python-h5py python-numpy python-scipy qt4-dev-tools \
    libassimp-dev libavcodec-dev libavformat-dev libavformat-dev libboost-all-dev libboost-date-time-dev libbullet-dev libfaac-dev libglew-dev libgsm1-dev liblapack-dev liblog4cxx-dev libmpfr-dev libode-dev libogg-dev libpcrecpp0v5 libpcre3-dev libqhull-dev libqt4-dev libsoqt-dev-common libsoqt4-dev libswscale-dev libswscale-dev libvorbis-dev libx264-dev libxml2-dev libxvidcore-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libcairo2-dev libjasper-dev libpoppler-glib-dev libsdl2-dev libtiff5-dev libxrandr-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# compile OpenSceneGraph
RUN ["/bin/bash", "-c", \
  "mkdir $DEV_WS && cd $DEV_WS && \
  git clone https://github.com/openscenegraph/OpenSceneGraph.git --branch OpenSceneGraph-3.4 && \
  cd $DEV_WS/OpenSceneGraph && \
  mkdir -p $DEV_WS/OpenSceneGraph/build && cd $DEV_WS/OpenSceneGraph/build && \
  cmake .. -DDESIRED_QT_VERSION=4 && \
  make -j `nproc` && \
  make install"]
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN pip install --upgrade --user sympy==0.7.1
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get remove -y \
    python-mpmath && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# # compile fcl
# RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
#     software-properties-common && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*
# RUN apt-add-repository ppa:imnmfotmal/libccd
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-kinetic-moveit ros-kinetic-moveit-kinematics && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# RUN ["/bin/bash", "-c", \
#   "cd $DEV_WS && \
#   git clone https://github.com/flexible-collision-library/fcl && \
#   cd $DEV_WS/fcl && \
#   git reset --hard 0.5.0 && \
#   mkdir -p $DEV_WS/fcl/build && cd $DEV_WS/fcl/build && \
#   cmake .. && \
#   make -j `nproc` && \
#   make install"]
# compile openrave
RUN ["/bin/bash", "-c", \
  "cd $DEV_WS && \
  git clone --branch latest_stable https://github.com/rdiankov/openrave.git && \
  cd $DEV_WS/openrave && \
  git reset --hard 9c79ea26 && \
  mkdir -p $DEV_WS/openrave/build && cd $DEV_WS/openrave/build && \
  cmake -DODE_USE_MULTITHREAD=ON -DOSG_DIR=/usr/local/lib64/ .. && \
  make -j `nproc` && \
  make install"]
# Setup catkin workspace
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python-wstool python-catkin-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p $ROS_WS
RUN ["/bin/bash", "-c", \
  "cd $ROS_WS && \
  wstool init $ROS_WS/src && \
  catkin init && \
  catkin config --extend /opt/ros/kinetic"]
# clone required code stack and build
COPY misc/openrave.rosinstall $ROS_WS
RUN ["/bin/bash", "-c", \
    "cd $ROS_WS/src && \
    wstool merge $ROS_WS/openrave.rosinstall && \
    wstool update && \
    cd $ROS_WS && \
    catkin build"]
# install some useful tools
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    vim terminator xinput gdb curl wget winff firefox ipython-notebook && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY misc/.vimrc $HOME/
RUN ["/bin/bash", "-c", \
     "mkdir -p $HOME/.vim/syntax && \
     cd $HOME/.vim/syntax && \
     wget https://raw.githubusercontent.com/hdima/python-syntax/master/syntax/python.vim"]
RUN git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
RUN vim +PluginInstall +qall
RUN pip install jedi
# setup pycharm
RUN ["/bin/bash", "-c", \
     "cd $DEV_WS && \
     wget https://download.jetbrains.com/python/pycharm-professional-2020.2.2.tar.gz && \
     tar xvf pycharm-professional-2020.2.2.tar.gz && \
     mv pycharm-2020.2.2 pycharm && \
     rm pycharm-professional-2020.2.2.tar.gz"]
# setup clion
RUN ["/bin/bash", "-c", \
    "cd $DEV_WS && \
    wget https://download.jetbrains.com/cpp/CLion-2020.3.tar.gz && \
    tar xvf CLion-2020.3.tar.gz && \
    mv clion-2020.3 clion && \
    rm CLion-2020.3.tar.gz"]
WORKDIR /root
COPY docker-entrypoint.sh /root
ENTRYPOINT ["/root/docker-entrypoint.sh"]
