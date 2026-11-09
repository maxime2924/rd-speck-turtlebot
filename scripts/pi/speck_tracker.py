import time, json, socket
from statistics import median
import samna

MIN_EVENTS = 50
PERIOD = 0.05

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
addr = ("127.0.0.1", 5005)

devices = samna.device.get_unopened_devices()
board = samna.device.open_device(devices[0])
graph = samna.graph.EventFilterGraph()
sink = samna.graph.sink_from(board.get_model_source_node())
config = samna.speck2f.configuration.SpeckConfiguration()
config.dvs_layer.raw_monitor_enable = True
board.get_model().apply_configuration(config)
graph.start()
try:
    while True:
        time.sleep(PERIOD)
        ev = sink.get_events()
        n = len(ev)
        if n >= MIN_EVENTS:
            msg = {"t": time.time(), "n": n,
                   "x": median(e.x for e in ev), "y": median(e.y for e in ev)}
            sock.sendto(json.dumps(msg).encode(), addr)
except KeyboardInterrupt:
    pass
finally:
    graph.stop()
