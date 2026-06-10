extends Resource

class_name SaveData

@export var save_name:String = ""
@export var player_name:String = "Player"

@export var level:int = 1
@export var gold:int = 0

@export var hp:int = 100
@export var attack:int = 10

@export var inventory:Dictionary = {}

@export var bag:Dictionary = {}

@export var warehouse:Dictionary = {}

@export var shop:Dictionary = {}

@export var equipped_items = []

@export var unlocked_skills:Array = []

@export var current_stage:int = 1
