class_name PlayerInputControls
extends Node2D

enum InputMode {NORMAL,SELECTED,USE_ITEM,USE_SKILL,MOVE,ATTACK}


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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var is_press = event.is_pressed()
		var is_release = not event.is_pressed()
		
		# 同时支持普通的点击（按下时触发），以及拖拽释放（松开时触发）
		# 这可以完美兼容点击后点击目标与直接拖拽放置到目标身上两种操作
		var should_process = false
		if is_press:
			should_process = true
		elif is_release:
			if current_mode == InputMode.USE_ITEM or current_mode == InputMode.USE_SKILL:
				should_process = true
				
		if should_process:
			var global_mouse_pos = get_global_mouse_position()
			var local_mouse_pos = terrain_layer.to_local(global_mouse_pos)
			var clicked_hex_coord = terrain_layer.local_to_map(local_mouse_pos)
			
			if not HexMapManager.world_cells.has(clicked_hex_coord):
				return
			_handle_click_by_mode(clicked_hex_coord)

		

func _handle_click_by_mode(coord:Vector2i)->void:
	var unit_on_tile = null
	if game_map and game_map.has_method("get_unit_at_tile"):
		unit_on_tile = game_map.get_unit_at_tile(coord)
		
	match current_mode:
		InputMode.NORMAL:
			if unit_on_tile != null:
				_select_unit(unit_on_tile)
			else:
				_inspect_tile_info(coord)
		InputMode.SELECTED:
			if unit_on_tile != null:
				if unit_on_tile.is_in_group("NPC"):
					_trigger_npc_dialog(unit_on_tile)
				elif unit_on_tile.is_in_group("Player"):
					_select_unit(unit_on_tile)
			else:
				# 直接点击空地图完成移动
				if current_selected_unit != null and current_selected_unit.is_in_group("Player"):
					_try_move_selected_unit(coord)
		InputMode.USE_ITEM:
			if unit_on_tile != null:
				_execute_use_item(unit_on_tile)
			else:
				_back_to_normal()
		InputMode.USE_SKILL:
			if unit_on_tile != null:
				_execute_use_skill(unit_on_tile)
			else:
				_back_to_normal()
		InputMode.MOVE:
			if current_selected_unit != null and current_selected_unit.is_in_group("Player"):
				_try_move_selected_unit(coord)
		InputMode.ATTACK:
			if unit_on_tile != null:
				_execute_attack(unit_on_tile)
			else:
				_back_to_normal()
				
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
	if target_coord and current_selected_unit:
		var path_data = game_map._ligal_hex_cell(current_selected_unit.current_hex,target_coord,current_selected_unit)
		if not path_data.is_empty():
			current_selected_unit.set_movement_path(path_data,terrain_layer)
			# 移动后恢复到选中状态，方便后续进行其他交互或再次移动
			current_mode = InputMode.SELECTED


func _trigger_npc_dialog(npc_node)->void:
	print("show_npc",npc_node)
	_back_to_normal()
	

func _execute_use_item(target_unit)->void:
	print("Using item on: ", target_unit, " data: ", pending_use_data)
	if SignalManager.has_signal("use_item_on_unit"):
		SignalManager.use_item_on_unit.emit(current_selected_unit, target_unit, pending_use_data)
	else:
		if target_unit.has_method("use_item"):
			target_unit.use_item(pending_use_data)
	_back_to_normal()

func _execute_use_skill(target_unit)->void:
	print("Using skill on: ", target_unit, " data: ", pending_use_data)
	if SignalManager.has_signal("use_skill_on_unit"):
		SignalManager.use_skill_on_unit.emit(current_selected_unit, target_unit, pending_use_data)
	else:
		if target_unit.has_method("use_skill"):
			target_unit.use_skill(pending_use_data)
	_back_to_normal()
var times =0
func _execute_attack(target_unit)->void:


	if SignalManager.has_signal("player_attack_triggered"):
		times+=1
		print("attack emit times",times)
		SignalManager.player_attack_triggered.emit(current_selected_unit, target_unit)
	else:
		if target_unit.has_method("take_damage"):
			target_unit.take_damage(current_selected_unit.get("attack") if "attack" in current_selected_unit else 10)
	# 攻击完后默认恢复到选中状态
	current_mode = InputMode.SELECTED

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
			SceneManager.open_scene("",game_map)
		"equipment":
			SceneManager.open_scene("",game_map)
		"attack", "combat":
			_on_attack_pressed()


func _on_move_pressed() -> void:
	current_mode=InputMode.MOVE

func _on_attack_pressed() -> void:
	current_mode = InputMode.ATTACK
	print("切换为攻击模式")

func _on_next_turn_pressed() -> void:
	print("回合结束，敌方开始行动")
	SignalManager.npc_turn.emit()
