class_name MapGraph
extends Resource

var nodes:Dictionary = {}

func get_node(node_id:int) -> MapNodeData:
	return nodes.get(node_id)
