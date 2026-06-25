extends State

var attack_index = 0

func enter(_params: Dictionary = {}):
	context.play_animation("Attack2")
		
func physics_update(_delta: float) -> void:
	if context.is_animation_stop():
		request_transition("Idle")
