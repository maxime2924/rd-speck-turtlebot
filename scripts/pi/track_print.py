import time
from statistics import median
import samna

devices = samna.device.get_unopened_devices()
board = samna.device.open_device(devices[0])
graph = samna.graph.EventFilterGraph()
sink = samna.graph.sink_from(board.get_model_source_node())
config = samna.speck2f.configuration.SpeckConfiguration()
config.dvs_layer.raw_monitor_enable = True
board.get_model().apply_configuration(config)
graph.start()
t0 = time.time()
try:
    while time.time() - t0 < 10:
        time.sleep(0.05)
        ev = sink.get_events()
        if len(ev) >= 50:
            xs = [e.x for e in ev]
            ys = [e.y for e in ev]
            print(f"{time.time()-t0:5.2f}s  n={len(ev):5d}  x={median(xs):5.1f}  y={median(ys):5.1f}  ts={ev[-1].timestamp}")
finally:
    graph.stop()
