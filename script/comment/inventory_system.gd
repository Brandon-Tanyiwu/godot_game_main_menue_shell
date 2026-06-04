extends Control
class_name InventorySystem

@export var slot_scene:PackedScene

# 【新增】当格子被点击时，向外派发信号，方便 ShopUI 监听并触发购买
signal item_clicked_ext(item_data: ItemData)

const GRID_SIZE = 64 
var inventory_data:Array = []

func _ready() -> void:
	inventory_data.resize(GRID_SIZE)
	inventory_data.fill(null)
	_initialize_grid()
	
func _initialize_grid():
	for i in range(GRID_SIZE):
		var slot:ItemSlot = slot_scene.instantiate()
		add_child(slot)
		slot.slot_clicked.connect(_on_slot_clicked)

func update_slot_ui(index:int):
	var slot :ItemSlot = get_child(index)
	var data = inventory_data[index]
	
	if data != null:
		# 🛠️【修复】将 "Amount" 改为小写 "amount" 与写入时保持一致
		slot.setup_slot(data["item"], data["amount"])
		
		# 【新增】如果数据里包含商店专属的额外信息（如折扣），且 ItemSlot 编写了接收方法，则传过去
		if data.has("extra") and slot.has_method("set_shop_properties"):
			slot.set_shop_properties(data["extra"])
	else:
		slot.clear_slot()

# 【改造】允许接收一个可选的 extra 字典，用来存放商店特有的数据（如价格、折扣）
func insert_item(index: int, item:ItemData, amount:int = 1, extra: Dictionary = {}):
	if index < 0 or index >= GRID_SIZE:
		return
	inventory_data[index] = {"item": item, "amount": amount, "extra": extra}
	update_slot_ui(index)		

func remove_item(index:int):
	if index >= 0 and index < GRID_SIZE:
		inventory_data[index] = null
		update_slot_ui(index)

func _on_slot_clicked(item_data:ItemData):
	# 【新增】将点击事件及数据向外转发
	item_clicked_ext.emit(item_data)
