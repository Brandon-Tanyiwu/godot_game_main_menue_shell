extends Control

@onready var npc_name: Label = $VBoxContainer/NPCName
@onready var npc_desc: Label = $"VBoxContainer/NPC Desc"
@onready var animated_sprite_2d: AnimatedSprite2D = $VBoxContainer/AnimatedSprite2D
@onready var inventory_system: InventorySystem = $VBoxContainer/ScrollContainer/InventorySystem

const item_slot = preload("res://scenes/comment/item_slot.tscn")
var npc_data:Dictionary

func _ready() -> void:
	visible = false
	npc_data = GameDataManager.fish
	SignalManager.unit_selected.connect(_on_show_npc_tooltip)

func _on_show_npc_tooltip(npc_node:Node)->void:

	if npc_node.is_in_group("Player"):
		return
	#animated_sprite_2d.sprite_frames=load(npc_data.get(npc_id)["npc_frame"])
	var npc_id=npc_node["npc_id"]
	var npc_item = npc_node["current_bag_data"]
	npc_name.text = npc_node["npcname"]
	visible = true	
	print(npc_item)
	for child in inventory_system.get_children():
		child.queue_free()
	
	if npc_item.is_empty():
		return
	
	else:
		
		for item_id in npc_item:
			var current_slot_node = item_slot.instantiate()
			inventory_system.add_child(current_slot_node)
			if GameDataManager.items.has(item_id):
				var base_item = GameDataManager.get_item_data(item_id)
				var item_num = 1
				current_slot_node.setup_slot(base_item, item_num, false, base_item.extra)
				
	
