extends Node

# 改为变量，以便在运行期间动态修改
var save_dir: String = "user://saves/"

var current_save: SaveData

func _ready() -> void:
	# 自动识别环境并切换路径
	if OS.has_feature("editor"):
		save_dir = "res://saves/"
		print("[存档系统] 当前为【测试环境】(编辑器)，使用路径: ", save_dir)
	else:
		save_dir = "user://saves/"
		print("[存档系统] 当前为【正式环境】(打包独立运行)，使用路径: ", save_dir)
	
	# 自动创建目录
	DirAccess.make_dir_absolute(save_dir)


func create_new_save(player_name: String):
	var save = SaveData.new()
	save.player_name = player_name
	
	# 这里建议统一使用二进制的 .res 或文本的 .tres
	save_game(save, "save_1.res")
	current_save = save


func save_game(save_data: SaveData, file_name: String):
	var err = ResourceSaver.save(save_data, save_dir + file_name)
	if err != OK:
		print("[存档系统] 保存失败，错误码：", err)


func load_game(file_name: String):
	var path = save_dir + file_name
	if not FileAccess.file_exists(path):
		print("[存档系统] 未找到存档文件: ", path)
		return null
		
	var data = ResourceLoader.load(path)
	current_save = data
	return data
	
	
func get_all_save():
	var result = []
	var dir = DirAccess.open(save_dir)
	
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			# 这里根据你实际使用的后缀（.res 或 .tres）进行判断
			if file.ends_with(".res") or file.ends_with(".tres"):
				result.append(file)
			
			file = dir.get_next()
	return result
	

func delete_save(file_name: String):
	DirAccess.remove_absolute(save_dir + file_name)
