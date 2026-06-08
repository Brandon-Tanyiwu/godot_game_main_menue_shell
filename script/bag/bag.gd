extends PanelContainer
@onready var inventory_system: InventorySystem = $InventorySystem/HBoxContainer/ScrollContainer/GridContainer

var bag_data = SaveManager.current_save.bag


func _ready() -> void:
	load_bag()
	SignalManager.request_add_item.connect(add_item_auto)

func load_bag() -> void:
	for i in range(inventory_system.GRID_SIZE):
		inventory_system.remove_item(i)
	
	for bag_item_id in bag_data.keys():
		var bag_item = GameDataManager.items[bag_item_id]
		var item_num = bag_data[bag_item_id]["item_num"]
		var item_index = bag_data[bag_item_id]["index"]
		inventory_system.insert_item(item_index,bag_item,item_num)
		

func add_item_auto(item:ItemData,item_num:int,extra:Dictionary):
	var remaining_amount = item_num
	var max_limit = item.max_stack
	
	for i in range()
	
	
		
