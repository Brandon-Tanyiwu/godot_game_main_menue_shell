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
	var terrain_type: String    # 地形名称: "grass", "forest", "mountain", "water"
	var movement_cost: float = 1.0 # 移动消耗权重
	var is_passable: bool = true   # 是否可通过
	var fog_state: FogState = FogState.UNEXPLORED
	
	
func generate_hex_map(width: int,height:int) -> void:
		
	_clear_system()
	
	##平顶六边形先width,后循环height，尖顶六边形反之
	for q in range(width):
		var q_offset = q >> 1
		for r in range(-q_offset,height-q_offset):
			var coord = Vector2i(q,r)
			var cell = CellData.new()
			cell.coord = coord
			
			var rand = randf()
			if rand<=0.15:
				cell.id=0
			elif  rand <0.35:
				cell.id=3
			else:
				cell.id=5
			world_cells[coord] = cell
			
			var id = _get_or_create_id(coord)
			var world_pos_approx = _axial_to_pixel(coord)
			astar.add_point(id,world_pos_approx,cell.movement_cost)
	for coord in world_cells:
		var current_id = _coord_to_id[coord]
		if not world_cells[coord].is_passable:
			astar.set_point_disabled(current_id,true)
		for dir in HEX_DIRECTIONS:
			var neighbor_coord = coord +dir
			if world_cells.has(neighbor_coord):
				var neighbor_id = _coord_to_id[neighbor_coord]
				if not astar.are_points_connected(current_id,neighbor_id):
					astar.connect_points(current_id,neighbor_id)
	SignalManager.map_generation_completed.emit(world_cells)

func get_hex_distance(start:Vector2i,end:Vector2i)->int:
	var ax = start.x;var az = start.y;var ay = -ax-az
	var bx = end.x;var bz = end.y;var by = -bx-bz
	return int((abs(ax-bx)+abs(ay-by)+abs(az-bz))/2)

##寻路接口
func find_path(start:Vector2i,end:Vector2i) -> Dictionary:
	var result = {"path":[] as Array[Vector2i],"total_cost":0.0}
	
	if not _coord_to_id.has(start) or not _coord_to_id.has(end):
		return result
	
	var start_id = _coord_to_id[start]
	var end_id = _coord_to_id[end]
	
	var id_path = astar.get_id_path(start_id,end_id)
	if id_path.is_empty():
		return result
	for id in id_path:
		var coord = _id_to_coord[id]
		result["path"].apppend(coord)
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
