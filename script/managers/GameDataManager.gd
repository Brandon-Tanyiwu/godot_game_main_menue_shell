extends Node
const icon_path="res://resource/item/#1 - Transparent Icons.png"
const icon_size = 32

@onready var icon_spritesheet = load(icon_path)


var items:Dictionary = {}
var skills:Dictionary = {}
var icons:Dictionary = {}
func _ready() -> void:
	print("load csv data")
	items = _load_csv("res://config/item/item_data.csv")
	icons = _load_csv("res://config/icon/icon_match.csv")
	print(items)

func _load_csv(path:String, delimiter:String=",")-> Dictionary:
	var result:Dictionary = {}
	
	if not FileAccess.file_exists(path):
		push_error("can't find file:"+ path)
		return result
	
	var file = FileAccess.open(path,FileAccess.READ)
	
	var headers = file.get_csv_line(delimiter)
	if headers.is_empty() or headers[0]=="":
		push_error("can't find columns name:"+path)
		return result
	
	while !file.eof_reached():
		var line = file.get_csv_line(delimiter)
		
		if line.size() < headers.size() or line[0].strip_edges() == "":
			continue
		
		var row_data:Dictionary = {}
		var row_id : String = line[0].strip_edges()
		
		for i in range(1,line.size()):
			if i< headers.size():
				var key = headers[i].strip_edges()
				var value = line[i].strip_edges()
				row_data[key] = _auto_cast(value)
		result[row_id] = row_data
	file.close()
	return result

func get_item_data(item_id:int) -> ItemData:
	var raw_info = items.get(item_id)
	var icon_info = icons.get(item_id)
	if not raw_info:return null
	
	var item = ItemData.new()
	for key in raw_info:
		var value = raw_info[key]
		item.set(key,value)
	var grid_x:int = icon_info.get("x",0)
	var grid_y:int = icon_info.get('y',0)
	item.set("x",grid_x)
	item.set("y",grid_y)
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = icon_spritesheet
	
	atlas_texture.region = Rect2(
		grid_x*icon_size,grid_y*icon_size,icon_size,icon_size
	)
	item.icon = atlas_texture
	return item
func _auto_cast(val:String)->Variant:
	match val.to_lower():
		"":
			return ""
		"true":
			return true
		"false":
			return false
		_:
			if val.is_valid_int():
				return val.to_int()
			if val.is_valid_float():
				return val.to_float()
			return val
