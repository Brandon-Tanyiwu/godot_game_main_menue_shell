# jump_state.gd（跳跃状态）
extends State


func enter(_params: Dictionary = {}) -> void:
	context.velocity.y = -context.jump_force
	var direction : Vector2 = context.get_input_direction()
	context.velocity.x = direction.x * context.air_move_speed
	if context:
		context.play_animation("Jump")

func exit() -> void:
	if context:
		context.stop_animation()
