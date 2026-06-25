# air_state.gd（空中父状态）
class_name airstate
extends State

func _ready() -> void:
	pass

func enter(_params: Dictionary = {}) -> void:
	pass

func physics_update(delta: float) -> void:
	# 空中姿态控制
	if context.is_jump_pressed():
		if context.is_on_floor() :
			request_transition("Jump")
		else:
			request_transition("DoubleJump")

	var direction : Vector2 = context.get_input_direction()
	context.velocity.x = direction.x * context.air_move_speed
	
	context.velocity.y += context.gravity*delta
	# 🔥 朝向方向给一个水平冲量（可选）
	
	context.velocity.y += context.gravity*delta
	context.velocity.x = direction.x * context.move_speed
	context.move_and_slide()
	if context.velocity.y>0:
		request_transition("Fall")
	# 检查落地
	if context.is_on_floor():
		request_transition("Idle")  # 意图：落地
	
func apply_gravity(delta: float) -> void:
	if not context.is_on_floor():
		context.velocity.y += context.gravity * delta
		context.velocity.y = min(context.velocity.y, context.max_fall_speed)

func jump(jump_power: float = context.jump_force) -> void:
	context.velocity.y = -jump_power
