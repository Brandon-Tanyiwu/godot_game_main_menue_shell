extends Control
class_name InventorySystem

@export var slot_scene:PackedScene

# 【新增】当格子被点击时，向外派发信号，方便 ShopUI 监听并触发购买
signal item_clicked_ext(index:int,item_data: ItemData)

var grid_size = 24
enum GridType {DEFAULT,SHOP,EQUIPMENT,WAREHOUSE,BAG}
@export var current_grid_type: GridType = GridType.DEFAULT
var inventory_data:Array = []
var slot_nodes:Array[ItemSlot] = []

func _ready() -> void:
	inventory_data.resize(grid_size)
	inventory_data.fill(null)
	_initialize_grid()
	
func _initialize_grid():
	for i in range(grid_size):
		var slot:ItemSlot = slot_scene.instantiate()
		add_child(slot)
		slot_nodes.append(slot)
		slot.slot_index = i
		slot.slot_clicked.connect(_on_slot_clicked)

func update_slot_ui(index:int):
	var slot :ItemSlot = slot_nodes[index]
	var data = inventory_data[index]
	
	if data != null:
		var is_shop = (current_grid_type == GridType.SHOP)
		var _extra_data = data.get("extra",{})
		slot.setup_slot(data["item"], data["amount"],is_shop,_extra_data)
		
	else:
		slot.clear_slot()

# 【改造】允许接收一个可选的 extra 字典，用来存放商店特有的数据（如价格、折扣）
func insert_item(index: int, item:ItemData, amount:int = 1, extra: Dictionary = {}):
	if index < 0 or index >= grid_size:
		return
	inventory_data[index] = {"item": item, "amount": amount, "extra": extra}
	update_slot_ui(index)		
# 背包数据管理脚本 (例如 InventoryManager.gd)


func remove_item(index:int):
	if index >= 0 and index < grid_size:
		inventory_data[index] = null
		update_slot_ui(index)

func _on_slot_clicked(index:int,item_data:ItemData):
	# 【新增】将点击事件及数据向外转发
	item_clicked_ext.emit(index,item_data)
