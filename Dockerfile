FROM nvidia/cuda:11.6.2-devel-ubuntu18.04
# https://hub.docker.com/r/nvidia/cudagl/

ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

RUN apt update &&  \
    DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends  \
    wget curl unzip git make cmake gcc clang gdb libeigen3-dev libncurses5-dev libncursesw5-dev libfreeimage-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libgtk-3-dev pkg-config \
    libcanberra-gtk-module libcanberra-gtk3-module lsb python3-pip vim && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root

RUN echo 'if [ "$color_prompt" = yes ]; then' >> ~/.bashrc && \
    echo '    PS1='\''${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '\''' >> ~/.bashrc && \
    echo 'else' >> ~/.bashrc && \
    echo '    PS1='\''${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '\''' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc

# --------------------------------------------------------------- #
# Install ROS
# https://wiki.ros.org/melodic/Installation/Ubuntu
# --------------------------------------------------------------- #
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    apt update

RUN DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends ros-melodic-desktop-full

RUN echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc

RUN . /opt/ros/melodic/setup.sh && \
    DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends \
    python-rosdep python-rosinstall python-rosinstall-generator python-wstool build-essential

RUN . /opt/ros/melodic/setup.sh && \
    rosdep init && \
    rosdep update

# --------------------------------------------------------------- #
# Install dVRK-ROS
# https://github.com/jhu-dvrk/sawIntuitiveResearchKit/wiki/FirstSteps
# --------------------------------------------------------------- #
RUN apt update &&  \
    DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends  \
    libxml2-dev libraw1394-dev libncurses5-dev qtcreator swig sox espeak cmake-curses-gui cmake-qt-gui git \
    subversion gfortran libcppunit-dev libqt5xmlpatterns5-dev  libbluetooth-dev python-wstool python-catkin-tools \
    flite libopencv-dev qt5-default fluid


RUN . /opt/ros/melodic/setup.sh && \
    mkdir ~/catkin_ws           && \       
    cd ~/catkin_ws              && \       
    wstool init src             && \       
    catkin init                 && \       
    catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release && \ 
    cd src                      && \       
    wstool merge https://raw.githubusercontent.com/jhu-dvrk/dvrk-ros/master/dvrk_ros.rosinstall && \ 
    wstool up                   && \       
    catkin build --summary     

RUN echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc && \
    echo "source ~/catkin_ws/devel/cisstvars.sh" >> ~/.bashrc

RUN . /opt/ros/melodic/setup.sh && \
    . ~/catkin_ws/devel/setup.sh && \
    . ~/catkin_ws/devel/cisstvars.sh && \
    cd ~/catkin_ws/src && \
    catkin build --summary

RUN apt update &&  \
    DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends  \
    lshw udev

RUN mkdir -p /etc/udev/rules.d  &&  \
    echo 'KERNEL=="fw*", GROUP="fpgaqla", MODE="0666"' > ~/80-firewire-all.rules &&  \
    mv ~/80-firewire-all.rules /etc/udev/rules.d/80-firewire-all.rules  &&  \
    addgroup fpgaqla  

# RUN udevadm control --reload-rules
    