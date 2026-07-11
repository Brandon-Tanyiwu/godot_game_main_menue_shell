# item_slot.gd (以 item_card 为框架的通用物品槽)
extends Control
class_name ItemSlot

# 点击槽位时向外发出的信号（用于购买、装备、移库等逻辑）
signal slot_clicked(index:int,item_data: ItemData)


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
var slot_index:int = -1
var item_id:int
var SlotGritType:String
var extra_data:Dictionary = {}
func _ready() -> void:
	# ❗ 关键：确保拦截鼠标事件，否则 _gui_input 和 hover 信号在 Grid 里可能失效
	mouse_filter = Control.MOUSE_FILTER_STOP 
	
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	
	# 默认初始化为空格子
	clear_slot()

## 核心融合方法：兼容 商店、背包、仓库
## is_shop_mode 为 true 时显示价格，为 false 时显示数量
func setup_slot(data: ItemData, amount: int = 1, is_shop_mode: bool = false,other_info:Dictionary={},GridType:String = "default"):
	if data == null:
		clear_slot()
		return	
	extra_data = other_info
	item_data = data
	current_amount = amount
	item_id = item_data.id
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
		var final_price:int
		if other_info.has("discount_rate"):
			final_price= data.price * other_info["discount_rate"]
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
				slot_clicked.emit(slot_index,item_data)

func _get_drag_data(at_position: Vector2) -> Variant:
	if item_data == null:
		return null
	
	var draw_preview = TextureRect.new()
	draw_preview.texture = icon.texture
	draw_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	draw_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	draw_preview.custom_minimum_size = icon.size
	draw_preview.modulate.a = 0.6
	
	set_drag_preview(draw_preview)
	
	TooltipManager.hide_item_tooltip()
	return {
		"from_type":SlotGritType
		,"from_index":slot_index
	}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if price_label.is_visible_in_tree():
		return false
	return data is Dictionary and data.has("from_type") and data.has("from_index")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var from_type = data["from_type"]
	var from_index = data["from_index"]
	ItemTransitionManager.move_or_swap_slots(from_type,from_index,SlotGritType,slot_index)
	SignalManager.refresh_inventory_ui.emit()
