# Préparation du TurtleBot3 Burger

Matériel : TurtleBot3 Burger, Raspberry Pi 4 Model B, carte OpenCR, lidar LDS-02 (puce LD08), batterie LiPo 11,1 V 1800 mAh.
Mesuré sur le robot : Ubuntu 20.04.4 (aarch64), Python 3.8.10, ROS 1 Noetic.

## 1. Carte SD
- Image : « Raspberry Pi 4B (2GB or 4GB) ROS Noetic image » du manuel ROBOTIS (SBC Setup, onglet Noetic).
- Raspberry Pi Imager 2.x : choisir « Use custom ». La page de personnalisation (Wi-Fi, utilisateur, SSH) n'est pas proposée pour une image personnalisée.
- Modifier seulement `network-config` et `user-data` sur la partition `system-boot` n'a pas suffi. Méthode qui a fonctionné : un script exécuté une fois par le Pi au démarrage, déclenché par `cmdline.txt` (voir `scripts/first_boot_setup.sh.example`) :
  1. Copier le script à la racine de `system-boot` sous le nom `diag.sh`, fins de ligne LF, en remplaçant les `CHANGE_ME`.
  2. Sauvegarder `cmdline.txt`, puis ajouter à la fin de l'unique ligne : ` systemd.run=/boot/firmware/diag.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target`
  3. Démarrer le Pi : il exécute le script, redémarre et rejoint le Wi-Fi.
  4. Une fois connecté : changer le mot de passe et supprimer `/boot/firmware/diag*`.
- Accès : point d'accès mobile Windows (réseau 192.168.137.x). L'IP du Pi est visible dans « Appareils connectés », puis `ssh ubuntu@IP`.

## 2. ROS
- Ne pas passer à Ubuntu 22.04 (do-release-upgrade) : Noetic ne fonctionne que sur 20.04.
- Dans ~/.bashrc : ROS_MASTER_URI=http://localhost:11311, ROS_HOSTNAME=localhost, TURTLEBOT3_MODEL=burger, LDS_MODEL=LDS-02.
- Lancer une seule instance : `roslaunch turtlebot3_bringup turtlebot3_robot.launch`. Deux lancements simultanés se coupent mutuellement (nœuds de même nom).
- Valeurs mesurées : /imu environ 148 Hz, /scan environ 8,9 Hz, firmware OpenCR v1.2.6 compatible Burger.
- Avec LDS_MODEL=LDS-01 (valeur par défaut de l'image), /scan ne publie rien : ce robot a un LDS-02.

## 3. Batterie et horloge
- Bips répétés observés avec une batterie à 10,94 V (probablement l'alarme de batterie faible).
- Charger la batterie hors du robot (chargeur LBC-010), sans surveillance interdite.
- Éteindre le Pi avec `sudo shutdown now` avant de couper l'alimentation.
- Le Pi n'a pas d'horloge interne : remettre l'heure après chaque redémarrage.
