# WorldMapController.gd
extends Node2D

@onready var terrain_layer: TileMapLayer = $HexMap
@onready var fog_layer: TileMapLayer = $FogLayer
@onready var camera_2d: Camera2D = $Camera2D



const CHARACTER_SCENE = preload("res://scenes/player/player_controller.tscn")
var players:player
@export var max_x:int = 25
@export var max_y:int = 25

func _ready() -> void:

	var final_map_data: Array[Dictionary] = []
	# 1. 🔍 核心判断：检查 SaveManager 内是否存在合法的地图存档
	if _has_valid_save_data():
		print("💾 [地图加载] 检测到现有存档，正在安全还原世界...")
		final_map_data = SaveManager.current_save.hex_map_info

	else:
		print("🎲 [地图加载] 存档地图信息为空，正在重新生成全新的随机肉鸽关卡...")
		var random_seed = randi() 
		# 调用上一轮写好的权重生成器
		final_map_data = HexMapManager.create_random_map(max_x,max_y,random_seed)
		
		
		# 🌟 自动把刚生成的新地图写进 SaveManager 的缓存中，时刻准备着被存盘
		_write_to_save(final_map_data)
	
	##运行地图生成,完成后发出信号渲染地图
	HexMapManager.generate_hex_map(final_map_data,terrain_layer)
	_spawn_player(Vector2i(0,0))
	camera_2d.setup_camera_limits()

func _spawn_player(spawn_coord:Vector2i)->void:
	players=CHARACTER_SCENE.instantiate()
	add_child(players)
	var spawn_piexl = terrain_layer.map_to_local(spawn_coord)
	players.global_position = terrain_layer.to_global(spawn_piexl)


func _unhandled_input(event: InputEvent) -> void:
	# 当玩家在地图上点击鼠标左键时
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 🌟 修正：确保对象名字和下面一致（防止因变量名笔误导致直接 return）
		if players == null: return
		
		# 1. 获取鼠标在屏幕/世界中的【全局】像素位置
		var global_mouse_pos = get_global_mouse_position()
		
		# 2. 🌟 核心修正：利用 to_local 将全局坐标转换为 terrain_layer 的【本地】像素坐标
		# 这一步会自动把地图的 position 偏移、scale 缩放全部计算进去，实现 100% 精准点击！
		var local_mouse_pos = terrain_layer.to_local(global_mouse_pos)
		
		# 3. 把【本地】像素点反向换算成六边形网格坐标
		var clicked_hex_coord = terrain_layer.local_to_map(local_mouse_pos)
		_ligal_hex_cell(players.current_hex,clicked_hex_coord,players)

##校验目标合法，计算路径并发起对目标地图格的信号
func _ligal_hex_cell(current_hex:Vector2i,target_hex:Vector2i,object)->void:
	if not HexMapManager.world_cells.has(target_hex):
		return
	if not HexMapManager.world_cells[target_hex].is_passable:
		print("target can't pass")
		return
	var path_result = HexMapManager.find_path(current_hex,target_hex)
	var hex_path = path_result["path"]
	if not hex_path.is_empty() and path_result["total_cost"]<=object.current_resource:
		SignalManager.hex_cell_clicked.emit(path_result,terrain_layer)
	else:
		return


##缓存读取函数
func _has_valid_save_data()->bool:
	if SaveManager.current_save == null:
		return false
	var map_info = SaveManager.current_save.hex_map_info
	return map_info!= null and not map_info.is_empty()

##缓存数据恢复
#func _load_map_from_save() -> Array[Dictionary]:
	#var raw_data :Array[Dictionary] = SaveManager.current_save.hex_map_info
	#var processed_data: Dictionary = {}
	#
	#for map_info in raw_data:
		#var coord:Vector2i
		#
	#return processed_data

func _write_to_save(data:Array[Dictionary]) -> void:
	if SaveManager.current_save != null:
		SaveManager.current_save.hex_map_info = data

func _parse_string_to_vector2i(key:String) ->Vector2i:
	key = key.replace("Vector2i","").replace("(","").replace(")","")
	var parts = key.split(",")
	
	if parts.size() == 2:
		return Vector2i(int(parts[0]),int(parts[1]))
	push_error("can't parse vector2i index")
	return Vector2i.ZERO


func _on_clear_pressed() -> void:
	SaveManager.delete_map(SaveManager.current_save)
	SceneManager.change_scene("res://scenes/hub/HubScene.tscn")




func _on_back_pressed() -> void:
	SceneManager.change_scene("res://scenes/hub/HubScene.tscn")
