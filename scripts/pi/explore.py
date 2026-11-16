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
