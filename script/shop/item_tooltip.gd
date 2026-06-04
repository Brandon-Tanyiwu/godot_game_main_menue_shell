extends Control

@onready var icon: TextureRect = $Icon
@onready var name_label: Label = $NameLabel
@onready var desc_label: Label = $DescLabel
@onready var stat_label: Label = $StatLabel
@onready var effect_label: Label = $EffectLabel

func setup(item:ItemData):
	icon.texture = item.icon
	name_label.text = item.item_name
	desc_label.text = item.description
	
	stat_label.text = \
		"ATK: %d\nDEF:%d\nHP:%d" %[
			item.attack
			,item.defense
			,item.hp]
	effect_label.text = item.special_effect
