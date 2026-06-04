class_name MapNode
extends Node2D

signal node_clicked(node_id)

@export var sprite:Sprite2D
@export var label : Label

var data : MapNodeData

func setup(node_data:MapNodeData):

	data = node_data

	position = data.position

	label.text = str(data.id)

	update_visual()

func update_visual():

	match data.type:

		MapNodeData.NodeType.START:
			sprite.modulate = Color.GREEN

		MapNodeData.NodeType.BATTLE:
			sprite.modulate = Color.WHITE

		MapNodeData.NodeType.ELITE:
			sprite.modulate = Color.RED

		MapNodeData.NodeType.SHOP:
			sprite.modulate = Color.BLUE

		MapNodeData.NodeType.TREASURE:
			sprite.modulate = Color.YELLOW

		MapNodeData.NodeType.EVENT:
			sprite.modulate = Color.PURPLE

		MapNodeData.NodeType.REST:
			sprite.modulate = Color.CYAN

		MapNodeData.NodeType.BOSS:
			sprite.modulate = Color.DARK_RED

	# 未解锁变暗
	if !data.unlocked:
		modulate.a = 0.4
	else:
		modulate.a = 1.0

func _on_area_2d_input_event(viewport,event,shape_idx):

	if event is InputEventMouseButton:
		if event.pressed:
			print(data)
			if data.unlocked:
				emit_signal(
					"node_clicked",
					data.id)
