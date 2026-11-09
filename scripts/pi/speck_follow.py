#!/usr/bin/env python3
import rospy
from geometry_msgs.msg import PointStamped, Twist

SIGN = 1.0      # mettre -1.0 si le robot tourne du mauvais cote
K = 0.6         # gain
MAX_W = 0.4     # vitesse de rotation max (rad/s)
DEAD = 0.08     # zone morte autour du centre
MIN_N = 200     # nombre minimal d'evenements pour y croire
TIMEOUT = 0.3   # s sans cible -> arret

rospy.init_node("speck_follow")
pub = rospy.Publisher("/cmd_vel", Twist, queue_size=1)
last = None

def cb(m):
    global last
    last = (rospy.Time.now(), m.point.x, m.point.z)

rospy.Subscriber("/speck/target", PointStamped, cb, queue_size=1)
rospy.on_shutdown(lambda: pub.publish(Twist()))
rate = rospy.Rate(20)
while not rospy.is_shutdown():
    t = Twist()
    if last and (rospy.Time.now() - last[0]).to_sec() < TIMEOUT and last[2] >= MIN_N:
        e = (last[1] - 64.0) / 64.0
        if abs(e) > DEAD:
            t.angular.z = max(-MAX_W, min(MAX_W, SIGN * K * e))
    pub.publish(t)
    rate.sleep()
