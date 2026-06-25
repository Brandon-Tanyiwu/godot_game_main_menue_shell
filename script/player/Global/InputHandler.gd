# InputHandler.gd
extends Node
class_name InputHandler

# ----------------------------
# ---- 缓存输入状态 ----
# ----------------------------
var input_direction: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var attack_pressed: bool = false

var attack_list = ["attack1","attack2","attack3"]

# ----------------------------
# ---- 每帧更新输入 ----
# ----------------------------
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	_collect_input()


# ----------------------------
# ---- 内部收集函数 ----
# ----------------------------
func _collect_input() -> void:
	# 水平移动输入
	input_direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_direction.y = 0

	# 跳跃输入
	jump_pressed = Input.is_action_just_pressed("ui_accept")

	# 攻击输入
	attack_pressed = (Input.is_action_just_pressed("attack3")
	or Input.is_action_just_pressed("attack2")
	or Input.is_action_just_pressed("attack1"))

# ----------------------------
# ---- 对外接口 ----
# ----------------------------
func get_direction() -> Vector2:
	return input_direction

func is_jump_pressed() -> bool:
	return jump_pressed

func is_attack_pressed() -> bool:
	return attack_pressed

func is_attack1_pressed() ->bool:
	return Input.is_action_just_pressed("attack1")

func is_attack2_pressed() ->bool:
	return Input.is_action_just_pressed("attack2")
