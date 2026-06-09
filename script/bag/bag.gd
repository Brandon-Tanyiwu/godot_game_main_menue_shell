extends PanelContainer
@onready var inventory_system: InventorySystem = $InventorySystem/HBoxContainer/ScrollContainer/GridContainer

# 🌟【新增】在内存中提前引用好这 24 个格子的节点，再也不去销毁它们
var slot_nodes: Array[ItemSlot] = []
var GRID_SIZE = 24

func _ready() -> void:
	# 🎯 初始化：只在游戏刚启动/背包第一次载入时，获取这 24 个格子的引用
	for child in inventory_system.get_children():
		if child is ItemSlot:
			slot_nodes.append(child)
	
	# 如果编辑器里没拉够格子，代码自动补齐到 24 个（只生成这一次）
	while slot_nodes.size() < GRID_SIZE:
		var new_slot = preload("res://scenes/comment/item_slot.tscn").instantiate()
		inventory_system.add_child(new_slot)
		slot_nodes.append(new_slot)
		
	# 给这 24 个格子死死焊上固定的门牌号
	for i in range(GRID_SIZE):
		slot_nodes[i].slot_index = i

	# 首次渲染
	load_bag()

func load_bag() -> void:
	var bag_data = SaveManager.current_save.bag
	
	# 🎯 核心优化：高阶复用循环
	for i in range(GRID_SIZE):
		var current_slot_node = slot_nodes[i] # 拿到已经存在的第 i 个格子肉身
		var slot_key = str(i)
		
		# 看看存档数据里，这个门牌号有没有东西
		if bag_data.has(slot_key) and bag_data[slot_key] != null:
			var slot_data = bag_data[slot_key]
			var bag_item_id = slot_data["item_id"]
			
			if GameDataManager.items.has(bag_item_id):
				var base_item = GameDataManager.items[bag_item_id]
				var item_num = slot_data.get("item_num", 1)
				
				# 🌟 只刷新这个格子的内容，没有任何节点被销毁或新建！
				current_slot_node.setup_slot(base_item, item_num) 
		else:
			# 🌟 如果数据里这一格是空的，直接让格子“变秃”（清空图片和数字）
			current_slot_node.clear_slot()


func _on_close_button_pressed() -> void:
	hide()
	SceneManager.change_scene("res://scenes/hub/HubScene.tscn")
