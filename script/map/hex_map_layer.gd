extends TileMapLayer


const source_id = 2 

func _ready() -> void:
	SignalManager.map_generation_completed.connect(_on_data_layer_ready)

func _on_data_layer_ready(cells_data:Dictionary)->void:
	clear()
	for coord in cells_data:
		var cell = cells_data[coord] as HexMapManager.CellData
		var cell_info = GameDataManager.get_terrain_info(cell.id)
		#print(cell,"  ",atlas_coord)
		set_cell(coord,source_id,Vector2i(cell_info["cell_source_x"],cell_info["cell_source_y"]))
	print("layer completed")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_local_pos = get_local_mouse_position()
			var clicked_hex_coord = local_to_map(mouse_local_pos)
			
			if HexMapManager.world_cells.has(clicked_hex_coord):
				var cell_data = HexMapManager.world_cells[clicked_hex_coord]
				print("click hex :",clicked_hex_coord,cell_data.terrain_type)
				SignalManager.hex_cell_clicked.emit(clicked_hex_coord,cell_data)
			
