# WorldMapController.gd
extends Node2D

@onready var terrain_layer: TileMapLayer = $HexMap
@onready var fog_layer: TileMapLayer = $FogLayer


# 假设你在 FogLayer 的 TileSet 里引入了一张纯黑/半透的迷雾切图
# 纯黑迷雾在 Atlas 中的坐标
const FOG_BLACK_ATLAS = Vector2i(0, 0) 
const FOG_SOURCE_ID = 1 # 迷雾 TileSet 的 Source ID


func _ready() -> void:
	SignalManager.map_generation_completed.connect(_on_map_data_ready)
	var final_map_data: Array[Dictionary] = []
	# 1. 🔍 核心判断：检查 SaveManager 内是否存在合法的地图存档
	if _has_valid_save_data():
		print("💾 [地图加载] 检测到现有存档，正在安全还原世界...")
		print(SaveManager.current_save.hex_map_info)
		final_map_data = SaveManager.current_save.hex_map_info

	else:
		print("🎲 [地图加载] 存档地图信息为空，正在重新生成全新的随机肉鸽关卡...")
		var random_seed = randi() 
		# 调用上一轮写好的权重生成器
		final_map_data = HexMapManager.create_random_map(50,50,random_seed)
		
		
		# 🌟 自动把刚生成的新地图写进 SaveManager 的缓存中，时刻准备着被存盘
		_write_to_save(final_map_data)
	##运行地图生成,完成后发出信号渲染地图
	HexMapManager.generate_hex_map(final_map_data)

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
