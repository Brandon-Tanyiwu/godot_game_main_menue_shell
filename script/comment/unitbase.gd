class_name UnitBase
extends CharacterBody2D

@export var radius:int=10
@export var current_resource = 6
@export var ai_leve:int = 1
@export var game_map:Node2D
@export var move_sconds = 0.5
@export var vision_radius = 0
var hurt_cooldown = true
var intent_priority: Dictionary = {
	"Death":1001,
	"Hurt":1000,
	"Attack1":999,
	"Attack2":998,
	"Run":2,
	"Idle":1,
}
@export var move_intent:Vector2=Vector2(0,0)
var pending_path
var terrain_layer:TileMapLayer
var current_hex:Vector2i
var current_hurt = 0
var total_hp = 50
var current_hp = 50
func _on_player_body_click(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		SignalManager.unit_selected.emit(self)
		#viewport.set_input_handle()
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		SignalManager.unit_deselected.emit()

			
