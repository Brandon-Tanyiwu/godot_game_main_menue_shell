extends PanelContainer
class_name ItemToolTip
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var tags_container: HBoxContainer = $VBoxContainer/TagsContainer
@onready var description_label: Label = $VBoxContainer/DescriptionLabel

func _ready() -> void:
	hide()

func display_info(item:ItemData):
	if not item:
		hide()
		return
	name_label.text = item.item_name
	description_label.text = item.description
	
	for child in tags_container.get_children():
		child.queue_free()
	
	for tag in item.tags:
		var tag_label = Label.new()
		tag_label.text = "[" + tag + "]"
		tags_container.add_child(tag_label)
	
	show()
