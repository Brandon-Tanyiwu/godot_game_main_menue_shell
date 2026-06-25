# AnimateController.gd
extends Node
class_name AnimateController

# ----------------------------
# ---- 动画节点引用 ----
# ----------------------------
@export var animated_sprite_2d: AnimatedSprite2D

# 当前正在播放的动画名
var current_animation: String = ""

# ----------------------------
# ---- 播放动画接口 ----
# ----------------------------
func play(anim_name: String) -> void:
	if not animated_sprite_2d:
		push_warning("AnimateController: animated_sprite_2d not assigned")
		return

	# 如果动画和当前一样，就不重复播放
	if current_animation == anim_name:
		return
	if animated_sprite_2d.sprite_frames.has_animation(anim_name):
		animated_sprite_2d.play(anim_name)
		current_animation = anim_name
	else:
		push_warning("AnimateController: animation '%s' not found" % anim_name)

func set_direction(dir:float) -> void:
	if not animated_sprite_2d:
		return
	
	if dir > 0 :
		animated_sprite_2d.flip_h=false
	elif dir<0 :
		animated_sprite_2d.flip_h=true

# ----------------------------
# ---- 停止动画接口 ----
# ----------------------------
func stop() -> void:
	if animated_sprite_2d:
		animated_sprite_2d.stop()
		current_animation = ""

# ----------------------------
# ---- 设置动画速度 ----
# ----------------------------
func set_speed(speed: float) -> void:
	if animated_sprite_2d:
		animated_sprite_2d.speed_scale = speed

# ----------------------------
# ---- 判断当前动画 ----
# ----------------------------
func is_playing() -> bool:
	return animated_sprite_2d.is_playing()
