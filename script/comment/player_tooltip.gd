extends VBoxContainer
@onready var player: Sprite2D = $HBoxContainer/Player
@onready var title: Label = $Title/Label
@onready var rank: Label = $"Info/Rank&Level/Rank"
@onready var level: Label = $"Info/Rank&Level/Level"
@onready var hp: Label = $"Info/HP&MP/HP"
@onready var mp: Label = $"Info/HP&MP/MP"
@onready var defence: Label = $"Info/Defence&Attack/Defence"
@onready var attack: Label = $"Info/Defence&Attack/Attack"
@onready var critical_rate: Label = $"Info/CriticalRate&CriticalDamage/CriticalRate"
@onready var critical_damage: Label = $"Info/CriticalRate&CriticalDamage/CriticalDamage"

var user_info = SaveManager.current_save

func _ready() -> void:
	title.text= "角色属性"
	_on_ui_refresh()
	SignalManager.player_info_change.connect(_on_ui_refresh)


func _on_ui_refresh()->void:
	rank.text=user_info.rank
	level.text=str(user_info.level)
	hp.text = str(user_info.hp)
	mp.text = str(user_info.mp)
	defence.text = str(user_info.defence)
	attack.text = str(user_info.attack)
	critical_rate.text = str(user_info.criticalrate)
	critical_damage.text = str(user_info.criticaldamage)
	
	
	
