# walk_state.gd（行走状态）
extends State
class_name Run
var speed: float = 300.0

func _ready() -> void:
	pass
func enter(_params: Dictionary = {}) -> void:
	move_along_path(context.pending_path,context.terrain_layer)
	if context:
		context.animatecontroller.play("Run")


func exit() -> void:
	if context:
		context.animatecontroller.stop()


func move_along_path(path_data:Dictionary,terrain_layer) -> void:
	if path_data.is_empty():
		return
	# 遍历路径中的每一个六边形网格坐标
	var path = path_data["path"]
	
	for next_hex in path:
		print("下一个位置:",next_hex.keys()[0])
		var hex_coord = next_hex.keys()[0]
		var hex_cost:int = next_hex[hex_coord]
		# 1. 先把网格坐标换算成地图图层的本地像素
		if context.current_resource<hex_cost:
			print("no more power!")
			return 
		context.current_resource -=hex_cost
		var local_pixel_pos = terrain_layer.map_to_local(hex_coord)
		var target_global_pos = terrain_layer.to_global(local_pixel_pos)
		
		# 2. 🌟 转向逻辑：根据下一格在左边还是右边，自动翻转图片
		if target_global_pos.x > context.global_position.x:
			context.animatecontroller.set_direction(1)
		elif target_global_pos.x < context.global_position.x:
			context.animatecontroller.set_direction(0)
		
		# 3. 让角色移动到这个全局像素点
		# 如果你是瞬间移动，直接赋值 global_position：
		#global_position = target_global_pos
		# 💡 如果你使用的是 Tween 动画平滑移动，请确保使用的是 "global_position" 属性：
		var tween = context.create_tween()
		tween.tween_property(context, "global_position", target_global_pos, context.move_sconds)
		await tween.finished
		
		# 4. 🌟 实时更新当前网格坐标：每走完一格，就把 current_hex 刷新为当前所在的格子
		context.current_hex = hex_coord
		SignalManager.move_completed.emit(hex_coord,self)
		SignalManager.request_reveal_fog.emit(context.current_hex,context.vision_radius)
	context.move_intent.x=0
