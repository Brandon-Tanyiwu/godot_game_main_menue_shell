extends Node

var NPC_data:Dictionary
var item_data:Dictionary 
@export var npc_level1:String
@export var npc_level2:String
var npc_list:Dictionary
var fish_list:Dictionary
var monster_list:Dictionary
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_data = GameDataManager.items
	NPC_data  = GameDataManager.npc
	#SignalManager.map_cal_completed.connect(NPC_Create)
	pass

func NPC_Create(seed_val,game_level)->void:
	print("start cal npc")
	var spawn_list:Array
	var noise = FastNoiseLite.new()
	noise.seed = seed_val
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.03
	var world_npc_cnt = 5 + (game_level*3)
	var gurd_probability = clamp(0.1 + (game_level*0.05),0.1,0.6)
	var current_spawned = 0
	var all_coords = HexMapManager.world_cells.keys()
	all_coords.shuffle()
	for coord in all_coords:
		
		if current_spawned >= world_npc_cnt:
			break
		var tile_data = HexMapManager.world_cells[coord]
		
		#if tile_data.cell_name not in ["深海","浅海"]:
			#continue
		
		var noise_val = noise.get_noise_2d(coord.x,coord.y)
		
		if noise_val >0.3 :
			var rand_val = randf()
			var npc_id:int = 1
			var npc_normal_config = _create_unit_by_id(npc_id)
			if rand_val < gurd_probability:
				npc_id = 3
			var npc_items:Array = _roll_loot_for_npc(npc_id,game_level)
			var spawn_data = {
				"id":npc_id
				,"coord":coord
				,"reward":npc_items
				,"config":npc_normal_config
			}
			spawn_list.append(spawn_data)
			npc_list[coord]=spawn_data
			current_spawned+=1
	SignalManager.npc_generation_completed.emit(spawn_list)
	

		
func _roll_loot_for_npc(npc_id:int,level:int) ->Array:
	
	var rolled_items:Array =[]
	var possible_loots = item_data.keys()
	if possible_loots.is_empty():
		return rolled_items
	var loot_count = randi_range(1,clamp(1+level,1,4))
	
	for i in range(loot_count):
		var random_item = possible_loots.pick_random()
		rolled_items.append(random_item)
	return rolled_items

func _create_unit_by_id(unit_id:int):
	if unit_id:
		return NPC_data[unit_id]

func _get_nearest_entity(unit:Node,group_name: String,find_unit_id:int) -> Vector2i:
	var entities : Dictionary
	match group_name:
		"NPC": entities=npc_list
	var target_coord:Vector2i
	var min_dist = INF
	for coord in entities.keys():
		if entities[coord]["id"]==find_unit_id:
			var dist =HexMapManager.get_hex_distance(unit.current_hex,coord)
			if dist < min_dist:
				min_dist = dist
				target_coord=coord
	return target_coord
