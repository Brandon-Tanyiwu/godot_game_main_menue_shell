extends Node
var world_cells:Dictionary = {}

var astar:AStar2D = AStar2D.new()
var _coord_to_id:Dictionary = {}
var _id_to_coord:Dictionary = {}
var _next_id:int = 0
enum FogState {
	UNEXPLORED, # 0: 未探索（全黑，连地形都看不见）
	EXPLORED,   # 1: 已探索但没视野（半透明/灰暗，能看地形，看不到敌军动态）
	VISIBLE     # 2: 当前可见（完全亮起）
	}
const HEX_DIRECTIONS = [
	Vector2i(1,0),Vector2i(1,-1),Vector2i(0,-1)
	,Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,1)
]
# 内部类：定义单个六边形的数据结构
class CellData extends RefCounted:
	var id: int #地形id
	var coord: Vector2i         # 轴向坐标 Vector2i(q, r)
	var cell_name: String    # 地形名称: "grass", "forest", "mountain", "water"
	var movement_cost: float = 1.0 # 移动消耗权重
	var is_passable: bool = true  # 是否可通过
	var fog_state: FogState = FogState.UNEXPLORED
	var event_id:int
	func _init(runtime_data: Dictionary, csv_config: Dictionary) -> void:
		# 先行注入坐标和事件等运行时变动数据
		self.coord = runtime_data.get("coord", Vector2i.ZERO)
		self.event_id = runtime_data.get("event_id", 0)
		self.is_passable = true if csv_config.passable_info==1 else false
		# 自动对齐并注入 CSV 的静态配置数据
		for key in csv_config:
			if key in self:
				self.set(key, csv_config[key])


var map_save :Array[Dictionary] = []
var map_list:Dictionary
var event_list:Dictionary

func _ready() -> void:
	map_list = GameDataManager.tiles
	event_list = GameDataManager.events
	
func create_random_map(width:int,height:int,seed_val:int,game_level)->Array:
	var noise = FastNoiseLite.new()
	noise.seed = seed_val
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.06
	var cell_index:int = 0
	for q in range(width):
		#var q_offset = q >> 1
		#for r in range(-q_offset,height-q_offset): 
		for r in range(height):
			cell_index +=1 
			var coord = Vector2i(q,r)
			var n_val = noise.get_noise_2d(float(q),float(r))
			var final_type :int
			var final_event:int = 1
			for zone_id in map_list:
				var zone=map_list[zone_id]
				if n_val<=zone["priority"]:
					final_type = zone["id"]
					break
			#if not final_type:
				#final_type = 1
				
			for event_id in event_list:
				var event=event_list[event_id]
				if n_val<=event["priority"]:
					final_event = event["id"]
					break
			if not final_event:
				pass
				
			map_save.append({"coord":coord,"map_id":final_type,"event_id":final_event,"cell_index":cell_index})
	return map_save

func generate_hex_map(raw_map_data:Array[Dictionary],tilemap_layer:TileMapLayer) -> void:
		
	_clear_system()
	# 平顶六边形专用方向（Horizontal）
	#var godot_hex_neighbors = [
		#TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		#TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
		#TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
		#TileSet.CELL_NEIGHBOR_LEFT_SIDE,
		#TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
		#TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE
	#]
	var godot_hex_neighbors = [
			TileSet.CELL_NEIGHBOR_TOP_SIDE,             # 正上
			TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,          # 正下
			TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,        # 左上
			TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,       # 右上
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,     # 左下
			TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE     # 右下
		]
	##平顶六边形先width,后循环height，尖顶六边形反之
	# 1. 第一遍循环：构建运行时 CellData 实体、精简数据归档、注册 A* 航点
	for data in raw_map_data:
		var coord = data["coord"]
		var map_id = data["map_id"]
		var csv_config = GameDataManager.tiles[map_id] 
		var cell = CellData.new(data, csv_config)
		# 依据地形 ID 属性映射具体通过性（可按需改为读取配置表单例）
		world_cells[coord] = cell
		var point_id = _get_or_create_id(coord)
		#var world_pos_approx = _axial_to_pixel(coord) ##使用自演算的六边形差分中心点
		var world_pos = tilemap_layer.map_to_local(coord) ##使用tilemaplayer 提供的真实中间点
		astar.add_point(point_id, world_pos, cell.movement_cost)
		
	# 2. 第二遍循环：双向打通 A* 拓扑网络并阻断障碍物
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
		#for dir in HEX_DIRECTIONS:
			#var neighbor_coord = coord + dir
			#if world_cells.has(neighbor_coord):
				#var neighbor_id = _coord_to_id[neighbor_coord]
				#if not astar.are_points_connected(current_id, neighbor_id):
					#astar.connect_points(current_id, neighbor_id)
					

	SignalManager.map_generation_completed.emit(world_cells)

func get_hex_distance(start:Vector2i,end:Vector2i)->int:
	var ax = start.x;var az = start.y;var ay = -ax-az
	var bx = end.x;var bz = end.y;var by = -bx-bz
	return int((abs(ax-bx)+abs(ay-by)+abs(az-bz))/2)

##寻路接口
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
	return	 result

##内部辅助函数

func _clear_system():
	world_cells.clear()
	astar.clear()
	_coord_to_id.clear()
	_id_to_coord.clear()
	_next_id = 0



func _axial_to_pixel(coord:Vector2i)->Vector2:
	var x=1.5*coord.x
	var y = sqrt(3.0)* (coord.y + coord.x/2.0)
	return Vector2i(x,y)
	
func _get_or_create_id(coord:Vector2i):
	if _coord_to_id.has(coord):return _coord_to_id[coord]
	var id = _next_id
	_coord_to_id[coord] = id
	_id_to_coord[id] = coord
	_next_id+=1
	return id
## 直接缩放地图图层节点
func autocomplete_screen_by_scaling_layer(tilemap_layer: TileMapLayer, width: int, height: int):
	# 1. 重置图层的变换，防止上一次生成的缩放干扰计算
	tilemap_layer.scale = Vector2.ONE
	tilemap_layer.position = Vector2.ZERO
	
	# 2. 获取屏幕大小和地图的像素大小
	var viewport_size = tilemap_layer.get_viewport_rect().size
	var start_pos = tilemap_layer.map_to_local(Vector2i(0, 0))
	var end_pos = tilemap_layer.map_to_local(Vector2i(width - 1, height - 1))
	var tile_size = tilemap_layer.tile_set.tile_size
	var map_pixel_size = (end_pos - start_pos).abs() + Vector2(tile_size)
	
	# 3. 计算并应用缩放因子
	var scale_x = viewport_size.x / map_pixel_size.x
	var scale_y = viewport_size.y / map_pixel_size.y
	var final_scale = min(scale_x, scale_y)
	
	tilemap_layer.scale = Vector2(final_scale, final_scale)
	
	# 4. 动态计算位置以实现全屏居中
	# 缩放后地图的实际像素大小
	var scaled_map_size = map_pixel_size * final_scale
	# 调整 TileMapLayer 的 position，将其挪到屏幕中央
	tilemap_layer.position = (viewport_size - scaled_map_size) / 2.0
	
	# 💡 注意：因为尖顶六边形的第一列中心点带有一些微调偏移，为了极致的像素对齐，可以加上 start_pos 修正
	tilemap_layer.position -= start_pos * final_scale
	
	
## 动态调整相机，使任意大小的地图完美居中并铺满屏幕
func autocomplete_screen_with_camera(tilemap_layer: TileMapLayer, width: int, height: int, camera: Camera2D):
	# 1. 获取当前屏幕（视口）的实际像素大小
	var viewport_size = tilemap_layer.get_viewport_rect().size
	
	# 2. 计算 10x10 地图像素世界的边界
	# 利用 Godot 的 map_to_local 拿到左上角和右下角的精确像素中心点
	var start_pos = tilemap_layer.map_to_local(Vector2i(0, 0))
	var end_pos = tilemap_layer.map_to_local(Vector2i(width - 1, height - 1))
	
	# 加上单个瓦片的大小作为边缘缓冲（防止半个格子被切掉）
	var tile_size = tilemap_layer.tile_set.tile_size
	var map_pixel_size = (end_pos - start_pos).abs() + Vector2(tile_size)
	
	# 3. 计算缩放比例（取宽高缩放比的最小值，确保地图完整显示在屏幕内，不超出边界）
	var scale_x = viewport_size.x / map_pixel_size.x
	var scale_y = viewport_size.y / map_pixel_size.y
	var final_zoom = min(scale_x, scale_y)
	
	# 4. 应用缩放和居中
	camera.zoom = Vector2(final_zoom, final_zoom)
	
	# 相机对齐到地图的几何中心点
	var map_center = start_pos + (end_pos - start_pos) / 2.0
	camera.position = map_center
