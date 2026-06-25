# walk_state.gd（行走状态）
extends State
class_name Run
var speed: float = 300.0

func enter(_params: Dictionary = {}) -> void:
	
	if context:
		context.play_animation("Run")

func exit() -> void:
	if context:
		context.stop_animation()
