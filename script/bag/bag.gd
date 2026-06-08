extends PanelContainer
@onready var inventory_system: InventorySystem = $InventorySystem/HBoxContainer/ScrollContainer/GridContainer

var bag_data = SaveManager.current_save.bag
var GRID_SIZE = 24

func _ready() -> void:
	load_bag()
	SignalManager.request_add_item.connect(inventory_system.insert_item)

func load_bag() -> void:
	# 1. 照常清空当前运行时的背包数据
	for i in range(GRID_SIZE):
		inventory_system.remove_item(i)
	

	for slot_key in bag_data:
		
		var index = int(slot_key)
		if index < 0 or index >= inventory_system.GRID_SIZE:
			continue
			
		var slot_data = bag_data[slot_key]
		
		# 确保格子里有物品 ID
		if slot_data == null or not slot_data.has("item_id"):
			continue
		var bag_item_id = slot_data["item_id"]
		if GameDataManager.items.has(bag_item_id):
			var base_item = GameDataManager.items[bag_item_id]
			
			# 如果是独立装备，克隆一份，防止数据污染
			var bag_item = base_item.duplicate() if base_item.get("unique_instance", false) else base_item
			
			var item_num = slot_data.get("item_num", 1)
			var item_extra = slot_data.get("extra", {}) 
			
			inventory_system.insert_item(index, bag_item, item_num, item_extra)
		

	## 🌟 聪明的自动添加物品函数（自动处理堆叠与溢出）
func add_item_auto(item: ItemData, amount: int = 1, extra: Dictionary = {}) -> int:
	var remaining_amount = amount
	var max_limit = item.max_stack # 假设你在 ItemData 里配置了 max_stack
	
	# === 阶段 1：先尝试寻找现有的、没装满的同类物品进行堆叠 ===
	for i in range(GRID_SIZE):
		var slot = bag_data[i]
		if slot != null and slot["item"].item_id == item.item_id:
			var current_amount = slot["amount"]
			
			# 如果这个格子还没满，就把手里的物品往里塞
			if current_amount < max_limit:
				var available_space = max_limit - current_amount
				var amount_to_add = min(remaining_amount, available_space)
				
				bag_data[i]["amount"] += amount_to_add
				remaining_amount -= amount_to_add
				
				# 数据变了，通知 UI 刷新这个格子
				inventory_system.insert_item(i,item, amount, extra)
				
				# 如果全塞进去了，大功告成，直接返回 0（代表没有溢出残余）
				if remaining_amount <= 0:
					return 0

	# === 阶段 2：如果还有剩下的（这就是你说的溢出物），开始找空格子 ===
	for i in range(GRID_SIZE):
		if bag_data[i] == null:
			# 看看剩下的数量是不是一次性能放得下一个新格子
			var amount_to_place = min(remaining_amount, max_limit)
			
			# 放入新格子
			bag_data[i] = {"item": item, "amount": amount_to_place, "extra": extra}
			remaining_amount -= amount_to_place
			
			# 数据变了，通知 UI 刷新这个格子
			inventory_system.insert_item(i,item, amount, extra)
			
			# 如果刚好塞完了，退出
			if remaining_amount <= 0:
				return 0
				
	# === 阶段 3：如果走到这一步 remaining_amount 还大于 0，说明背包全满了！ ===
	print("[背包警告] 背包已满！溢出了 %d 个 %s 无法放入！" % [remaining_amount, item.item_name])
	
	# 返回剩余没装下的数量，可以让外面的系统决定是不是要把物品“刷在玩家脚下的地面上”
	return remaining_amount
	
		


func _on_close_button_pressed() -> void:
	hide()
	SceneManager.change_scene("res://scenes/hub/HubScene.tscn")
