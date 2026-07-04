class_name NPC
extends CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D
@export var animatecontroller: AnimateController
@onready var layer_state_machine: StateMachine = $LayerStateMachine
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var radius:int=10
@export var current_resource = 6
@export var ai_leve:int = 1
@export var game_map:Node2D
@export var move_sconds = 0.5
@export var vision_radius = 0
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
func _ready() -> void:
	SignalManager.npc_turn.connect(_on_thinking_timer_timeout)
	if get_parent():
		game_map=get_parent()

func _on_thinking_timer_timeout():
	var action = think_next_action(self,game_map)
	if action["action"]=="Run":
		pending_path = action["path_data"]
		terrain_layer = pending_path["terrain_layer"]
		move_intent.x=1
	

func think_next_action(npc_context:CharacterBody2D,game_map:Node2D)->Dictionary:
	if npc_context.current_resource<=0:
		return {"action":"Idle"}
	var walkable_tiles:Dictionary = game_map.get_cell_neighbors(npc_context.current_hex,npc_context.radius,npc_context.current_resource)

	if not walkable_tiles.keys().is_empty:

		return {"action":"Idle"}
	
	var target_tile = walkable_tiles.keys().pick_random()
	print(target_tile)
	var path_data = game_map._ligal_hex_cell(npc_context.current_hex,target_tile,npc_context)

	if path_data.is_empty() or path_data["path"].is_empty():
		return {"action":"Idle"}
	return {
		"action":"Run"
		,"path_data":path_data
	}
