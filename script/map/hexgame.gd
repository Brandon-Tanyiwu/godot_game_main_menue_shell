# WorldMapController.gd
extends Node2D

@onready var terrain_layer: TileMapLayer = $HexMap
@onready var fog_layer: TileMapLayer = $FogLayer
@onready var camera_2d: Camera2D = $Camera2D



const CHARACTER_SCENE = preload("res://scenes/player/player.tscn")
const NPC_SCENE = preload("res://scenes/npc/npc.tscn")
var unit
@export var max_x:int = 25
@export var max_y:int = 25
var map_unit:Dictionary = {}
var game_level:int = 1

func _ready() -> void:
	var random_seed = randi() 
	SignalManager.npc_generation_completed.connect(_on_factory_npc_generation_completed)
	SignalManager.move_completed.connect(update_unit_hex)
	var final_map_data: Array[Dictionary] = []
	# 1. 🔍 核心判断：检查 SaveManager 内是否存在合法的地图存档
	if _has_valid_save_data():
		print("💾 [地图加载] 检测到现有存档，正在安全还原世界...")
		final_map_data = SaveManager.current_save.hex_map_info

	else:
		print("🎲 [地图加载] 存档地图信息为空，正在重新生成全新的随机肉鸽关卡...")
		
		# 调用上一轮写好的权重生成器
		final_map_data = HexMapManager.create_random_map(max_x,max_y,random_seed,game_level)
		
		
		# 🌟 自动把刚生成的新地图写进 SaveManager 的缓存中，时刻准备着被存盘
		_write_to_save(final_map_data)
	
	##运行地图生成,完成后发出信号渲染地图
	HexMapManager.generate_hex_map(final_map_data,terrain_layer)
	NpcFactory.NPC_Create(random_seed,game_level)
	
	_spawn_player(Vector2i(0,0),CHARACTER_SCENE)
	_spawn_player(Vector2i(5,5),NPC_SCENE)
	
	camera_2d.setup_camera_limits()
	

func _spawn_player(spawn_coord:Vector2i,scene,_id:int = 1,_items:Array=[])->void:
	unit=scene.instantiate()
	var spawn_piexl = terrain_layer.map_to_local(spawn_coord)
	register_unit(spawn_coord,unit)
	unit.current_hex = spawn_coord
	if "current_bag_data" in unit:
		unit.current_bag_data=_items
	unit.global_position = terrain_layer.to_global(spawn_piexl)
	add_child(unit)

func _on_factory_npc_generation_completed(spawn_list:Array)->void:
	print("start insert npc")
	for spawn in spawn_list:
		
		var id = spawn["id"]
		var type = spawn["type"]
		var coord = spawn["coord"]
		var items = spawn["reward"]
		_spawn_player(coord,NPC_SCENE,id,items)


##校验目标合法，计算路径并发起对目标地图格的信号
func _ligal_hex_cell(current_hex:Vector2i,target_hex:Vector2i,object)->Dictionary:
	if not HexMapManager.world_cells.has(target_hex):
		return {}
	if not HexMapManager.world_cells[target_hex].is_passable:
		print("target can't pass")
		return {}
	var path_result = HexMapManager.find_path(current_hex,target_hex)
	var hex_path = path_result["path"]
	if not hex_path.is_empty() and path_result["total_cost"]<=object.current_resource:
		#SignalManager.hex_cell_clicked.emit(path_result,terrain_layer)
		path_result["terrain_layer"]=terrain_layer
		return path_result
	else:
		return {}

##返回可同行的所有位置
func get_cell_neighbors(coord,radius,ap)->Dictionary:
	var hex_neighbors = [
		TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE
	]
	var visited: Dictionary = { coord: true }
	# 当前层（从中心点开始扩展）
	var current_layer: Array[Vector2i] = [coord]
	# 3. 核心：根据半径层层向外广播扩展
	for r in range(radius):
		var next_layer: Array[Vector2i] = []
		# 遍历当前外沿的每一个格子，把它们的邻居抓出来作为下一层
		for cell in current_layer:
			for direction in hex_neighbors:
				var neighbor = terrain_layer.get_neighbor_cell(cell, direction)
				var total_ap = HexMapManager.find_path(coord,neighbor)["total_cost"]
				
				if HexMapManager.world_cells.has(neighbor) and not visited.has(neighbor) and HexMapManager.world_cells[neighbor].is_passable and total_ap<ap:
					visited[neighbor] = true
					next_layer.append(neighbor)
					
		# 将下一层赋值给当前层，进入下一个半径循环
		current_layer = next_layer

	visited.erase(coord)
	return visited

##获取方块上的单位节点
func get_unit_at_tile(coord):
	
	if map_unit.has(coord):
		if is_instance_valid(map_unit[coord]):
			print("select unit on:",coord)
			return	map_unit[coord]
	return null
		
func register_unit(coord:Vector2i,_unit:Node)->void:
	map_unit[coord]=_unit

func unregister_unit(coord:Vector2i,_unit:Node)->void:
	if map_unit.has(coord):
		if map_unit[coord]==_unit:
			map_unit.erase(coord)

func update_unit_hex(new_coord:Vector2i,_unit:Node)->void:
	for coord in map_unit.keys():
		if map_unit[coord]== _unit:
			map_unit[coord].erase(coord)
			break
	map_unit[new_coord]=_unit

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
