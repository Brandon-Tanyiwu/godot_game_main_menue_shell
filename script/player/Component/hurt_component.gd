extends Area2D
class_name HurtComponent

signal damaged(hit_data)

var attribute
var buff_component

func _ready():
	attribute = get_parent().get_node("AttributeComponent")
	buff_component = get_parent().get_node("BuffComponent")

func take_hit(hit_data):
	# 1. 计算最终伤害（可以调用Attribute）
	var damage = calculate_damage(hit_data)

	# 2. 应用数值
	attribute.take_damage(damage)

	# 3. 应用buff
	if hit_data.has("buff"):
		buff_component.add_buff(hit_data.buff)

	# 4. 发事件（关键）
	emit_signal("damaged", {
		"damage": damage,
		"source": hit_data.source
	})

func calculate_damage(hit_data):
	var defense = attribute.get_defense()
	return max(hit_data.damage - defense, 0)
