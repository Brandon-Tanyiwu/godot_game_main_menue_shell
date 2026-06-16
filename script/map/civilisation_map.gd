# WorldMapController.gd
extends Node2D

@onready var terrain_layer: TileMapLayer = $HexMap
@onready var fog_layer: TileMapLayer = $FogLayer


# 假设你在 FogLayer 的 TileSet 里引入了一张纯黑/半透的迷雾切图
# 纯黑迷雾在 Atlas 中的坐标
const FOG_BLACK_ATLAS = Vector2i(0, 0) 
const FOG_SOURCE_ID = 1 # 迷雾 TileSet 的 Source ID

func _ready() -> void:
	# 1. 🌟 [关联事件]：让迷雾层和地形层同时监听大脑的生成完毕通知
	SignalManager.map_generation_completed.connect(_on_map_data_ready)
	SignalManager.hex_cell_clicked.connect(_on_cell_clicked)
	
	# 2. 🌟 [开始生成]：主动让大脑开始干活，生成 30x20 的世界
	print("⚙️ [地图初始化] 场景就绪，开始请求数据层生成地图...")
	HexMapManager.generate_hex_map(50, 50)

## 数据层生成完毕后的核心回调
func _on_map_data_ready(cells_data: Dictionary) -> void:
	# 清空迷雾层旧画面
	fog_layer.clear()
	
	# 遍历全图，初始化迷雾表现
	for coord in cells_data:
		var cell = cells_data[coord]
		
		# 如果数据层说这个格子是“未探索”，表现层就在 FogLayer 上盖一块黑色的六边形
		if cell.fog_state == HexMapManager.FogState.UNEXPLORED:
			fog_layer.set_cell(coord, FOG_SOURCE_ID, FOG_BLACK_ATLAS)
			
	print("🌫️ [迷雾系统] 战争迷雾已成功铺满整个世界！")

## 验证测试：点击一个格子，驱散它周围的迷雾
func _on_cell_clicked(coord: Vector2i, _data: RefCounted) -> void:
	print("⚡ [事件响应] 点击了 ", coord, "，正在执行局部战争迷雾驱散...")
	# 驱散点击的格子本身
	_reveal_cell(coord)
	
	# 驱散点击格子周围一圈的邻居 (利用之前写的方向常量)
	for dir in HexMapManager.HEX_DIRECTIONS:
		_reveal_cell(coord + dir)

## 内部驱散函数
func _reveal_cell(target_coord: Vector2i) -> void:
	if HexMapManager.world_cells.has(target_coord):
		var cell = HexMapManager.world_cells[target_coord]
		# 数据层修改状态
		cell.fog_state = HexMapManager.FogState.VISIBLE
		# 表现层：直接把 FogLayer 这一格的砖块擦除掉 (erase_cell)，底下的地形就露出来了！
		fog_layer.erase_cell(target_coord)
