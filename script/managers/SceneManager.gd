
extends Node
var current_scene

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func change_scene(path:String)-> void:
	call_deferred("_deferred_change_scene",path)


func _deferred_change_scene(path:String):
	
	if current_scene:
		current_scene.queue_free()
	
	var scene = load(path).instantiate()
	
	get_tree().root.add_child(scene)
	
	current_scene=scene
 
