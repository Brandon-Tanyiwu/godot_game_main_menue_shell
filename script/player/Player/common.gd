
extends State
class_name CommonState

func _ready() -> void:
	SignalManager.player_attack_triggered.connect(get_hurt)



func physics_update(_delta: float) -> void:
	#if context.is_attack1_pressed():
		#request_transition("Attack1")
	#if context.is_attack2_pressed():
		#request_transition("Attack2")
	
	if context.current_hp<=0:
		request_transition("Death")
	if not context.animatecontroller.is_playing():
		request_transition("Idle")
		
func get_hurt(attack_unit,target_unit):
	
	if target_unit!=context:
		return
	if not context.hurt_cooldown:
		return	
	context.current_hurt =attack_unit.attack
	request_transition("Hurt")
	print("target get hurt",target_unit.name)
