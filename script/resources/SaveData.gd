extends Resource

class_name SaveData

@export var save_name:String = ""
@export var player_name:String = "Player"
@export var rank:String = '练气期'
@export var level:int = 1
@export var gold:int = 0

@export var hp:int = 100
@export var mp:int = 100
@export var defence: int = 20
@export var attack:int = 10
@export var criticalrate:float = 0.3
@export var criticaldamage:float = 2.00

@export var player_info:Dictionary = {}
@export var inventory:Dictionary = {}

@export var bag:Dictionary = {}

@export var warehouse:Dictionary = {}

@export var shop:Dictionary = {}

@export var equipped_items = []

@export var unlocked_skills:Array = []

@export var hex_map_info: Array[Dictionary] = []

@export var current_stage:int = 1
