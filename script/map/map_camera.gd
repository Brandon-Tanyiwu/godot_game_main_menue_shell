extends Camera2D

## 拖拽与缩放自适应策略相机
## 适用场景：大/小六边形网格地图，支持右键抓取、平滑滚轮缩放、全自动边界锁定
@export var terrain_layer: TileMapLayer # 在检查器中把你的地图图层拖进来



# 🔍 缩放阻尼配置
var target_zoom: float = 1.0
var zoom_speed: float = 0.15     # 每次滚轮滚动的缩放幅度
var max_zoom: float = 3.0        # 允许放大的最大倍数（拉得很近）
var min_zoom: float = 0.5        # 允许缩小的最小倍数（代码里会根据地图大小自动动态重写）

# ✋ 拖拽状态
var is_dragging: bool = false

func _ready() -> void:
	if terrain_layer:
		# 如果开局地图已经生成好了，直接锁定边界
		setup_camera_limits()

## 🌟 核心函数：根据地图实际像素大小，死死锁住相机的极限边缘
func setup_camera_limits() -> void:
	# 1. 获取地图当前已经使用了的网格矩形范围 (Rect2i)
	var used_rect = terrain_layer.get_used_rect()
	var tile_size = terrain_layer.tile_set.tile_size
	
	# 2. 将网格坐标转换为世界中的绝对全局像素坐标
	var top_left = terrain_layer.to_global(terrain_layer.map_to_local(used_rect.position)) - Vector2(tile_size) / 2.0
	var bottom_right = terrain_layer.to_global(terrain_layer.map_to_local(used_rect.end - Vector2i(1, 1))) + Vector2(tile_size) / 2.0
	
	# 3. 注入 Godot 相机原生边界锁（只要设置了这四个值，相机在拖拽时边缘绝对无法越界）
	limit_left = int(top_left.x)
	limit_top = int(top_left.y)
	limit_right = int(bottom_right.x)
	limit_bottom = int(bottom_right.y)
	
	# 4. 🧠 防穿帮核心：动态计算“极限缩小比例”
	# 如果不加限制地缩小，当视口大于地图时就会看到黑边。
	var map_pixel_size = bottom_right - top_left
	var viewport_size = get_viewport_rect().size
	
	var min_zoom_x = viewport_size.x / map_pixel_size.x
	var min_zoom_y = viewport_size.y / map_pixel_size.y
	
	# 取最大值：确保宽或高在缩到最小时，刚好顶满屏幕，绝不露出地图外
	min_zoom = max(min_zoom_x, min_zoom_y)
	
	# 兜底保护：防止初始缩放比例已经超标
	target_zoom = clamp(zoom.x, min_zoom, max_zoom)
	zoom = Vector2(target_zoom, target_zoom)

func _unhandled_input(event: InputEvent) -> void:
	# ==== 一、 鼠标滚轮控制放大/缩小 ====
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom += zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom -= zoom_speed
			
		# 严格限制缩放区间，不允许缩小到突破 min_zoom 看到外部边界
		target_zoom = clamp(target_zoom, min_zoom, max_zoom)
		
	# ==== 二、 鼠标右键抓取拖拽地图 ====
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_dragging = event.pressed

	if event is InputEventMouseMotion and is_dragging:
		# 💡 极其关键的公式：将鼠标像素位移取反并“除以当前的缩放倍数”
		# 这样可以保证你在极其贴近地图（放大）或纵览全局（缩小）时，鼠标抓取地图的拖拽感都是 100% 绝对跟手的
		global_position -= event.relative / zoom.x

func _process(delta: float) -> void:
	# 让缩放带有丝滑的阻尼动画感，15.0 是插值速度，数值越大缩放越硬、越小越顺滑
	if not is_equal_approx(zoom.x, target_zoom):
		var current_z = lerp(zoom.x, target_zoom, 15.0 * delta)
		zoom = Vector2(current_z, current_z)
