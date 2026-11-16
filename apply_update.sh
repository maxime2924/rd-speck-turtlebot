#!/bin/bash
# Mise à jour du dépôt rd-speck-turtlebot (séance du 16 novembre 2026).
# Usage : se placer à la racine du dépôt, puis :  bash apply_update.sh
set -e
mkdir -p scripts/pi/system journal docs

cat > scripts/pi/speck_tracker2.py <<'PYEOF'
import time, json, socket
from statistics import median
import samna

MIN_EVENTS = 30
PERIOD = 0.05
ALPHA = 0.5       # lissage : 1 = aucun, plus petit = plus lisse
MIRROR_X = False  # mettre True pour retourner l'image
POOL = 2

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
addr = ("127.0.0.1", 5005)
devices = samna.device.get_unopened_devices()
board = samna.device.open_device(devices[0])
graph = samna.graph.EventFilterGraph()
sink = samna.graph.sink_from(board.get_model_source_node())
config = samna.speck2f.configuration.SpeckConfiguration()
config.dvs_layer.monitor_enable = True
config.dvs_layer.mirror.x = MIRROR_X
config.dvs_layer.pooling.x = POOL
config.dvs_layer.pooling.y = POOL
board.get_model().apply_configuration(config)
graph.start()
sx = sy = None
try:
    while True:
        time.sleep(PERIOD)
        ev = sink.get_events()
        n = len(ev)
        if n >= MIN_EVENTS:
            x = median(e.x for e in ev) * POOL + POOL / 2
            y = median(e.y for e in ev) * POOL + POOL / 2
            sx = x if sx is None else ALPHA * x + (1 - ALPHA) * sx
            sy = y if sy is None else ALPHA * y + (1 - ALPHA) * sy
            msg = {"t": time.time(), "n": n, "x": sx, "y": sy}
            sock.sendto(json.dumps(msg).encode(), addr)
        else:
            sx = sy = None
except KeyboardInterrupt:
    pass
finally:
    graph.stop()
PYEOF

cat > scripts/pi/speck_follow.py <<'PYEOF'
#!/usr/bin/env python3
import rospy
from geometry_msgs.msg import PointStamped, Twist

SIGN = 1.0      # mettre -1.0 si le robot tourne du mauvais cote
K = 0.6         # gain
MAX_W = 0.4     # vitesse de rotation max (rad/s)
DEAD = 0.08     # zone morte autour du centre
MIN_N = 60      # nombre minimal d'evenements pour y croire
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
PYEOF

cat > scripts/pi/start_speck.sh <<'SHEOF'
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
SHEOF

cat > scripts/pi/explore.py <<'PYEOF'
# Exploration des reglages de la couche DVS de la Speck (samna).
# Usage : python explore.py [mirror] [roi] [pool]
import sys, time
from statistics import mean
import samna

args = sys.argv[1:]
mirror = "mirror" in args
roi = "roi" in args
pool = "pool" in args
devices = samna.device.get_unopened_devices()
board = samna.device.open_device(devices[0])
graph = samna.graph.EventFilterGraph()
sink = samna.graph.sink_from(board.get_model_source_node())
config = samna.speck2f.configuration.SpeckConfiguration()
config.dvs_layer.monitor_enable = True
config.dvs_layer.mirror.x = mirror
if roi:
    config.dvs_layer.origin.x = 32
    config.dvs_layer.origin.y = 32
    config.dvs_layer.cut.x = 95
    config.dvs_layer.cut.y = 95
if pool:
    config.dvs_layer.pooling.x = 2
    config.dvs_layer.pooling.y = 2
board.get_model().apply_configuration(config)
graph.start()
name = " ".join(args) or "mon"
print("\n>>> AGITE LA MAIN sur tout le champ, prepare-toi...")
time.sleep(2)
sink.get_events()
print(">>> MAINTENANT (3 s)")
time.sleep(3)
ev = sink.get_events()
graph.stop()
if not ev:
    print(name, "n=0")
else:
    xs = [e.x for e in ev]
    ys = [e.y for e in ev]
    print(f"{name:10s} n={len(ev):7d}  x de {min(xs)} a {max(xs)}  y de {min(ys)} a {max(ys)}")
PYEOF

cat > scripts/pi/system/99-speck.rules <<'RULEOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="337d", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="04b4", MODE="0666"
RULEOF

cat > scripts/pi/system/settime-web <<'SHEOF'
#!/bin/bash
for i in $(seq 1 30); do
  d=$(curl -sI --max-time 5 http://example.com | grep -i '^date:' | cut -d' ' -f2- | tr -d '\r')
  if [ -n "$d" ]; then date -u -s "$d" && exit 0; fi
  sleep 5
done
exit 1
SHEOF

cat > scripts/pi/system/settime-web.service <<'UNITEOF'
[Unit]
Description=Set clock from web Date header
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/settime-web

[Install]
WantedBy=multi-user.target
UNITEOF

cat > docs/setup-speck-pi.md <<'MDEOF'
# Speck sur le Raspberry Pi du TurtleBot (Ubuntu 20.04, ROS Noetic)

## Connexion
- Le PC partage son Wi-Fi (point d'acces mobile Windows). Le Pi s'y connecte tout seul.
- `ssh ubuntu@turtlebot-rd.mshome.net` (le hotspot Windows enregistre le nom sous `mshome.net`).
- Cle SSH : `ssh-keygen -t ed25519` sur le PC (PowerShell), puis envoi de la cle publique dans `~/.ssh/authorized_keys` du Pi.

## Python et samna
Le Python systeme (3.8) sert a ROS. samna demande au moins Python 3.9 :
```
sudo apt install -y python3.9 python3.9-venv python3.9-dev
python3.9 -m venv ~/venv-speck
~/venv-speck/bin/pip install --upgrade pip
~/venv-speck/bin/pip install samna
```
samna 0.48.6 existe pour aarch64 (Python 3.9).

## Droits USB sans sudo
Copier `scripts/pi/system/99-speck.rules` dans `/etc/udev/rules.d/`, puis :
```
sudo udevadm control --reload-rules && sudo udevadm trigger
```
Rebrancher la Speck (port USB 3 bleu du Pi).

## Heure du Pi
Pas d'horloge materielle, NTP et ping bloques par le partage de connexion, HTTP fonctionne.
`scripts/pi/system/settime-web` (a copier dans `/usr/local/bin/`, executable) et `settime-web.service` (a copier dans `/etc/systemd/system/`) reglent l'heure au demarrage :
```
sudo systemctl daemon-reload
sudo systemctl enable --now settime-web
```

## Lancer tout
`scripts/pi/start_speck.sh` (a copier dans le dossier personnel du Pi avec `speck_ros_node.py`, `speck_tracker2.py`, `speck_follow.py`). Robot soulevé. `Ctrl+C` arrete tout.

## Arret
`sudo poweroff`, attendre que la LED verte arrete de clignoter, puis couper l'interrupteur.
MDEOF

cat > docs/samna-notes.md <<'MDEOF'
# Notes samna (Speck2f dev kit), apprises par experiences

Config : `samna.speck2f.configuration.SpeckConfiguration()` contient `dvs_layer`, `dvs_filter`, `cnn_layers`, `readout`, `debug_config`, `factory_config`. `config.dvs_layer.to_json()` affiche les valeurs.

## Deux sorties d'evenements
- `raw_monitor_enable` : evenements bruts du capteur (type `DvsEvent`), avant la couche DVS.
- `monitor_enable` : sortie apres la couche DVS (type `Spike`), seule sortie sur laquelle agissent miroir, zone d'interet et regroupement.
- Les deux ont `x` et `y`. Leur champ `timestamp` vaut toujours 0 (a resoudre).

## Reglages testes (sur `monitor_enable`)
| Reglage | Effet observe |
|---|---|
| `dvs_layer.mirror.x = True` | x devient environ 127 - x |
| `origin` (32, 32), `cut` (95, 95) | zone de 64 x 64, coordonnees recalees (0 a 63) |
| `pooling` 2 x 2 | image 64 x 64, environ 3 fois moins d'evenements |
| `dvs_filter.enable = True` | aucun effet utile (bruit au repos : 200 a 300 evenements en 3 s) |

Resolution du capteur : 128 x 128. Lentille : 3,6 mm.

`explore.py` (dans `scripts/pi/`) reproduit ces mesures.
MDEOF

cat > journal/2026-11-16.md <<'MDEOF'
# Séance du 16 novembre 2026

## Fait
- Connexion au Pi par cle SSH et par nom (`turtlebot-rd.mshome.net`) : plus de mot de passe ni de recherche d'IP.
- Speck lue sur le Pi sans sudo (regle udev).
- Script de demarrage unique `start_speck.sh` (robot + pont ROS + suivi + rotation).
- Premier rosbag : 35 s, 5 465 messages (IMU, odometrie, lidar, position de la cible, commandes), 2,6 Mo.
- Exploration de samna : deux sorties d'evenements (brute / apres la couche DVS), miroir, zone d'interet, regroupement, filtre de bruit. Details dans `docs/samna-notes.md`.
- Suivi v2 (`speck_tracker2.py`) : sortie apres la couche DVS, regroupement 2 x 2, lissage.
- Observation : le robot tourne presque toujours du meme cote car le bras de l'operateur entre toujours par le meme bord du champ (x moyen 95 a 121 sur 128). Au repos, le plafond du labo ne produit presque pas d'evenements.

## Problemes
- Alarme de batterie faible pendant le test du suivi v2 : le robot est alimente par une batterie avec un chargeur branche en meme temps, ce qui ne suffit pas. Test interrompu, robot eteint proprement. Prochaine fois : alimentation directe 12 V sur l'OpenCR.
- Horodatages toujours a 0.

## À faire
- Photos de la Speck (a l'echelle) et du bord avant d'une plaque, pour modeliser le support 3D (4 vis : 2 au niveau du lidar, 2 au niveau de la batterie).
- Valider le suivi v2 : main centree, puis main sur un cote.
- Arret d'urgence par le lidar, premier deplacement reel lent.
- Chercher les horodatages.
MDEOF

echo "OK : fichiers ecrits. Verifie avec : git status"
