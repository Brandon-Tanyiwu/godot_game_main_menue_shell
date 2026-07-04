# ground_state.gd（父状态）
extends State
class_name GroundState
var _current_intent: String = ""

## 发起单格移动结束信号
signal cell_movement_done
func _ready() -> void:
	pass
func enter(_params: Dictionary = {}) -> void:
	pass
## 地面状态，管理移动和停止
func physics_update(delta: float) -> void:
	#动作游戏
		#var direction: float= context.get_input_direction().x
		#var new_intent:String = "Idle" if direction==0 else "Run"
		#if new_intent!=_current_intent:
			#_current_intent=new_intent
			#request_transition(_current_intent)
		#context.update_facing(direction)
		#context.velocity.x = direction * context.move_speed
		#context.move_and_slide()
	#策略游戏

	var direction : Vector2 = context.move_intent
	if direction.x>0:
		_current_intent="Run"
		#request_transition(_current_intent)
	else:
		_current_intent="Idle"
	request_transition(_current_intent)
