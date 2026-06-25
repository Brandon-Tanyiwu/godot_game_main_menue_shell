# BuffData.gd
extends Resource
class_name BuffData

@export var name: String
@export var duration: float = 5.0
@export var tick_interval: float = 1.0

@export var attack_bonus: int = 0
@export var defense_bonus: int = 0

@export var dot_damage: int = 0  # 持续伤害
