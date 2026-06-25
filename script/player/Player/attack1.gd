extends State

var attack_index = 0

func enter(_params: Dictionary = {}):
	context.play_animation("Attack1")
		
func physics_update(_delta: float) -> void:
	pass
