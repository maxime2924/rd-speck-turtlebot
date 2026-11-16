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
