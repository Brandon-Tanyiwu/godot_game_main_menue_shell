class_name NPCBrain
extends Node

@export var npc_type: int = 1
@export var movement_speed: float = 100.0

# 距离常量（假设 1 格 = 64 像素，你可以根据你的网格大小调整 grid_size）
const GRID_SIZE: float = 64.0
const PIRATE_ESCAPE_DIST: float = 5.0 * GRID_SIZE
const PLAYER_DETECT_DIST: float = 5.0 * GRID_SIZE
const GUARD_DETECT_DIST: float = 10.0 * GRID_SIZE

# 外部依赖（需要由 NPC 宿主在 ready 时或过程中注入）
@export var host: CharacterBody2D # 宿主 NPC 自身
var world_map: Node # 用于获取港口、海岸线、实体位置的管理器

# 内部状态缓存
var normal_escape_turns_left: int = 0  # 普通NPC逃跑剩余回合数
var patrol_points: Vector2i
var current_patrol_index: int = 0
var merchant_random_target: Vector2 = Vector2.ZERO

func _ready() -> void:
	_initialize_ai()

func _initialize_ai() -> void:
	world_map=host.game_map
	# 初始化商人的随机目标
	if npc_type == 2:
		merchant_random_target = HexMapManager._get_random_cell()
	# 初始化守卫的海岸线巡逻点（模拟获取最近的海岸线两个端点）
	elif npc_type == 3:
		patrol_points = HexMapManager._get_nearest_coastline_points(host)

## 核心接口：每个回合或每帧调用，获取下一个移动目标点
func get_next_movement_target() -> Vector2:
	match npc_type:
		1:
			return _process_normal_npc()
		2:
			return _process_merchant_npc()
		3:
			return _process_guard_npc()
	return host.global_position

# ==================== 1. 普通 NPC 行为逻辑 ====================
func _process_normal_npc() -> Vector2:
	var my_pos = host.global_position
	var nearest_pirate = NpcFactory._get_nearest_entity(host,"pirates",1)
	var nearest_player = NpcFactory._get_nearest_entity(host,"pirates",1)
	var nearest_port = NpcFactory._get_nearest_entity(host,"pirates",1)

	# 1.1 检查海盗（逃逸优先级最高）
	if nearest_pirate and my_pos.distance_to(nearest_pirate.global_position) <= PIRATE_ESCAPE_DIST:
		# 激活逃跑状态：记录 1 个回合（这里可以用计时器或回合计数器表示）
		normal_escape_turns_left = 1 
		# 计算反方向逃离位置
		var escape_dir = (my_pos - nearest_pirate.global_position).normalized()
		return my_pos + escape_dir * GRID_SIZE * 2 # 向反方向逃跑2格
	
	# 如果处于“逃离一回合”的冷却中
	if normal_escape_turns_left > 0:
		# 这里假设调用此函数代表消耗了行动，递减冷却
		normal_escape_turns_left -= 1
		# 继续保持原有的逃跑方向移动
		return host.global_position + host.velocity.normalized() * GRID_SIZE

	# 1.2 检查玩家（出现玩家时会停止前进）
	if nearest_player and my_pos.distance_to(nearest_player.global_position) <= PLAYER_DETECT_DIST:
		return my_pos # 停止前进（目标设定为自身位置）

	# 1.3 默认行为：始终朝向最近的港口移动
	if nearest_port != Vector2.ZERO:
		return nearest_port
		
	return my_pos

# ==================== 2. 商人 NPC 行为逻辑 ====================
func _process_merchant_npc() -> Vector2:
	var my_pos = host.global_position
	var nearest_player = NpcFactory._get_nearest_entity(host,"players",1)

	# 2.1 玩家单位进入5格范围内时，向玩家移动
	if nearest_player and my_pos.distance_to(nearest_player.global_position) <= PLAYER_DETECT_DIST:
		return nearest_player.global_position

	# 2.2 永远在自由移动（到达随机点后重新生成）
	if my_pos.distance_to(merchant_random_target) < 10.0:
		merchant_random_target = HexMapManager._get_random_position()
		
	return merchant_random_target

# ==================== 3. 守卫 NPC 行为逻辑 ====================
func _process_guard_npc() -> Vector2:
	var my_pos = host.global_position
	var nearest_pirate = NpcFactory._get_nearest_entity(host,"pirates",1)

	# 3.1 当海盗进入10格范围内时追击
	if nearest_pirate and my_pos.distance_to(nearest_pirate.global_position) <= GUARD_DETECT_DIST:
		return nearest_pirate.global_position

	# 3.2 默认/海盗逃离死亡后：在海岸线附近反复巡逻
	if patrol_points:
		return patrol_points

	return my_pos
