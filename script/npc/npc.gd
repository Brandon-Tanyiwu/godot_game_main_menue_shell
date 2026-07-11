class_name NPC
extends UnitBase
@export var animated_sprite_2d: AnimatedSprite2D
@export var animatecontroller: AnimateController
@onready var layer_state_machine: StateMachine = $LayerStateMachine
@export var collision_shape_2d: Area2D 
@onready var npc_name: Label = $Name
var current_bag_data:Array
var npc_id:int
var npcname:String
func _ready() -> void:
	SignalManager.npc_turn.connect(_on_thinking_timer_timeout)
	collision_shape_2d.input_event.connect(_on_player_body_click)
	if get_parent():
		game_map=get_parent()

func _on_thinking_timer_timeout():
	var action = think_next_action(self,game_map)
	if action["action"]=="Run":
		pending_path = action["path_data"]
		terrain_layer = pending_path["terrain_layer"]
		move_intent.x=1

func init_npc_entity(hex_coord:Vector2i,config:Dictionary,items:Array) ->void:
	self.current_hex=hex_coord
	self.current_hp = config["HP"]
	self.npc_name   = config["name"]
	self.npcname = config["name"]
		

func think_next_action(npc_context:CharacterBody2D,_game_map:Node2D)->Dictionary:
	if npc_context.current_resource<=0:
		return {"action":"Idle"}
	var walkable_tiles:Dictionary = _game_map.get_cell_neighbors(npc_context.current_hex,npc_context.radius,npc_context.current_resource)

	if not walkable_tiles.keys().is_empty:

		return {"action":"Idle"}
	
	var target_tile = walkable_tiles.keys().pick_random()
	print(target_tile)
	var path_data = _game_map._ligal_hex_cell(npc_context.current_hex,target_tile,npc_context)

	if path_data.is_empty() or path_data["path"].is_empty():
		return {"action":"Idle"}
	return {
		"action":"Run"
		,"path_data":path_data
	}
