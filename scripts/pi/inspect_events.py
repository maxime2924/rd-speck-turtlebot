import time, collections, samna

devices = samna.device.get_unopened_devices()
board = samna.device.open_device(devices[0])
graph = samna.graph.EventFilterGraph()
sink = samna.graph.sink_from(board.get_model_source_node())
config = samna.speck2f.configuration.SpeckConfiguration()
config.dvs_layer.raw_monitor_enable = True
board.get_model().apply_configuration(config)
graph.start()
time.sleep(2)
events = sink.get_events()
graph.stop()
print(collections.Counter(type(e).__name__ for e in events))
e = events[0]
print(type(e))
print([a for a in dir(e) if not a.startswith('_')])
