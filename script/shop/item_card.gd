extends Control

@onready var border: ColorRect = $Panel/Border
@onready var icon: TextureRect = $Panel/Icon
@onready var name_label: Label = $Panel/NameLabel
@onready var price_label: Label = $Panel/PriceLabel
@onready var discount_price_label: Label = $Panel/DiscountPriceLabel


var tooltip_scene = preload("res://scenes/shop/item_tooltip.tscn")

var tooltip

var item_data:ItemData

func _ready() -> void:
	mouse_entered.connect( _on_hover)
	mouse_exited.connect(_on_exit)
	
func setup(data:ItemData,discount_rate:float):
	item_data = data
	icon.texture = data.icon
	name_label.text = data.item_name
	price_label.text = str(data.base_price)
	var final_price = int(data.base_price*discount_rate)
	discount_price_label.text = str(final_price)
	border.color = get_rarity_color(data.rarity)

func get_rarity_color(rarity):
	match rarity:
		0:
			return Color.GRAY
		1:
			return Color.GREEN
		2:
			return Color.BLUE
		3:
			return Color.PURPLE
		4:
			return Color.GOLD
		5:
			return Color.RED
	return Color.WHITE

func _on_hover():
	tooltip = tooltip_scene.instantiate()
	get_tree().current_scene.add_child(tooltip)
	tooltip.setup(item_data)
	tooltip.global_position = get_global_mouse_position()+ Vector2(20,20)

func _on_exit():
	if tooltip:
		tooltip.queue_free()
	


	
