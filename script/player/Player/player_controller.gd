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
@export var move_sconds= 1
var player_intent = "Idle"
var move_intent = Vector2(0,0) 
var pending_path:Array
var terrain_layer:TileMapLayer

func _ready() -> void:
	await get_tree().process_frame
	SignalManager.request_reveal_fog.emit(current_hex,vision_radius)

func set_movement_path(path:Array,terrain_layer:TileMapLayer)->void:
	pending_path = path
	terrain_layer = terrain_layer
	move_intent.x = 1.0
	
func teleport_to_hex(coord:Vector2i,pixel_pos:Vector2i)->void:
	current_hex = coord
	global_position= pixel_pos

func move_along_path(path: Array, terrain_layer: TileMapLayer) -> void:
	if path.is_empty():
		return
	layer_state_machine._on_transition_request("Run")
	# 遍历路径中的每一个六边形网格坐标
	for next_hex in path:
		# 1. 先把网格坐标换算成地图图层的本地像素
		var local_pixel_pos = terrain_layer.map_to_local(next_hex)
		var target_global_pos = terrain_layer.to_global(local_pixel_pos)
		
		# 2. 🌟 转向逻辑：根据下一格在左边还是右边，自动翻转图片
		if target_global_pos.x > global_position.x:
			animatecontroller.set_direction(1)
		elif target_global_pos.x < global_position.x:
			animatecontroller.set_direction(0)
		
		# 3. 让角色移动到这个全局像素点
		# 如果你是瞬间移动，直接赋值 global_position：
		#global_position = target_global_pos
		# 💡 如果你使用的是 Tween 动画平滑移动，请确保使用的是 "global_position" 属性：
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_global_pos, 0.2)
		await tween.finished
		
		# 4. 🌟 实时更新当前网格坐标：每走完一格，就把 current_hex 刷新为当前所在的格子
		current_hex = next_hex
		SignalManager.request_reveal_fog.emit(current_hex,vision_radius)



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
