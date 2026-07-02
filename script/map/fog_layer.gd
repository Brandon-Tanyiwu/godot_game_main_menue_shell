extends TileMapLayer
# 假设你在 FogLayer 的 TileSet 里引入了一张纯黑/半透的迷雾切图
# 纯黑迷雾在 Atlas 中的坐标
const FOG_BLACK_ATLAS = Vector2i(0, 2) 
const FOG_SOURCE_ID = 2 # 迷雾 TileSet 的 Source ID

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.map_generation_completed.connect(_on_map_data_ready)
	SignalManager.request_reveal_fog.connect(_on_cell_reveal_fog)


## 数据层生成完毕后的核心回调
func _on_map_data_ready(cells_data: Dictionary) -> void:
	clear()
	for coord in cells_data:
		var cell = cells_data[coord]
		
		# 如果数据层说这个格子是“未探索”，表现层就在 FogLayer 上盖一块黑色的六边形
		if cell.fog_state == HexMapManager.FogState.UNEXPLORED:
			set_cell(coord, FOG_SOURCE_ID, FOG_BLACK_ATLAS)
			
	print("🌫️ [迷雾系统] 战争迷雾已成功铺满整个世界！")

## 驱散目标格子周围的迷雾（支持任意半径 radius）
func _on_cell_reveal_fog(coord: Vector2i, radius: int) -> void:
	if radius < 0:
		return
		
	# 1. 驱散点击的格子本身
	_reveal_cell(coord)
	if radius == 0:
		return

	# 2. 六边形标准 6 个邻居方向
	var hex_neighbors = [
		TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE
	]

	# 用字典当做 HashSet，记录所有已经决定要驱散的格子（避免重复计算）
	var visited: Dictionary = { coord: true }
	# 当前层（从中心点开始扩展）
	var current_layer: Array[Vector2i] = [coord]

	# 3. 核心：根据半径层层向外广播扩展
	for r in range(radius):
		var next_layer: Array[Vector2i] = []
		
		# 遍历当前外沿的每一个格子，把它们的邻居抓出来作为下一层
		for cell in current_layer:
			for direction in hex_neighbors:
				var neighbor = get_neighbor_cell(cell, direction)
				
				# 如果这个邻居之前没处理过，则加入下一层并执行驱散
				if not visited.has(neighbor):
					visited[neighbor] = true
					next_layer.append(neighbor)
					_reveal_cell(neighbor) # 🌟 逐个驱散
					
		# 将下一层赋值给当前层，进入下一个半径循环
		current_layer = next_layer

## 内部驱散函数
func _reveal_cell(target_coord: Vector2i) -> void:
	if HexMapManager.world_cells.has(target_coord):
		var cell = HexMapManager.world_cells[target_coord]
		# 数据层修改状态
		cell.fog_state = HexMapManager.FogState.VISIBLE
		# 表现层：直接把 FogLayer 这一格的砖块擦除掉 (erase_cell)，底下的地形就露出来了！
		erase_cell(target_coord)
