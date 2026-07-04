class_name NPCAILevel1
extends AIBrain

var roam_radius:int = 2

func think_next_action(npc_context:CharacterBody2D,game_map:Node2D)->Dictionary:
	if npc_context.current_resource<=0:
		return {"action":"Idle"}
	var walkable_tiles:Dictionary = game_map.get_cell_neighbors(npc_context.current_hex,npc_context.radius,npc_context.current_resource)
	if walkable_tiles.is_empty:
		return {"action":"Idle"}
	var target_tile = walkable_tiles.keys().pick_random()
	var path_data = game_map._ligal_hex_cell(npc_context.current_hex,target_tile,npc_context)
	if path_data.is_empty() or path_data["path"].is_empty():
		return {"action":"Idle"}
	return {
		"actuib":"Run"
		,"path_data":path_data
	}
#var walkable_tiles = grid_manager.get_walkable_tiles_in_radius(npc_context.current_tile, roam_radius)
	#walkable_tiles.erase(npc_context.current_tile) # 剔除自身
