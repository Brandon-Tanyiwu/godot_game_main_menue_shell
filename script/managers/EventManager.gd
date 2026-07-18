extends Node
var event_data:Dictionary
var game_map:Dictionary
var HexGame:Node
const CHARACTER_SCENE = preload("res://scenes/player/player.tscn")
const NPC_SCENE = preload("res://scenes/npc/npc.tscn")
func _ready() -> void:
	SignalManager.move_completed.connect(_is_event_action)
	SignalManager.cell_event_action.connect(action_event)
	event_data = GameDataManager.events
	#game_map = HexMapManager.map_save

func _setup(world)->void:
	HexGame=world

func _is_event_action(coord:Vector2i,unit:Node):
	var action_event = {}
	var cell_data = HexMapManager._get_coord_info(coord)
	var cell_event_id = cell_data["event_id"]
	print(event_data)
	var cell_event = event_data[cell_event_id]
	if cell_event["target_group"] =="All":
		action_event = cell_event
	elif cell_event["target_group"] in unit.get_groups():
		action_event = cell_event
	else:
		action_event = {}
	if action_event == {}:
		return
	SignalManager.cell_event_action.emit(cell_event,unit)

func action_event(cell_event:Dictionary,unit:Node):
	if event_data.is_empty():
		return
	match cell_event["event_type"]:
		"element_event":
			_unit_element_action(cell_event,unit)
		"split_unit":
			_split_unit(cell_event,unit)	
		"end_game":
			_enter_end_zone()


func _unit_element_action(cell_event:Dictionary,unit:Node)->void:
	unit.food += cell_event["food"]
	unit.current_hp += int(cell_event["hp"])
	unit.attack += int(cell_event["attack"])
	
func _split_unit(cell_event:Dictionary,unit:Node)->void:
	var coord_list=HexGame.get_cell_neighbors(unit.current_hex,1,1)
	var target_coord = coord_list.pick_random()
	var new_unit_item = []
	for i in range(len(unit.current_bag_data)):
		if i<=roundi(len(unit.current_bag_data)):
			new_unit_item.append(unit.current_bag_data[i])
			unit.current_bag_data.remove_at(i)
	HexGame._spawn_unit(target_coord,NPC_SCENE,unit.id,new_unit_item)
	print("触发分裂", target_coord)

func _enter_end_zone() ->void:
	HexGame._end_game()
	
	
