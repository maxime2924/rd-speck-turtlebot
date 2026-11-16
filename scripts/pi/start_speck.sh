#!/bin/bash
source /opt/ros/noetic/setup.bash
source ~/catkin_ws/devel/setup.bash
export TURTLEBOT3_MODEL=burger
export LDS_MODEL=LDS-02
export ROS_MASTER_URI=http://localhost:11311
export ROS_HOSTNAME=localhost
trap 'kill $(jobs -p) 2>/dev/null' EXIT
roslaunch turtlebot3_bringup turtlebot3_robot.launch &
until rostopic list >/dev/null 2>&1; do sleep 1; done
sleep 5
python3 ~/speck_ros_node.py &
~/venv-speck/bin/python ~/speck_tracker2.py &
sleep 3
python3 ~/speck_follow.py
