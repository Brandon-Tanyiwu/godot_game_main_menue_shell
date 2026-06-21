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

func delete_map(save_data:SaveData):
	if save_data:
		save_data.hex_map_info.clear()

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
	

func inspect_save_data_dependencies(data: Resource):
	print("\n================ 🩺 SaveData 依赖项深度体检 ================")
	if data == null:
		print("❌ 致命错误: 传入的 save_data 本身就是空的 (null)！")
		return
		
	# 1. 强制列出该资源在引擎底层记录的所有外部依赖路径
	var properties = data.get_property_list()
	
	for prop in properties:
		var prop_name = prop["name"]
		# 我们只关心你自己定义的业务变量，排除引擎自带变量
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value = data.get(prop_name)
			print("▶️ 检查类属性 -> [%s] 当前值类型: %s" % [prop_name, typeof_to_name(typeof(value))])
			
			# 如果属性是个字典（比如你的背包/仓库字典）
			if value is Dictionary:
				_scan_dictionary_dependencies(value)
			# 如果属性直接是一个子资源对象
			elif value is Resource:
				_validate_single_resource(value)
			# ❗ 抓贼：如果你误把场景里的节点（Node）存进去了
			elif value is Node:
				print("  ❌【致命错误】: 你把一个场景节点存进了属性 [%s] 里！节点是无法被 ResourceSaver 序列化的，这会导致保存崩溃！" % prop_name)

	print("=========================================================\n")

func _scan_dictionary_dependencies(dict: Dictionary):
	for key in dict:
		var val = dict[key]
		# 检查字典嵌套（比如背包格子里存的数据）
		if val is Dictionary:
			if val.has("item_id"):
				print("    - 格子 [%s] 内存放的物品 ID 为: %s" % [str(key), val["item_id"]])
			# 如果你在字典里直接存了整个 ItemData 对象
			for sub_k in val:
				if val[sub_k] is Resource:
					_validate_single_resource(val[sub_k])
				elif val[sub_k] is Node:
					print("    ❌【致命错误】: 字典格子 [%s] 的键 [%s] 对应的值是个 Node 节点！" % [str(key), sub_k])

func _validate_single_resource(res: Resource):
	if res.resource_path == "":
		print("    ⚠️ 警告: 存在一个没有物理路径的内存虚拟 Resource (可能是通过 .new() 动态创建且未保存的)")
	else:
		print("    |-- 子资源路径: ", res.resource_path)
		# 💡 核心检查：这个路径在硬盘上真的存在吗？
		if not FileAccess.file_exists(res.resource_path):
			print("    ❌【依赖项丢失】: 硬盘上找不到该资源文件！它可能被你删除、移动或改名了！")

# 辅助函数：把类型枚举转成好看的文字
func typeof_to_name(type_int: int) -> String:
	var types = ["Nil","bool","int","float","String","Vector2","Rect2","Vector3","Transform2D","Plane","Quaternion","AABB","Basis","Transform3D","Projection","Color","StringName","NodePath","RID","Object","Dictionary","Array"]
	return types[type_int] if type_int < types.size() else "Unknown"
