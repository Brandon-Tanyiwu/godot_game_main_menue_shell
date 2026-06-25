
extends State
class_name CommonState
func _ready() -> void:
	pass


func physics_update(_delta: float) -> void:
	if context.is_attack1_pressed():
		request_transition("Attack1")
	if context.is_attack2_pressed():
		request_transition("Attack2")
