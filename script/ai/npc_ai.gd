class_name AIBrain
extends RefCounted


func think_next_action(npc_context:CharacterBody2D,game_map:Node2D)->Dictionary:
	return {"action":"Idle"}
