# idle_state.gd（待机状态）
extends State
class_name IdleState
func enter(_params: Dictionary = {}) -> void:
	if context:
		context.animatecontroller.play("Idle")
