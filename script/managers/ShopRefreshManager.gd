extends Node

signal shop_refreshed(new_shop_data:ShopData)

const SAVE_PATH = "res://shop_state.config"
const REFRESH_INTERVAL_SECONDS = 3600

var shop_list = {
	"武器商店":{
		"keeper_name":"翰墨"
		,"portrait":"res://resource/tileset/hanmer.png"
		,"background":"res://resource/background/orig.png"
		,"item_type_pool":["equipment","weapon"]
	}
	,"药剂商店":{
		"keeper_name":"莉莉"
		,"portrait":"res://resource/tileset/lili.png"
		,"background":"res://resource/background/orig.png"
		,"item_type_pool":["consumable"]
	}
	,"食物商店":{
		"keeper_name":"莉莉"
		,"portrait":"res://resource/tileset/cofu.png"
		,"background":"res://resource/background/orig.png"
		,"item_type_pool":["food"]
	}
}

var current_shop_data:ShopData
var last_refresh_timestamp:float=0.0

func _ready() -> void:
	randomize()
	
	if !_load_shop_state():
		print("first_load_shop")
		force_refresh()
	else:
		_check_time_and_refresh()
	var timer = Timer.new()
	timer.wait_time = 10
	timer.autostart = true	
	timer.timeout.connect(_check_time_and_refresh)
	add_child(timer)
	
func _check_time_and_refresh()-> void:
	var current_time = Time.get_unix_time_from_system()
	var time_passed = current_time - last_refresh_timestamp
	
	if time_passed >= REFRESH_INTERVAL_SECONDS:
		print("time out and fresh")
		force_refresh()
		

func force_refresh()-> void:		
	last_refresh_timestamp = Time.get_unix_time_from_system()
	
	var new_shop = ShopData.new()
	
	var shop_names = shop_list.keys()
	var chosen_name = shop_names[randi()%shop_names.size()]
	new_shop.shop_name = chosen_name
	
	var template = shop_list[chosen_name]
	var keeper = ShopKeeperData.new()
	keeper.keeper_name = template["keeper_name"]
	keeper.portrait = load(template["portrait"])
	keeper.background =load(template["background"])
	new_shop.shopkeeper=keeper
	
	new_shop.items = _generate_random_items(template["item_type_pool"])
	
	current_shop_data = new_shop
	_save_shop_state()
	
	shop_refreshed.emit(current_shop_data)
	print("refresh success,shop_name:"+chosen_name)
	

func _generate_random_items(types:Array) -> Array[ItemData]:
	var result_items:Array[ItemData] = []
	
	var valid_pool:Array[Dictionary] = []
	var total_weight:float = 0.0
	
	for item_id in GameDataManager.items:
		var raw_info = GameDataManager.items[item_id]
		var current_item_type = raw_info.get("item_type")
		
		if types.has(current_item_type):
			var item_entry = raw_info.duplicate()
			item_entry["item_id"] = item_id
			valid_pool.append(item_entry)
			total_weight += float(raw_info.get("rarity",10.0))
	if valid_pool.is_empty():
		push_warning("no match items")
		return result_items
	
	var target_count = randi_range(7,16)
	
	for n in range(target_count):
		var roll=randf()*total_weight
		var current_sum = 0.0
		
		for item_entry in valid_pool:
			current_sum += float(item_entry.get("rarity",10.0))
			if roll <= current_sum:
				var item_data = GameDataManager.get_item_data(item_entry['item_id'])
				if item_data:
					result_items.append(item_data)
				break
	return result_items


func _save_shop_state() -> void:
	var config = ConfigFile.new()
	config.set_value("shop","last_refresh",last_refresh_timestamp)
	config.set_value("shop","shop_name",current_shop_data.shop_name)
	
	config.set_value("shop","keeper_name",current_shop_data.shopkeeper.keeper_name)
	
	var item_ids : Array[int] = []
	for item in current_shop_data.items:
		item_ids.append(item.item_id)
	config.set_value("shop","current_items",item_ids)
	config.set_value("shop","keeper_portrait",current_shop_data.shopkeeper.portrait)
	config.set_value("shop","background",current_shop_data.shopkeeper.background)
	config.save(SAVE_PATH)
	
func _load_shop_state()->bool:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false # 没存档
		
	last_refresh_timestamp = config.get_value("Shop", "last_refresh", 0.0)
	
	var loaded_shop = ShopData.new()
	loaded_shop.shop_name = config.get_value("Shop", "shop_name", "")
	
	# 还原店员
	var t_name = loaded_shop.shop_name
	if t_name:
		var keeper = ShopKeeperData.new()
		keeper.name = config.get_value("Shop", "keeper_name", "")
		keeper.portrait = load(config.get_value("Shop", "keeper_portrait", ""))
		keeper.background = load(config.get_value("Shop", "background", ""))
		loaded_shop.shopkeeper = keeper
		
	# 还原商品
	var item_ids = config.get_value("Shop", "current_items", [])
	var restored_items: Array[ItemData] = []
	for id in item_ids:
		var item_data = GameDataManager.get_item_data(id)
		if item_data:
			restored_items.append(item_data)
	loaded_shop.items = restored_items
	
	current_shop_data = loaded_shop
	return true
