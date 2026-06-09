# InventoryManager.gd (Autoload 单例)
extends Node

# 📢 当任何数据发生改变时，发出此信号。UI 监听到这个信号后就会执行 load_bag() 或 load_warehouse()
signal inventory_changed(target_type: String)

# 定义容器的最大格子上限
const BAG_SIZE = 24
const WAREHOUSE_SIZE = 96

func _ready() -> void:
	SignalManager.request_add_item.connect(add_item)
# ==========================================
# 📥 核心操作 1：获取 / 自动放入物品 (Acquire)
# ==========================================
## 将指定物品放入目标容器 ("bag" 或 "warehouse")，返回未能装下的溢出数量
func add_item(target_type: String, item_id: int, amount: int = 1, extra: Dictionary = {}) -> int:
	var target_info = _get_target_info(target_type)
	if target_info.is_empty(): return amount
	
	var target_dict: Dictionary = target_info["dict"]
	var grid_size: int = target_info["size"]
	
	# 从配置大本营捞出基础数据获取堆叠上限
	if not GameDataManager.items.has(item_id):
		print("[物品警告] 找不到该物品的配置 ID:", item_id)
		return amount
	var max_limit = GameDataManager.items[item_id].get("max_stack", 99)
	
	var remaining_amount = amount

	# 阶段 1：同类物品尝试堆叠
	for i in range(grid_size):
		var slot_key = str(i)
		if target_dict.has(slot_key) and target_dict[slot_key] != null:
			var slot_data = target_dict[slot_key]
			if slot_data.get("item_id") == item_id:
				var current_num = slot_data.get("item_num", 0)
				if current_num < max_limit:
					var available_space = max_limit - current_num
					var amount_to_add = min(remaining_amount, available_space)
					
					target_dict[slot_key]["item_num"] = current_num + amount_to_add
					remaining_amount -= amount_to_add
					
					if remaining_amount <= 0:
						_finalize_change(target_type)
						return 0

	# 阶段 2：寻找空位放入
	for i in range(grid_size):
		var slot_key = str(i)
		if not target_dict.has(slot_key) or target_dict[slot_key] == null:
			var amount_to_place = min(remaining_amount, max_limit)
			
			target_dict[slot_key] = {
				"item_id": item_id,
				"item_num": amount_to_place,
				"extra": extra.duplicate() # 规避引用污染
			}
			remaining_amount -= amount_to_place
			
			if remaining_amount <= 0:
				_finalize_change(target_type)
				return 0
				
	_finalize_change(target_type)
	return remaining_amount


# ==========================================
# 📤 核心操作 2：扣除 / 丢弃物品 (Discard)
# ==========================================
## 扣除指定格子的物品。若 amount 为 -1 则代表不管有多少直接清空该格子
func remove_item(target_type: String, index: int, amount: int = -1) -> bool:
	var target_info = _get_target_info(target_type)
	if target_info.is_empty(): return false
	
	var target_dict: Dictionary = target_info["dict"]
	var slot_key = str(index)
	
	if not target_dict.has(slot_key) or target_dict[slot_key] == null:
		return false
		
	var slot_data = target_dict[slot_key]
	var current_num = slot_data.get("item_num", 0)
	
	if amount == -1 or current_num <= amount:
		# 直接斩草除根清空
		target_dict[slot_key] = null
	else:
		# 扣减数量
		target_dict[slot_key]["item_num"] = current_num - amount
		
	_finalize_change(target_type)
	return true


# ==========================================
# 🔄 核心操作 3：跨容器转移 (Transfer)
# ==========================================
## 将物品从源容器的某个位置，转移到目标容器中（例如 "bag" -> "warehouse"）
## amount 为 -1 时转移该格子的全部数量
func transfer_item(from_type: String, to_type: String, from_index: int, amount: int = -1) -> bool:
	var from_info = _get_target_info(from_type)
	if from_info.is_empty(): return false
	
	var from_dict: Dictionary = from_info["dict"]
	var from_key = str(from_index)
	
	if not from_dict.has(from_key) or from_dict[from_key] == null:
		return false
		
	var slot_data = from_dict[from_key]
	var item_id = slot_data["item_id"]
	var available_num = slot_data["item_num"]
	var extra = slot_data.get("extra", {})
	
	# 计算实际要转移的数量
	var total_to_move = available_num if amount == -1 else min(amount, available_num)
	
	# 试探性往目标容器里塞入
	var overflow = add_item(to_type, item_id, total_to_move, extra)
	var successfully_moved = total_to_move - overflow
	
	if successfully_moved > 0:
		# 目标进去了多少，源头就得扣掉多少（精准处理因目标容器突然爆满导致的截流）
		remove_item(from_type, from_index, successfully_moved)
		return true
		
	return false


# ==========================================
# 🔀 核心操作 4：通用的移动、交换与合并 (跨容器/同容器通用)
# ==========================================
## 支持从任意容器的任意格子，拖拽到另一个容器的任意格子
func move_or_swap_slots(from_type: String, from_index: int, to_type: String, to_index: int) -> void:
	# 如果自己拖给自己，直接无视
	if from_type == to_type and from_index == to_index: return
	
	var from_dict = _get_target_info(from_type)["dict"]
	var to_dict = _get_target_info(to_type)["dict"]
	
	var from_key = str(from_index)
	var to_key = str(to_index)
	
	# 如果源格子根本没东西，抓了个寂寞，直接返回
	var from_data = from_dict.get(from_key)
	if from_data == null: return
	
	var to_data = to_dict.get(to_key)
	
	# 情况 1：目标格子有相同物品 ➡️ 尝试合并堆叠
	if to_data != null and to_data["item_id"] == from_data["item_id"]:
		var max_limit = GameDataManager.items[from_data["item_id"]].get("max_stack", 99)
		var to_num = to_data["item_num"]
		var from_num = from_data["item_num"]
		
		if to_num < max_limit:
			var space = max_limit - to_num
			var to_add = min(from_num, space)
			
			to_dict[to_key]["item_num"] += to_add
			
			# 如果源格子扣完了就清空，没扣完就留着残余
			if from_num - to_add <= 0:
				from_dict[from_key] = null
			else:
				from_dict[from_key]["item_num"] = from_num - to_add
				
			# 数据变了，发出通知刷新 UI
			_finalize_change(from_type)
			if from_type != to_type: _finalize_change(to_type)
			return

	# 情况 2：目标格子是空的，或者装了不同的物品 ➡️ 直接数据肉身对调 (交换位置)
	from_dict[from_key] = to_data
	to_dict[to_key] = from_data
	
	# 数据变了，发出通知刷新 UI
	_finalize_change(from_type)
	if from_type != to_type: _finalize_change(to_type)

# ==========================================
# 🔒 内部辅助私有函数
# ==========================================
# 快速定位要操作的数据源
func _get_target_info(type: String) -> Dictionary:
	match type:
		"bag":
			return {"dict": SaveManager.current_save.bag, "size": BAG_SIZE}
		"warehouse":
			return {"dict": SaveManager.current_save.warehouse, "size": WAREHOUSE_SIZE}
	print("[背包架构错误] 未知的容器类型: ", type)
	return {}

# 统一善后：引发 UI 变更通知，或者在这里执行自动存档
func _finalize_change(type: String):
	inventory_changed.emit(type)
