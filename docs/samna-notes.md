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
