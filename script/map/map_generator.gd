class_name MapGenerator
extends Node

var graph := MapGraph.new()
var node_id:int = 0

func generate() -> MapGraph:
	randomize()
	var layers = []
	# 每层节点数量
	var layer_counts = [
		1,
		3,
		4,
		5,
		4,
		3,
		2,
		1
	]
	for layer in range(layer_counts.size()):
		var current_layer = []
		for i in range(layer_counts[layer]):
			var node = create_node(
				layer,
				i,
				layer_counts[layer]
			)

			graph.nodes[node.id] = node

			current_layer.append(node.id)

		layers.append(current_layer)
	connect_layers(layers)
	unlock_start_nodes(layers)
	return graph

func create_node(layer:int,index:int,count:int) -> MapNodeData:

	var node = MapNodeData.new()
	node.id = node_id
	node.layer = layer

	var spacing_x = 250
	var spacing_y = 220

	var offset =(count - 1) * spacing_x * 0.5

	node.position = Vector2(index * spacing_x - offset+ randf_range(-40, 40),
		layer * spacing_y
	)

	node.type = random_type(layer)

	# 起点
	if layer == 0:
		node.type =MapNodeData.NodeType.START

	# Boss
	if layer == 6:
		node.type =MapNodeData.NodeType.BOSS
	
	node_id += 1
	

	return node

func random_type(layer:int):
	var pool = [
		MapNodeData.NodeType.BATTLE,
		MapNodeData.NodeType.BATTLE,
		MapNodeData.NodeType.EVENT,
		MapNodeData.NodeType.TREASURE,
		MapNodeData.NodeType.SHOP
	]

	if layer >= 3:
		pool.append(
			MapNodeData.NodeType.ELITE
		)

	return pool.pick_random()

func connect_layers(layers: Array) -> void:
	for i in range(layers.size() - 1):
		var cur_layer: Array = layers[i]
		var next_layer: Array = layers[i + 1]
		
		if cur_layer.is_empty() or next_layer.is_empty():
			continue

		# 1. 第一层全连接（特殊业务保持原样）
		if i == 0:
			for from_id in cur_layer:
				for to_id in next_layer:
					connect_nodes(from_id, to_id)
			continue

		# 2. 第二层以下：用纯数学公式统一处理所有缩放情况
		var cur_size := cur_layer.size()
		var next_size := next_layer.size()
		
		# 核心：计算当前层到下一层的数量步长变化
		# 少变多时为 0，多变少时为 -1
		var offset := 0 if cur_size < next_size else -1

		for idx in range(cur_size):
			var from_id: int = cur_layer[idx]
			
			# 无论变多变少，每个节点都“尝试”连接两个目标位置
			# 通过 offset 自动完成错位转换
			var target_idx1 := idx + offset
			var target_idx2 := idx + offset + 1
			
			# 使用优化的边界检查，确保不越界
			if target_idx1 >= 0 and target_idx1 < next_size:
				connect_nodes(from_id, next_layer[target_idx1])
				
			if target_idx2 >= 0 and target_idx2 < next_size:
				connect_nodes(from_id, next_layer[target_idx2])

func connect_nodes(from_id:int,to_id:int):
	var from_node =graph.get_node(from_id)
	var to_node =graph.get_node(to_id)

	if to_id not in from_node.next_nodes:
		from_node.next_nodes.append(to_id)

	if from_id not in to_node.prev_nodes:
		to_node.prev_nodes.append(from_id)

func unlock_start_nodes(layers):
	var start_layer = layers[0]
	for node_id in start_layer:
		graph.get_node(node_id).unlocked = true
