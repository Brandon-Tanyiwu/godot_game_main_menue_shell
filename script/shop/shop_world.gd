extends Node2D

@onready var background = $BackGround
@onready var wall = $Wall
@onready var shopkeeper_sprite = $ShopKeeper
@onready var npc_dialog: Control = $CanvasLayer/NpcDialog
@onready var shop_ui: Control = $CanvasLayer/ShopUi


@export var shop_data :ShopData

func _ready() -> void:
	ShopRefreshManager.shop_refreshed.connect(load_shop)
	load_shop(ShopRefreshManager.current_shop_data)
	npc_dialog.hide()
	shop_ui.hide()

func load_shop(shop_data: ShopData):
	if not shop_data: return
	
	var keeper = shop_data.shopkeeper
	background.texture = keeper.background
	shopkeeper_sprite.texture = keeper.portrait
	
	npc_dialog.setup(keeper)
	shop_ui.setup(shop_data) # 你的 UI 内部循环读取 shop_data.items 来创建商品格子
	


func _on_close_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/hub/HubScene.tscn")



func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("mouse_left"):
		print("click-keeper")
			# 安全检查：只有当商店界面和对话框都没打开时，点击 NPC 才有效
		if not npc_dialog.visible and not shop_ui.visible:
			print("点击了 NPC，展示对话框")
			npc_dialog.show()
