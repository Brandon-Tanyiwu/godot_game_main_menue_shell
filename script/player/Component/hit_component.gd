extends Area2D

class_name HitComponent

@export var damage: int = 10
@export var knockback_force: float = 200.0
@export var team: int = 0 #阵营判断，剔除友伤

var  owner_body: Node = null	

func _ready() -> void:
	owner_body = get_parent()
	connect("area_entered",_on_area_entered)
	

func _on_area_entered(area: Area2D):
	if not area is HurtComponent:
		return
	if area.team == team:
		return
	
	var direction = (area.global_position - global_position).normalized()
	
	area.take_hit(
		{"damage":damage,
		"knockback":direction * knockback_force,
		"source":owner_body,
		}
	)
	
	
	
