extends Control

@onready var inventory_system: InventorySystem = $VBoxContainer/InventorySystem
@onready var describe: Label = $VBoxContainer/Describe
@onready var claim_reward: Button = $VBoxContainer/ClaimReward


const item_slot = preload("res://scenes/comment/item_slot.tscn")
var npc_data:Dictionary
var current_item_list:Array = []
func _ready() -> void:
	visible = false
	SignalManager.unit_death.connect(_on_show_npc_tooltip)

func _on_show_npc_tooltip(npc_node:Node)->void:
	
	#animated_sprite_2d.sprite_frames=load(npc_data.get(npc_id)["npc_frame"])
	var npc_id=npc_node["npc_id"]
	var npc_name = npc_node.npcname
	describe.text = "恭喜你击败了"+npc_name+"获得了以下奖励"
	var npc_item = npc_node["current_bag_data"]
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
				print(item_id)
				var base_item = GameDataManager.get_item_data(item_id)
				var item_num = 1
				current_slot_node.setup_slot(base_item, item_num, false, base_item.extra)
				current_item_list.append(base_item)

		


func _on_close_pressed() -> void:
	visible=false


func _on_claim_reward_pressed() -> void:
	for item_node in inventory_system.get_children():
		if item_node is ItemSlot:
			SignalManager.request_add_item.emit("bag",item_node.item_data["id"],1,item_node.extra_data)
			item_node.queue_free()
	visible=false
