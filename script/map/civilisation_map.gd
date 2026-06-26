# WorldMapController.gd
extends Node2D

@onready var terrain_layer: TileMapLayer = $HexMap
@onready var fog_layer: TileMapLayer = $FogLayer
@onready var camera_2d: Camera2D = $Camera2D


# 假设你在 FogLayer 的 TileSet 里引入了一张纯黑/半透的迷雾切图
# 纯黑迷雾在 Atlas 中的坐标
const FOG_BLACK_ATLAS = Vector2i(0, 2) 
const FOG_SOURCE_ID = 2 # 迷雾 TileSet 的 Source ID
const CHARACTER_SCENE = preload("res://scenes/player/player_controller.tscn")
var players:player
@export var max_x:int = 25
@export var max_y:int = 25

func _ready() -> void:
	SignalManager.map_generation_completed.connect(_on_map_data_ready)
	SignalManager.request_reveal_fog.connect(_on_cell_reveal_fog)
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




## 数据层生成完毕后的核心回调
func _on_map_data_ready(cells_data: Dictionary) -> void:
	fog_layer.clear()
	for coord in cells_data:
		var cell = cells_data[coord]
		
		# 如果数据层说这个格子是“未探索”，表现层就在 FogLayer 上盖一块黑色的六边形
		if cell.fog_state == HexMapManager.FogState.UNEXPLORED:
			fog_layer.set_cell(coord, FOG_SOURCE_ID, FOG_BLACK_ATLAS)
			
	print("🌫️ [迷雾系统] 战争迷雾已成功铺满整个世界！")

## 驱散目标格子周围的迷雾
func _on_cell_reveal_fog(coord: Vector2i,radius:int) -> void:
	print("⚡ [事件响应] 点击了 ", coord, "，正在执行局部战争迷雾驱散...")
	
	# 1. 驱散点击的格子本身
	_reveal_cell(coord)
	
	# 2. 🌟 核心修正：利用 Godot 4 内置的 CellNeighbor 枚举安全获取六边形邻居
	# 尖顶六边形（Vertical）的 6 个标准邻居方向定义如下：
	if radius>=1:
		var hex_neighbors = [
			TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
			TileSet.CELL_NEIGHBOR_TOP_SIDE,
			TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
			TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
			TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE
		]
		
		for direction in hex_neighbors:
			# 🌟 使用 fog_layer 自己的内置函数去抓取错位布局下的精准邻居坐标！
			var neighbor_coord = fog_layer.get_neighbor_cell(coord, direction)
			_reveal_cell(neighbor_coord)

## 内部驱散函数
func _reveal_cell(target_coord: Vector2i) -> void:
	if HexMapManager.world_cells.has(target_coord):
		var cell = HexMapManager.world_cells[target_coord]
		# 数据层修改状态
		cell.fog_state = HexMapManager.FogState.VISIBLE
		# 表现层：直接把 FogLayer 这一格的砖块擦除掉 (erase_cell)，底下的地形就露出来了！
		fog_layer.erase_cell(target_coord)

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
		
		# 检查这个格子是否合法且在地图数据内
		if not HexMapManager.world_cells.has(clicked_hex_coord):
			# print("点击了地图外部: ", clicked_hex_coord) # 调试用
			return
			
		# 4. 检查目标点是否可通行
		if not HexMapManager.world_cells[clicked_hex_coord].is_passable:
			print("🚫 那是高山或深海，无法通行！")
			return
			
		# 5. 🚀 触发你的 Manager 寻路接口
		# 此时传入的 clicked_hex_coord 已经是绝对正确的 10x10 网格坐标了
		var path_result = HexMapManager.find_path(players.current_hex, clicked_hex_coord)
		var hex_path = path_result["path"]
		
		if not hex_path.is_empty():
			print("🏃 找到路径，消耗行动力: ", path_result["total_cost"])
			# 6. 命令角色开始走格子
			players.move_along_path(hex_path, terrain_layer)
		else:
			print("❌ 无法到达该目标点（无路可走）")

func _on_back_pressed() -> void:
	SceneManager.change_scene("res://scenes/hub/HubScene.tscn")
