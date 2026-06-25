# BuffComponent.gd
extends Node
class_name BuffComponent

var buffs = []

var attribute: AttributeComponent

func _ready():
	attribute = get_parent().get_node("AttributeComponent")

func add_buff(buff_data: BuffData):
	var buff = {
		"data": buff_data,
		"time_left": buff_data.duration,
		"tick_timer": 0.0
	}

	# 应用属性加成
	if buff_data.attack_bonus != 0:
		attribute.add_modifier("attack", buff_data.attack_bonus)

	if buff_data.defense_bonus != 0:
		attribute.add_modifier("defense", buff_data.defense_bonus)

	buffs.append(buff)

func _process(delta):
	for buff in buffs:
		buff.time_left -= delta
		buff.tick_timer += delta

		# DOT伤害
		if buff.data.dot_damage > 0 and buff.tick_timer >= buff.data.tick_interval:
			buff.tick_timer = 0
			attribute.take_damage(buff.data.dot_damage)

	# 清理过期buff
	for buff in buffs.duplicate():
		if buff.time_left <= 0:
			remove_buff(buff)

func remove_buff(buff):
	var data = buff.data

	if data.attack_bonus != 0:
		attribute.remove_modifier("attack", data.attack_bonus)

	if data.defense_bonus != 0:
		attribute.remove_modifier("defense", data.defense_bonus)

	buffs.erase(buff)
