extends CanvasLayer

@onready var tooltip = $ItemTooltip

func _ready():
	tooltip.hide()

func show_item_tooltip(item_data: ItemData, global_pos: Vector2):
	if item_data == null: return
	tooltip.display_info(item_data)
	tooltip.global_position = global_pos + Vector2(20, 20)
	tooltip.show()

func hide_item_tooltip():
	tooltip.hide()
