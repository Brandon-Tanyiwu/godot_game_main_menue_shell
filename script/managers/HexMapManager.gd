extends Node
var world_cells:Dictionary = {}

var astar:AStar2D = AStar2D.new()
var _coord_to_id:Dictionary = {}
var _id_to_coord:Dictionary = {}
var _next_id:int = 0

enum FogState {
	UNEXPLORED, # 0: 未探索（全黑）
	EXPLORED,   # 1: 已探索无视野（半透明）
	VISIBLE     # 2: 当前可见（完全亮起）
	}

const HEX_DIRECTIONS = [
	Vector2i(1,0),Vector2i(1,-1),Vector2i(0,-1),
	Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,1)
]

var godot_hex_neighbors = [
			TileSet.CELL_NEIGHBOR_TOP_SIDE,
			TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
			TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
			TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
			TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE
		]
const GRASS = 0
const MOUNTAIN = 3
const HIGH_MOUNTAIN = 5
const SHALLOW_SEA = 6
const DEEP_SEA = 7
const PORT = 36
const LIGHTHOUSE = 38
const BEACH = 24
const ISLAND = 32

class CellData extends RefCounted:
	var id: int
	var coord: Vector2i
	var cell_name: String
	var movement_cost: float = 1.0
	var is_passable: bool = true
	var fog_state: FogState = FogState.UNEXPLORED
	var event_id:int
	
	func _init(runtime_data: Dictionary, csv_config: Dictionary) -> void:
		self.coord = runtime_data.get("coord", Vector2i.ZERO)
		self.event_id = runtime_data.get("event_id", 0)
		self.is_passable = true if csv_config.get("passable_info", 1) == 1 else false
		for key in csv_config:
			if key in self:
				self.set(key, csv_config[key])

var map_save :Array[Dictionary] = []
var _map_save_dict :Dictionary = {}
var map_list:Dictionary
var event_list:Dictionary
var post_list:Array=[]
func _ready() -> void:
	map_list = GameDataManager.tiles
	event_list = GameDataManager.events
	
func create_random_map(width:int,height:int,seed_val:int,game_level:int)->Array:
	map_save.clear()
	_map_save_dict.clear()
	seed(seed_val)
	
	var cell_index := 0
	
	# 1. 基础铺底
	for q in range(width):
		for r in range(height):
			cell_index += 1
			var coord = Vector2i(q, r)
			var cell_data = {
				"coord": coord,
				"map_id": DEEP_SEA,
				"event_id": 4,
				"cell_index": cell_index
			}
			map_save.append(cell_data)
			_map_save_dict[coord] = cell_data

	# 2 & 3. 陆地与不规则入海口生成
	_generate_borders_and_coasts(width, height)
	
	# 4. 点缀港口
	_place_ports_and_events(game_level)
	
	# 5. 点缀增益与危险事件
	_place_dynamic_elements(game_level)

	return map_save

func _generate_borders_and_coasts(width: int, height: int):
	var river_mouths_q: Array[Dictionary] = []
	var river_mouths_r = []
	var q_mouth_count = randi_range(1, 2)
	var r_mouth_count = randi_range(1, 2)
	
	# 初始化入海口基准线（确定中心点和基础宽度）
	for i in range(q_mouth_count):
		var center_q = randi_range(int(width * 0.15), int(width * 0.85))
		var mouth_width = randi_range(2, 4) # 基础宽度
		river_mouths_q.append({"center": center_q, "base_width": mouth_width})
		
	for i in range(r_mouth_count):
		var center_r = randi_range(int(height * 0.15), int(height * 0.85))
		var mouth_width = randi_range(2, 4)
		river_mouths_r.append({"center": center_r, "base_width": mouth_width})

	for coord in _map_save_dict:
		var q = coord.x
		var r = coord.y
		var base_thickness = randi_range(3, 4)
		
		var random_offset = randi_range(-1, 1)
		var land_thickness = clampi(base_thickness + random_offset, 2, 5)
		var dist_to_edge = min(q, r, width - 1 - q, height - 1 - r)
		
		#--------------------------------------------------
		# 全局入海口与深水航道动态演算（支持向外海延伸）
		#--------------------------------------------------
		var is_in_river_mouth = false
		var is_deep_channel = false
		
		# 极其关键：将距离做归一化映射，使喇叭口从内陆向外海无缝舒展
		# dist_to_edge 越小（越靠外海），width_modifier 越大，河道和深水域都等比例变宽
		var width_modifier = clampi(land_thickness + 1 - dist_to_edge, 0, 4)

		# 检查 Q 轴入海口
		for mouth in river_mouths_q:
			var dynamic_width = mouth["base_width"] + width_modifier
			var half_w = dynamic_width / 2.0
			var dist_to_center = abs(q - mouth["center"])
			
			if dist_to_center <= half_w:
				is_in_river_mouth = true
				# 【深水喇叭口核心】：深水域的触发宽度不再是固定值，而是随着整体河道变宽同步拉宽
				if dynamic_width >= 4:
					# 允许正中心约 30% ~ 40% 的区域被演变成深水航道（越往外海，能容纳深水的格子越多）
					var center_threshold = half_w * 0.45
					if dist_to_center <= center_threshold:
						is_deep_channel = true
				break
				
		# 检查 R 轴入海口
		if not is_in_river_mouth:
			for mouth in river_mouths_r:
				var dynamic_width = mouth["base_width"] + width_modifier
				var half_w = dynamic_width / 2.0
				var dist_to_center = abs(r - mouth["center"])
				
				if dist_to_center <= half_w:
					is_in_river_mouth = true
					if dynamic_width >= 4:
						var center_threshold = half_w * 0.45
						if dist_to_center <= center_threshold:
							is_deep_channel = true
					break

		#--------------------------------------------------
		# 地形刷写（将外海过渡区也纳入出海口管辖）
		#--------------------------------------------------
		if dist_to_edge < land_thickness:
			# 陆地区域内部
			if is_in_river_mouth:
				_map_save_dict[coord].map_id = DEEP_SEA if is_deep_channel else SHALLOW_SEA
			else:
				if dist_to_edge == 0:
					_map_save_dict[coord].map_id = HIGH_MOUNTAIN if randf() < 0.4 else MOUNTAIN
				elif dist_to_edge == 1:
					_map_save_dict[coord].map_id = MOUNTAIN if randf() < 0.7 else GRASS
				else:
					_map_save_dict[coord].map_id = GRASS if randf() < 0.8 else MOUNTAIN
					
		elif dist_to_edge < land_thickness + randi_range(2, 3):
			# 陆地向外海过渡的浅海缓冲带
			if is_in_river_mouth:
				# 关键改动：缓冲带内的出海口中央同样刷成深海，使其无缝与大洋深海连通
				_map_save_dict[coord].map_id = DEEP_SEA if is_deep_channel else SHALLOW_SEA
			else:
				if dist_to_edge == land_thickness:
					_map_save_dict[coord].map_id = BEACH if randf() < 0.8 else SHALLOW_SEA
				else:
					_map_save_dict[coord].map_id = SHALLOW_SEA

func _place_ports_and_events(level: int):
	var possible_port_cells = []
	for coord in _map_save_dict:
		var cell = _map_save_dict[coord]
		if cell.map_id == SHALLOW_SEA:
			var neighbors = get_neighbors(coord)
			var touch_land = false
			for n_pos in neighbors:
				var n_cell = get_cell(n_pos)
				if n_cell and (n_cell.map_id == MOUNTAIN or n_cell.map_id == HIGH_MOUNTAIN):
					touch_land = true
					break
			if touch_land:
				possible_port_cells.append(cell)
				
	possible_port_cells.shuffle()
	var port_count = clampi(level, 1, 3)
	for i in range(min(port_count, possible_port_cells.size())):
		possible_port_cells[i].map_id = PORT
		possible_port_cells[i].event_id = 3 
		post_list.append(possible_port_cells[i].coord)

func _place_dynamic_elements(level: int):
	var num_lighthouses = level * 2
	var num_islands = level * 2
	var num_archipelagos = level * 1
	
	var deep_sea_pool = []
	for coord in _map_save_dict:
		if _map_save_dict[coord].map_id == DEEP_SEA:
			deep_sea_pool.append(coord)
			
	deep_sea_pool.shuffle()
	
	# A. 投放灯塔
	for i in range(min(num_lighthouses, deep_sea_pool.size())):
		var pos = deep_sea_pool.pop_back()
		_map_save_dict[pos].map_id = LIGHTHOUSE
		_map_save_dict[pos].event_id = 4 
		
	# B. 投放独立小岛
	for i in range(min(num_islands, deep_sea_pool.size())):
		var pos = deep_sea_pool.pop_back()
		_map_save_dict[pos].map_id = ISLAND
		
	# C. 投放大规模群岛 (5 ~ 20格聚合)
	for i in range(min(num_archipelagos, deep_sea_pool.size())):
		if deep_sea_pool.is_empty(): break
		var center_pos = deep_sea_pool.pop_back()
		_map_save_dict[center_pos].map_id = ISLAND
		
		# 采用队列实现群岛的多层随机扩散
		var archipelago_cells: Array[Vector2i] = [center_pos]
		var target_size = randi_range(5, 20)
		var current_size = 1
		
		# 扩散搜索队列
		var queue: Array[Vector2i] = [center_pos]
		while queue.size() > 0 and current_size < target_size:
			var current_loc = queue.pop_front()
			var neighbors = get_neighbors(current_loc)
			neighbors.shuffle() # 随机扩散方向
			
			for n_pos in neighbors:
				if current_size >= target_size: break
				var n_cell = get_cell(n_pos)
				# 确保是深海且还没被归纳进当前群岛
				if n_cell and n_cell.map_id == DEEP_SEA and not n_pos in archipelago_cells:
					# 距离中心越远，蔓延概率稍微衰减，保证群岛凝聚力
					var dist = get_hex_distance(center_pos, n_pos)
					var spawn_chance = 0.85 if dist <= 1 else 0.5
					
					if randf() < spawn_chance:
						n_cell.map_id = ISLAND
						archipelago_cells.append(n_pos)
						deep_sea_pool.erase(n_pos)
						queue.append(n_pos) # 将新岛屿加入队列，继续向外辐射
						current_size += 1

	# D. 概率分配鱼群和海盗/海妖危险事件
	for coord in deep_sea_pool:
		var cell = _map_save_dict[coord]
		var rand_val = randf()
		if rand_val < 0.08:
			cell.event_id = 1 
		elif rand_val < 0.18:
			cell.event_id =6

func get_neighbors(pos:Vector2i)->Array:
	return [
		pos + Vector2i(1,0), pos + Vector2i(-1,0),
		pos + Vector2i(0,1), pos + Vector2i(0,-1),
		pos + Vector2i(1,-1), pos + Vector2i(-1,1)
	]

func get_cell(pos:Vector2i):
	return _map_save_dict.get(pos, null)

func _get_coord_info(coord:Vector2i):
	return _map_save_dict.get(coord, null)

func _get_random_cell()->Vector2i:
	var coord_list = _map_save_dict.keys()
	coord_list.shuffle()
	return coord_list.pick_random()

func process_coast():
	pass

func generate_hex_map(raw_map_data:Array[Dictionary],tilemap_layer:TileMapLayer) -> void:
	_clear_system()

	# 第一遍循环：构建 CellData 并注册 A* 航点
	for data in raw_map_data:
		var coord = data["coord"]
		var map_id = data["map_id"]
		var csv_config = GameDataManager.tiles[map_id] 
		var cell = CellData.new(data, csv_config)

		world_cells[coord] = cell
		var point_id = _get_or_create_id(coord)
		var world_pos = tilemap_layer.map_to_local(coord) 
		astar.add_point(point_id, world_pos, cell.movement_cost)
		
	# 第二遍循环：利用 Godot 系统的邻居判定连通 A* 网络
	for coord in world_cells:
		var current_id = _coord_to_id[coord]
		if not world_cells[coord].is_passable:
			astar.set_point_disabled(current_id, true)
		for direction in godot_hex_neighbors:
			var neighbor_coord = tilemap_layer.get_neighbor_cell(coord,direction)
			if neighbor_coord == coord:
				continue
			if world_cells.has(neighbor_coord):
				var neighbor_id = _coord_to_id[neighbor_coord]
				if not astar.are_points_connected(current_id,neighbor_id):
					astar.connect_points(current_id,neighbor_id)

	SignalManager.map_generation_completed.emit(world_cells)

func get_hex_distance(start:Vector2i,end:Vector2i)->int:
	var ax = start.x;var az = start.y;var ay = -ax-az
	var bx = end.x;var bz = end.y;var by = -bx-bz
	return int((abs(ax-bx)+abs(ay-by)+abs(az-bz))/2)

func find_path(start:Vector2i,end:Vector2i) -> Dictionary:
	var result = {"path":[] as Array[Dictionary],"total_cost":0.0}
	if not _coord_to_id.has(start) or not _coord_to_id.has(end):
		return result
	
	var start_id = _coord_to_id[start]
	var end_id = _coord_to_id[end]
	var id_path = astar.get_id_path(start_id,end_id)
	
	if id_path.is_empty():
		return result
	for id in id_path:
		var coord = _id_to_coord[id]
		result["path"].append({coord:world_cells[coord]["movement_cost"]})
		if id != start_id:
			result["total_cost" ] += world_cells[coord].movement_cost
	return result

func _clear_system():
	world_cells.clear()
	astar.clear()
	_coord_to_id.clear()
	_id_to_coord.clear()
	_next_id = 0

func _get_or_create_id(coord:Vector2i):
	if _coord_to_id.has(coord):return _coord_to_id[coord]
	var id = _next_id
	_coord_to_id[coord] = id
	_id_to_coord[id] = coord
	_next_id+=1
	return id

# 获取最近港口的位置
func _get_nearest_port(unit:Node) -> Vector2:
	# 假设你的港口在 "ports" 组里，或者通过地图管理器获取
	var ports = HexMapManager.post_list
	var nearest_pos = Vector2.ZERO
	var min_dist = INF
	for port in ports:
		var dist = HexMapManager.get_hex_distance(unit.current_hex,port)
		if dist < min_dist:
				min_dist = dist
				nearest_pos = port.global_position
	return nearest_pos

# 获取守卫最近的海岸线巡逻点
func _get_nearest_coastline_points(unit:Node) -> Vector2:
	return _get_nearest_coastline_points(unit)



func autocomplete_screen_by_scaling_layer(tilemap_layer: TileMapLayer, width: int, height: int):
	tilemap_layer.scale = Vector2.ONE
	tilemap_layer.position = Vector2.ZERO
	
	var viewport_size = tilemap_layer.get_viewport_rect().size
	var start_pos = tilemap_layer.map_to_local(Vector2i(0, 0))
	var end_pos = tilemap_layer.map_to_local(Vector2i(width - 1, height - 1))
	var tile_size = tilemap_layer.tile_set.tile_size
	var map_pixel_size = (end_pos - start_pos).abs() + Vector2(tile_size)
	
	var scale_x = viewport_size.x / map_pixel_size.x
	var scale_y = viewport_size.y / map_pixel_size.y
	var final_scale = min(scale_x, scale_y)
	
	tilemap_layer.scale = Vector2(final_scale, final_scale)
	var scaled_map_size = map_pixel_size * final_scale
	tilemap_layer.position = (viewport_size - scaled_map_size) / 2.0
	tilemap_layer.position -= start_pos * final_scale
	
func autocomplete_screen_with_camera(tilemap_layer: TileMapLayer, width: int, height: int, camera: Camera2D):
	var viewport_size = tilemap_layer.get_viewport_rect().size
	var start_pos = tilemap_layer.map_to_local(Vector2i(0, 0))
	var end_pos = tilemap_layer.map_to_local(Vector2i(width - 1, height - 1))
	var tile_size = tilemap_layer.tile_set.tile_size
	var map_pixel_size = (end_pos - start_pos).abs() + Vector2(tile_size)
	
	var scale_x = viewport_size.x / map_pixel_size.x
	var scale_y = viewport_size.y / map_pixel_size.y
	var final_zoom = min(scale_x, scale_y)
	
	camera.zoom = Vector2(final_zoom, final_zoom)
	var map_center = start_pos + (end_pos - start_pos) / 2.0
	camera.position = map_center
func initialize_from_painted_map(tilemap_layer: TileMapLayer) -> void:
	grid_map.clear()
	port_positions.clear()
	coastline_positions.clear()
	
	# 1. 获取手绘地图中所有有贴图的格子坐标
	var used_cells = tilemap_layer.get_used_cells()
	var tile_size = tilemap_layer.tile_set.tile_size # 例如 Vector2i(64, 64)
	
	# 2. 遍历每一个绘制的格子，提取其自定义数据
	for cell_coords in used_cells:
		var tile_data: TileData = tilemap_layer.get_cell_tile_data(cell_coords)
		if tile_data:
			# 读取我们在第一步设置的 "tile_type" 属性
			var type_name = tile_data.get_custom_data("tile_type")
			
			# 如果该格子有标记类型，将其记录进我们的字典
			if type_name != "":
				grid_map[cell_coords] = type_name
				
				# 顺便转换为世界位置存入缓存，供 NPC 查找
				var world_pos = tilemap_layer.map_to_local(cell_coords)
				match type_name:
					"port":
						port_positions.append(world_pos)
					"coastline":
						coastline_positions.append(world_pos)
						
	print("手绘地图解析完毕！共发现港口：", port_positions.size(), "，海岸线：", coastline_positions.size())
