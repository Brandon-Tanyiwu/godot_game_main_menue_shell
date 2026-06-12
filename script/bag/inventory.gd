extends PanelContainer


@onready var inventory_system: InventorySystem = $VBoxContainer/ScrollContainer/InventorySystem

var slot_nodes: Array[ItemSlot] = []
var GRID_SIZE = 128
var gridtype = "warehouse"

func _ready() -> void:
	for child in inventory_system.get_children():
		if child is ItemSlot:
			slot_nodes.append(child)

	while slot_nodes.size() < GRID_SIZE:
		var new_slot = preload("res://scenes/comment/item_slot.tscn").instantiate()
		inventory_system.add_child(new_slot)
		slot_nodes.append(new_slot)

	for i in range(GRID_SIZE):
		slot_nodes[i].slot_index = i
		slot_nodes[i].SlotGritType = gridtype

	load_inventory()
	SignalManager.refresh_inventory_ui.connect(load_inventory)

func load_inventory() -> void:
	var warehouse_data = SaveManager.current_save.warehouse

	for i in range(GRID_SIZE):
		var current_slot_node = slot_nodes[i]
		var slot_key = str(i)

		if warehouse_data.has(slot_key) and warehouse_data[slot_key] != null:
			var slot_data = warehouse_data[slot_key]
			var item_id = slot_data["item_id"]

			if GameDataManager.items.has(item_id):
				var base_item = GameDataManager.get_item_data(item_id)
				var item_num = slot_data.get("item_num", 1)
				current_slot_node.setup_slot(base_item, item_num, false, base_item.extra)
		else:
			current_slot_node.clear_slot()

func _on_close_button_pressed() -> void:
	queue_free()
