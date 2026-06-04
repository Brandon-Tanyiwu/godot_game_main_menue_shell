extends Control

@onready var name_label = $Panel/NameLabel
@onready var dialog_label=$Panel/DialogLabel
@onready var enter_button = $Panel/EnterShopButton

var keeper_data:ShopKeeperData

func _ready() -> void:
	hide()
	enter_button.pressed.connect(_on_enter_shop)
	print('enter dailog')

func setup(data:ShopKeeperData):
	keeper_data = data
	name_label.text = data.keeper_name
	dialog_label.text = data.greeting
	
func show_dialog():
	show()

func _on_enter_shop():
	hide()
	get_parent().get_node("ShopUi").open_shop()
