extends UnitBase
class_name player
@export var animatecontroller: AnimateController 
@export var input_handler: InputHandler 
@export var layer_state_machine: StateMachine 
@export var collision_shape_2d: Area2D 


@export var air_move_speed = 100
@export var jump_force = 400
@export var move_speed = 150
@export var gravity = -400
@export var double_jump_gravity = -400
@export var double_jump_force = 150
@export var max_fall_speed = 500
var player_intent = "Idle"
func _ready() -> void:
	await get_tree().process_frame
	SignalManager.request_reveal_fog.emit(current_hex,vision_radius)
	collision_shape_2d.input_event.connect(_on_player_body_click)

func set_movement_path(path_data:Dictionary,tilemaplayer:TileMapLayer)->void:
	pending_path = path_data
	terrain_layer = tilemaplayer
	move_intent.x = 1.0


func _get_player_info() ->void:
	var user_info = SaveManager.current_save.player_info	
	attack = SaveManager.current_save.attack
	current_resource = SaveManager.current_save.player_resource

func is_jump_pressed() ->bool:
	return input_handler.is_jump_pressed()

func is_attack_pressed() -> bool:
	return input_handler.is_attack_pressed()

func is_attack1_pressed() -> bool:
	return input_handler.is_attack1_pressed()
	
func is_attack2_pressed() -> bool:
	return input_handler.is_attack2_pressed()	

func get_input_direction() -> Vector2:
	return input_handler.input_direction
