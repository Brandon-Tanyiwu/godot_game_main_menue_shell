
class_name MapManager
extends Node

@export var map_view:MapView
var generator := MapGenerator.new()

func _ready():

	var graph = generator.generate()

	map_view.render_map(graph)
