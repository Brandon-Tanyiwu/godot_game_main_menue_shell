class_name MapNodeData
extends Resource

enum NodeType {
	START,
	BATTLE,
	ELITE,
	SHOP,
	TREASURE,
	EVENT,
	REST,
	BOSS
}

var id:int

# 地图中的位置
var position:Vector2

# 节点类型
var type:NodeType


# 后继节点
var next_nodes:Array[int] = []

# 前驱节点
var prev_nodes:Array[int] = []

# 状态
var visited:bool = false
var unlocked:bool = false

# 当前层
var layer:int = 0
