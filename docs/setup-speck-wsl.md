# Speck (Speck2fDevKit) sur Windows 11 + WSL2

Mesuré : Windows 11, WSL2 Ubuntu 24.04 (Python 3.12.3), usbipd-win 5.3.0, samna 0.48.6.
Le dev kit demande une liaison USB 3.x : `lsusb -t` doit la montrer sur le bus 5000M.

## Installation
1. Windows : installer usbipd-win.
2. Ubuntu : `sudo apt install -y usbutils python3-venv python3-pip`, puis `python3 -m venv ~/speck && source ~/speck/bin/activate && pip install samna`.

## À chaque session
1. Ouvrir Ubuntu et le laisser ouvert (usbipd en a besoin).
2. PowerShell administrateur : `usbipd list` (repérer Speck2fDevKit), `usbipd bind --busid X-Y` (une fois), puis `usbipd attach --wsl --busid X-Y --auto-attach`. L'identifiant X-Y change avec le port USB.
3. Ubuntu : `sudo chmod -R a+rw /dev/bus/usb`. Le script `install-synsense-rules` de samna 0.48.6 plante (TypeError), d'où ce contournement à refaire après chaque rebranchement.
4. Test : `python scripts/test_events.py`.
