extends State
class_name Hurt
func _ready() -> void:
	pass
func enter(_params: Dictionary = {}) -> void:
	if context:
		context.animatecontroller.play("Hurt")
	cal_hurt_result()
	

func exit() -> void:
	if context:
		context.animatecontroller.stop()
	context.hurt_cooldown = true

func cal_hurt_result()->void:
	context.current_hp -=context.current_hurt
	print(context.current_hp)
