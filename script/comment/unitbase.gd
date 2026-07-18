class_name UnitBase
extends CharacterBody2D

@export var radius:int=10 
@export var current_resource = 6
@export var ai_leve:int = 1
@export var game_map:Node2D
@export var move_sconds = 0.5
@export var vision_radius = 0
@export var npc_name:String
@export var move_intent:Vector2=Vector2(0,0)
var pending_path
var terrain_layer:TileMapLayer
var current_hex:Vector2i
var current_hurt = 0
var total_hp = 50
var current_hp = 50
var attack = 10
var hurt_cooldown = true
var dailog:String = ""
var reward:Dictionary
var requirement:String
var final_target_coord:Vector2i
var id:int
var npcname:String
var current_bag_data

var intent_priority: Dictionary = {
	"Death":1001,
	"Hurt":1000,
	"Attack1":999,
	"Attack2":998,
	"Run":2,
	"Idle":1,
}

func _on_player_body_click(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		SignalManager.unit_selected.emit(self)
		#viewport.set_input_handle()
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		SignalManager.unit_deselected.emit()

func init_npc_entity(hex_coord:Vector2i,config:Dictionary,items:Array,Game:Node) ->void:
	self.game_map = Game
	self.current_hex=hex_coord
	self.current_hp = config["hp"]
	self.total_hp = config["hp"]
	self.npc_name   = config["name"]
	self.npcname = config["name"]
	self.current_resource = config["vp"]
	self.current_bag_data = items
	self.dailog = config["dialog"]
	#self.reward = config["reward"]
	self.requirement = config["requirement"]
	self.add_to_group(config["group"])
