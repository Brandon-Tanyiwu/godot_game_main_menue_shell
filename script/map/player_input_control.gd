class_name PlayerInputControls
extends Node2D

enum InputMode {NORMAL,SELECTED,USE_ITEM,USE_SKILL,MOVE}


@export var terrain_layer :TileMapLayer
@export var game_map:Node2D
var current_mode:InputMode = InputMode.NORMAL
var current_selected_unit = null
var pending_use_data :Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.unit_selected.connect(_select_unit)
	SignalManager.unit_deselected.connect(_clear_selection)
	SignalManager.ui_item_clicked.connect(_on_ui_item_selected)
	SignalManager.ui_skill_clicked.connect(_on_ui_skill_selected)
	SignalManager.ui_page_tab_clicked.connect(_on_ui_page_tab_clicked)
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		var global_mouse_pos = get_global_mouse_position()
		var local_mouse_pos = terrain_layer.to_local(global_mouse_pos)
		var clicked_hex_coord = terrain_layer.local_to_map(local_mouse_pos)
		
		if not HexMapManager.world_cells.has(clicked_hex_coord):
			return
		_handle_click_by_mode(clicked_hex_coord)

func _handle_click_by_mode(coord:Vector2i)->void:
	var unit_on_tile =  current_selected_unit##game_map.get_unit_at_tile(coord)
	match  current_mode:
		InputMode.NORMAL:
			if unit_on_tile !=null:
				_select_unit(unit_on_tile)
			else:
				_inspect_tile_info(coord)
		InputMode.SELECTED:
			if unit_on_tile != null:
				if unit_on_tile.is_in_group("NPC"):
					_trigger_npc_dialog(unit_on_tile)
				elif unit_on_tile.is_in_group("Player"):
					_select_unit(unit_on_tile)
		InputMode.USE_ITEM:
			if unit_on_tile!=null and unit_on_tile.is_in_group("player"):
				_execute_use_item(unit_on_tile)
			else:
				_back_to_normal()
		InputMode.USE_SKILL:
			if unit_on_tile!=null:
				_execute_use_skill(unit_on_tile)
			else:
				_back_to_normal()
		InputMode.MOVE:
			if unit_on_tile.is_in_group("Player"):
				_try_move_selected_unit(coord)
				
##核心点击能力

##1、选中单位
func _select_unit(unit)->void:
	current_selected_unit = unit
	current_mode = InputMode.SELECTED
	#SignalManager.unit_selected.emit(unit)
##2、取消选中
func _clear_selection() ->void:
	current_selected_unit = null
	current_mode = InputMode.NORMAL


##3、查看空白地图块
func _inspect_tile_info(coord:Vector2i)->void:
	var tile_data = HexMapManager.world_cells[coord]
	SignalManager.tile_inspected.emit(tile_data)
	
func _try_move_selected_unit(target_coord:Vector2i) ->void:
	if target_coord:
		var path_data = game_map._ligal_hex_cell(current_selected_unit.current_hex,target_coord,current_selected_unit)
		if not path_data.is_empty():
			current_selected_unit.set_movement_path(path_data,terrain_layer)
			#SignalManager.hex_cell_clicked.emit(path_data,terrain_layer)


func _trigger_npc_dialog(npc_node)->void:
	print("show_npc",npc_node)
	_back_to_normal()
	

func _execute_use_item(target_unit)->void:
	print("use skill",target_unit)
	_back_to_normal()

func _execute_use_skill(target_unit)->void:
	print("use skill",target_unit)
	_back_to_normal()

func _back_to_normal()->void:
	current_mode = InputMode.NORMAL
	current_selected_unit = null
	pending_use_data.clear()


##ui 表现

func _on_ui_item_selected(item_data:Dictionary)->void:
	current_mode = InputMode.USE_ITEM
	pending_use_data = item_data
	print("在背包选中道具")

func _on_ui_skill_selected(skill_data:Dictionary)->void:
	current_mode = InputMode.USE_SKILL
	pending_use_data = skill_data
	print("选中技能")

func _on_ui_page_tab_clicked(tab_name:String)->void:
	print("点击了按钮",tab_name)
	match tab_name:
		"quest_log":
			SceneManager.open_scene("")
		"equipment":
			SceneManager.open_scene("")


func _on_move_pressed() -> void:
	current_mode=InputMode.MOVE


func _on_next_turn_pressed() -> void:
	print("回合结束，敌方开始行动")
	SignalManager.npc_turn.emit()
