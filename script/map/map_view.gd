class_name MapView
extends Node2D

@export var node_container:Node
@export var connection_container:Node

var node_scene = preload("res://scenes/map/map_node.tscn")


var graph:MapGraph

func render_map(map_graph:MapGraph):

	graph = map_graph
	clear_old()
	draw_connections()
	draw_nodes()

func clear_old():
	for child in node_container.get_children():
		child.queue_free()
	for child in connection_container.get_children():
		child.queue_free()

func draw_nodes():
	for node_data in graph.nodes.values():
		var node = node_scene.instantiate()
		node.setup(node_data)
		node.node_clicked.connect(_on_node_clicked)
		node_container.add_child(node)

func draw_connections():

	for node_data in graph.nodes.values():
		for target_id in node_data.next_nodes:
			var target =graph.get_node(target_id)

			var line = Line2D.new()

			line.width = 4

			line.default_color = Color.GRAY

			line.add_point(node_data.position)
			line.add_point(target.position)

			connection_container.add_child(line)

func _on_node_clicked(node_id):

	print("点击节点:", node_id)

	complete_node(node_id)

func complete_node(node_id:int):

	var node = graph.get_node(node_id)

	node.visited = true
	node.unlocked = false

	for next_id in node.next_nodes:

		graph.get_node(next_id).unlocked = true

	refresh_nodes()

func refresh_nodes():

	for node in node_container.get_children():
		node.update_visual()
