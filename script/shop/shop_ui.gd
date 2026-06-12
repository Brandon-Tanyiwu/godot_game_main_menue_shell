extends Control

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/TitleLabel
@onready var gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/GoldLabel
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CloseButton

# 核心：通用的网格组件
@onready var inventory_system: InventorySystem = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/InventorySystem
var shop_data: ShopData

func _ready() -> void:
	hide()
	close_button.pressed.connect(close_shop)
	# 监听通用组件转发出来的商品点击信号
	inventory_system.item_clicked_ext.connect(_on_shop_item_clicked)

func setup(data: ShopData) -> void:
	shop_data = data
	title_label.text = data.shop_name
	load_shop_items()
	update_gold_display()

## 将商店数据上架到通用网格中
func load_shop_items() -> void:
	# 1. 先清空当前货架网格的所有格子
	for i in range(inventory_system.grid_size):
		inventory_system.remove_item(i)
		
	if not shop_data or not "items" in shop_data:
		return
		
	# 2. 获取当前的店主折扣
	var discount = shop_data.shopkeeper.discount_rate if "shopkeeper" in shop_data and shop_data.shopkeeper else 1.0
	
	# 3. 将商品依次塞入网格的前几个格子
	for i in range(shop_data.items.size()):
		var item = shop_data.items[i]
		# 调用通用组件的 insert_item，并将折扣作为额外数据传入
		inventory_system.insert_item(i, item, 1, {"discount": discount})

## 刷新金币显示
func update_gold_display() -> void:
	# 💡 注意：由于当前的 inventory_system 节点变成了“商店货架”，
	# 玩家真正的金币数据和背包数据通常存放在全局单例中（例如全局的 InventoryManager 或 PlayerData）
	# 这里请根据你项目里实际存放玩家金币的单例进行修改：
	gold_label.text = "金币: " + str(SaveManager.current_save.gold)


## 处理商品点击（购买逻辑）
func _on_shop_item_clicked(index:int,item_data: ItemData) -> void:
	if item_data == null:
		return
	if item_data.base_price<=SaveManager.current_save.gold:
		inventory_system.remove_item(index)
		SignalManager.request_add_item.emit("bag",item_data.item_id,1,item_data.extra)
		SaveManager.current_save.gold -=item_data.base_price
		update_gold_display()
	# 【执行购买】
	# 1. 检查玩家全局单例中的金币是否足够 (如 if PlayerData.gold < final_price)
	# 2. 检查玩家【真正的背包组件】是否已满
	# 3. 扣除玩家金币，并调用玩家背包的全局接口加入该 item_data
	# 4. 调用 update_gold_display() 刷新顶栏金币

func open_shop() -> void:
	show()
	update_gold_display()
	
func close_shop() -> void:
	hide()


func _on_refresh_test_pressed() -> void:
	ShopRefreshManager.force_refresh()
