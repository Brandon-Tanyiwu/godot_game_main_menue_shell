extends Camera2D

var dragging := false
var last_mouse_pos := Vector2.ZERO

var zoom_speed := 0.1

func _ready():

	enabled = true

func _unhandled_input(event):

	# 鼠标拖拽
	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_MIDDLE:

			dragging = event.pressed

			last_mouse_pos =get_global_mouse_position()

		# 缩放
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:

			zoom -= Vector2.ONE * zoom_speed

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:

			zoom += Vector2.ONE * zoom_speed

		zoom.x = clamp(zoom.x, 0.5, 2.0)
		zoom.y = clamp(zoom.y, 0.5, 2.0)

	# 拖动
	elif event is InputEventMouseMotion:

		if dragging:

			var current_mouse =get_global_mouse_position()

			var delta =last_mouse_pos - current_mouse

			position += delta

			last_mouse_pos = current_mouse
