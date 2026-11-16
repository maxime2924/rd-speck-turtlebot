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
