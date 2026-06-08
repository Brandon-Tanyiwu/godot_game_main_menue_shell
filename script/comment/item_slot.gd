# item_slot.gd (以 item_card 为框架的通用物品槽)
extends Control
class_name ItemSlot

# 点击槽位时向外发出的信号（用于购买、装备、移库等逻辑）
signal slot_clicked(item_data: ItemData)

# 保留你原有的场景节点映射


# 💡 建议在你的场景 Panel 下追加一个 Label 叫 AmountLabel，用来给背包/仓库模式显示物品数量
@onready var amount_label: Label = $VBoxContainer/PriceContainer/AmountLabel
@onready var border: ColorRect = $Border
@onready var icon: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var price_label: Label = $VBoxContainer/PriceContainer/PriceLabel
@onready var discount_price_label: Label = $VBoxContainer/PriceContainer/DiscountPriceLabel


var tooltip_scene = preload("res://scenes/comment/item_tooltip.tscn")
var tooltip: Node = null
var item_data: ItemData = null
var current_amount: int = 0

func _ready() -> void:
	# ❗ 关键：确保拦截鼠标事件，否则 _gui_input 和 hover 信号在 Grid 里可能失效
	mouse_filter = Control.MOUSE_FILTER_STOP 
	
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	
	# 默认初始化为空格子
	clear_slot()

## 核心融合方法：兼容 商店、背包、仓库
## is_shop_mode 为 true 时显示价格，为 false 时显示数量
func setup_slot(data: ItemData, amount: int = 1, discount_rate: float = 1.0, is_shop_mode: bool = false):
	if data == null:
		clear_slot()
		return
		
	item_data = data
	current_amount = amount
	
	# 1. 基础通用信息渲染
	icon.texture = data.icon
	icon.show()
	name_label.text = data.item_name
	name_label.show()
	border.color = get_rarity_color(data.rarity)
	border.show()
	
	# 2. 根据所处界面模式，动态分流 UI 展示
	if is_shop_mode:
		# 商店模式：显示原价和折后价，隐藏数量
		if amount_label: amount_label.hide()
		
		price_label.text = str(data.base_price)
		price_label.show()
		
		var final_price = int(data.base_price * discount_rate)
		discount_price_label.text = str(final_price)
		discount_price_label.show()
	else:
		# 背包/仓库模式：隐藏价格标签，展示物品堆叠数量
		price_label.hide()
		discount_price_label.hide()
		
		if amount_label:
			if amount > 1:
				amount_label.text = str(amount)
				amount_label.show()
			else:
				amount_label.hide()

## 清空槽位（对应 8x8 网格中“没有物品就留空”的需求）
func clear_slot():
	item_data = null
	current_amount = 0
	
	if icon: icon.hide()
	if name_label: name_label.hide()
	if price_label: price_label.hide()
	if discount_price_label: discount_price_label.hide()
	if amount_label: amount_label.hide()
	
	# 空格子时的边框表现：可以隐藏，或者给一个半透明的灰色作为格子的底绘
	if border:
		border.color = Color(0.1, 0.1, 0.1, 0.3) 
		border.show()

func get_rarity_color(rarity: int) -> Color:
	match rarity:
		0: return Color.GRAY
		1: return Color.GREEN
		2: return Color.BLUE
		3: return Color.PURPLE
		4: return Color.GOLD
		5: return Color.RED
	return Color.WHITE
#
## 悬浮窗显示（加入非空校验）
func _on_hover():
	# ❗ 核心改动：如果格子里没有物品，绝对不要弹窗
	if item_data == null:
		return
	TooltipManager.show_item_tooltip(item_data,get_global_mouse_position())
	
## 悬浮窗销毁
func _on_exit():
	TooltipManager.hide_item_tooltip()

## 鼠标点击监测：点击格子时通知上层管理器
func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if item_data != null:
				slot_clicked.emit(item_data)
