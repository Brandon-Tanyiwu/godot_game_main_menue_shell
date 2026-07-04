extends CharacterBody2D
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
@export var current_resource = 100
var intent_priority: Dictionary = {
	"Death":1001,
	"Hurt":1000,
	"Attack1":999,
	"Attack2":998,
	"Run":2,
	"Idle":1,
}

var current_hex:Vector2i = Vector2i.ZERO
@export var vision_radius = 1
@export var move_sconds= 1.0
var player_intent = "Idle"
var move_intent = Vector2(0,0) 
var pending_path:Dictionary
var terrain_layer:TileMapLayer
@export var attack:int = 1
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


func _on_player_body_click(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		print(self," 被点击")
		SignalManager.unit_selected.emit(self)
		#viewport.set_input_handle()
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		SignalManager.unit_deselected.emit()
