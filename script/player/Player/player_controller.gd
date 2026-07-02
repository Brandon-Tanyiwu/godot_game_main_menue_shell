extends CharacterBody2D
class_name player
@onready var animatecontroller: AnimateController = $Animatecontroller
@onready var input_handler: InputHandler = $InputHandler
@onready var layer_state_machine: StateMachine = $LayerStateMachine

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
var pending_path:Array
var terrain_layer:TileMapLayer
@export var attack:int = 1
func _ready() -> void:
	await get_tree().process_frame
	SignalManager.request_reveal_fog.emit(current_hex,vision_radius)
	SignalManager.hex_cell_clicked.connect(set_movement_path)

func set_movement_path(path_data:Dictionary,terrain_layer:TileMapLayer)->void:
	pending_path = path_data["path"]
	terrain_layer = terrain_layer
	move_intent.x = 1.0


func _get_player_info() ->void:
	var user_info = SaveManager.current_save.player_info	
	attack = SaveManager.current_save.attack
	current_resource = SaveManager.current_save.player_resource

func play_animation(anim_name:String) -> void:
	if animatecontroller:

		animatecontroller.play(anim_name)
		

func is_animation_stop() -> void:
	return animatecontroller.is_playing()

func stop_animation() -> void:
	if animatecontroller.is_playing():
		animatecontroller.stop()

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

func update_facing(facing:int)->void:
	animatecontroller.set_direction(facing)
