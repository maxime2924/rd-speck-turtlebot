#!/usr/bin/env python3
import json, socket
import rospy
from geometry_msgs.msg import PointStamped

rospy.init_node("speck_target")
pub = rospy.Publisher("/speck/target", PointStamped, queue_size=10)
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("127.0.0.1", 5005))
sock.settimeout(0.5)
while not rospy.is_shutdown():
    try:
        data, _ = sock.recvfrom(1024)
    except socket.timeout:
        continue
    d = json.loads(data)
    m = PointStamped()
    m.header.stamp = rospy.Time.now()
    m.header.frame_id = "speck"
    m.point.x = d["x"]
    m.point.y = d["y"]
    m.point.z = d["n"]  # z = nombre d'evenements (provisoire)
    pub.publish(m)
