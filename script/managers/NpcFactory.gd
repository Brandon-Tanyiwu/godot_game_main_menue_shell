extends Node

var NPC_data:Dictionary
var item_data:Dictionary 
@export var npc_level1:String
@export var npc_level2:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_data = GameDataManager.items
	NPC_data  = GameDataManager.fish
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
	var fish_probability = clamp(0.1 + (game_level*0.05),0.1,0.6)
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
			var npc_type=npc_level1
			var rand_val = randf()
			if rand_val < fish_probability:
				npc_type = npc_level2
			var npc_items:Array = _roll_loot_for_npc(npc_type,game_level)
			var spawn_data = {
				"id":1
				,"type":npc_type
				,"coord":coord
				,"reward":npc_items
			}
			spawn_list.append(spawn_data)
			current_spawned+=1
	print(spawn_list)
	SignalManager.npc_generation_completed.emit(spawn_list)
	
		
func _roll_loot_for_npc(npc_type:String,level:int) ->Array:
	
	var rolled_items:Array =[]
	var possible_loots = item_data.keys()
	if possible_loots.is_empty():
		return rolled_items
	var loot_count = randi_range(1,clamp(1+level,1,4))
	
	for i in range(loot_count):
		var random_item = possible_loots.pick_random()
		rolled_items.append(random_item)
	return rolled_items
