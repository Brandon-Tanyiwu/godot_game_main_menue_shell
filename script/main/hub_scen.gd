extends Control

@onready var gold_label = $TopBar/GoldLabel
@onready var level_label  = $TopBar/LevelLabel
@onready var player_name = $TopBar/PlayerLabel
@onready var panel_container: HBoxContainer = $PanelContainer

var current_game:SaveData

func _ready() -> void:
	PlayerManager.load_from_save(SaveManager.current_save)
	refresh_ui()
	current_game = SaveManager.current_save

func refresh_ui():
	var data = SaveManager.current_save
	player_name.text = "角色名： "+data.player_name
	level_label.text = 'LV.' + str(data.level)
	
	gold_label.text  = "金币数: "+str(data.gold)
	


func _on_skill_tree_button_pressed() -> void:
	print("open_skill_tree")
	
func _on_inventory_button_pressed() -> void:
	print("open_inventory")
	var path_list = ["res://scenes/bag&inventory/bag.tscn","res://scenes/bag&inventory/inventory.tscn"]
	SceneManager._open_pannel(path_list,panel_container)

func _on_equipment_button_pressed() -> void:
	print("open_equipment") 


func _on_ware_house_button_pressed() -> void:
	print("open_warehouse")
	SceneManager.open_scene("res://scenes/bag&inventory/bag.tscn",panel_container)


func _on_back_button_pressed() -> void:
	print("back_main_menu")
	SceneManager.change_scene(
		"res://scenes/main_menu/main_menu.tscn")


func _on_save_button_pressed() -> void:
	print("save_game")
	SaveManager.save_game(current_game,"save_test.res")


func _on_shop_button_pressed() -> void:
	print("go shop")
	SceneManager.change_scene(
		"res://scenes/shop/shop_world.tscn"
		
	)


func _on_game_1_pressed() -> void:
	print("go map1")
	SceneManager.change_scene("res://scenes/map/gebulin_map.tscn")

func _on_game_2_pressed() -> void:
	print("go map2")
	SceneManager.change_scene("res://scenes/map/civilisation_map.tscn")


func _on_stage_button_pressed() -> void:
	print("open user info") ##pass # Replace with function body.
	SceneManager.open_scene("res://scenes/comment/player_tooltip.tscn",panel_container)


func _on_test_button_pressed() -> void:
	SaveManager.current_save.attack+=1
	print(SaveManager.current_save.attack)
	SignalManager.player_info_change.emit()
