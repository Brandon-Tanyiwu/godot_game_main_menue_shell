extends Resource

class_name ItemData

@export var item_name: String
@export_multiline var description:String

@export var icon:Texture2D
@export var rarity:int = 0
@export var item_id:int
@export var base_price:int = 100
@export var price:int = 0
@export var max_stack:int = 99
@export var item_type:String
@export var x:int
@export var y:int
@export var attack:int = 0
@export var defense:int = 0 
@export var hp:int = 0
@export var tags:Array[String] = []
@export_multiline var special_effect:String
