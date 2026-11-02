import time
import samna

devices = samna.device.get_unopened_devices()
print(devices)
board = samna.device.open_device(devices[0])

graph = samna.graph.EventFilterGraph()
sink = samna.graph.sink_from(board.get_model_source_node())

config = samna.speck2f.configuration.SpeckConfiguration()
config.dvs_layer.raw_monitor_enable = True
board.get_model().apply_configuration(config)

graph.start()
time.sleep(3)
events = sink.get_events()
print(f"{len(events)} événements reçus en 3 s")
graph.stop()
