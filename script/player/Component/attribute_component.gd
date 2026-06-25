extends Node
class_name AttributeComponent

signal hp_change(value)
signal died()

@export var base_hp:int = 100
@export var base_attack: int = 10
@export var base_defence: int = 5

var current_hp : int

var modifies = {
	"attack":[],
	"defence":[],
}

func _ready() -> void:
	current_hp = base_hp
	

func get_attack():
	return	apply_modifiers("attack",base_attack)

func get_defence():
	return apply_modifiers("defence",base_defence)
	
func take_damage(amount:int):
	current_hp -= amount
	emit_signal("hp_change",current_hp)
	
	if current_hp<=0:
		emit_signal("died")
		
func add_modifier(stat:String,value:float):
	modifies[stat].append(value)

func remove_modifiers( stat: String,value:float):
	modifies[stat].erase(value)
	
func apply_modifiers(stat:String,base:float)->float:
	var result = base
	
	for m in modifies[stat]:
		result += m
	return result
