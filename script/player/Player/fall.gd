# fall_state.gd（下落状态）
extends State

func enter(_params: Dictionary = {}) -> void:
	if context:
		context.play_animation("Fall")
