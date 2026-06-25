# state_machine.gd
class_name StateMachine
extends Node

## 初始状态
@export var initial_state: State
@export var common_state:State
## 当前状态
var current_state: State = null
## 状态字典（节点：节点名称）
var states: Dictionary = {}
## 状态路径映射（意图映射表，由父状态注册）
var intent_handlers: Dictionary = {}

var context

func _ready() -> void:
	
	_collect_states(self)
	_register_intent_handlers()
	
	
	if initial_state and initial_state is State:
		current_state = states[initial_state.name]
		current_state.enter()
	else:
		push_error("未指定初始意图", self,initial_state)

func _process(delta: float) -> void:
	if common_state:
		common_state.update(delta)
	if current_state:
		var chain = _get_ancestors(current_state)
		for state in chain:
			state.update(delta)

func _physics_process(delta: float) -> void:
	if common_state:
		common_state.physics_update(delta)
	if current_state:
		var chain = _get_ancestors(current_state)
		for state in chain:
			state.physics_update(delta)
		



## 收集所有状态节点
func _collect_states(parent: Node) -> void:
	self.context=owner
	for child in parent.get_children():
		if child is State:
			states[child.name] = child
			child.context = owner
			child.transition_request.connect(_on_transition_request)
		_collect_states(child)


## 注册意图处理器（由状态机注册）
func _register_intent_handlers() -> void:
	intent_handlers.clear()
	_scan_intent_tree(self)
	

##递归场景树
func _scan_intent_tree(node: Node) -> void:
	for child in node.get_children():

		if child is State:
			_register_intents(child)
			_scan_intent_tree(child)

##注册意图
func _register_intents(parent_state: State) -> void:
	
	for child in parent_state.get_children():
		
		if not (child is State):
			continue
		
		var intent_name := child.name  # 💥 核心：name = intent
		var key :String = intent_name
		
		intent_handlers[key] = {
			"priority": _get_intent_priority(child.name), # 默认值，后面由 Player 注入
			"handler_state": child.get_parent().name
		}


##获取意图的优先级
func _get_intent_priority(intent_name: String) -> int:
	if context:
		var dict = context.intent_priority
		return dict[intent_name]
	else:
		return 0
	


## 处理转换请求
func _on_transition_request(intent: String) -> void:
	if current_state==states.get(intent):
		return
	var intent_handle: String = intent_handlers.get(intent,{}).get("handler_state")
	var old_hander: String = intent_handlers.get(current_state.name,{}).get("handler_state")
	var new_state: State = states.get(intent)
	var old_handler_state:State = states.get(old_hander)
	var new_handler_state:State = states.get(intent_handle)
	if old_hander== intent_handle:
		current_state.exit()
		new_state.enter()
		current_state=new_state
	else	:
		old_handler_state.exit()
		current_state.exit()
		new_handler_state.enter()
		new_state.enter()
		current_state=new_state
	
	
func _is_pending_intent(from_state,intent) ->bool:
	var old_intent_priority:int = intent_handlers.get(from_state.name,{}).get("priority")
	var new_intent_priority:int = intent_handlers.get(intent.name,{}).get("priority")
	return old_intent_priority>new_intent_priority
	
	
	
## 获取状态的所有祖先
func _get_ancestors(state: State) -> Array[State]:
	var ancestors: Array[State] = []
	var current: Node = state
	while current != self and current != null:
		if current is State:
			ancestors.insert(0, current)
		current = current.get_parent()
	return ancestors

## 查找最近共同祖先
func _find_common_ancestor(ancestors_a: Array[State], ancestors_b: Array[State]) -> State:
	var min_size = min(ancestors_a.size(), ancestors_b.size())
	for i in range(min_size):
		if ancestors_a[i] != ancestors_b[i]:
			return ancestors_a[i - 1] if i > 0 else null
	return ancestors_a[min_size - 1] if min_size > 0 else null

## 查找父节点
func _find_character_parent() -> CharacterBody2D:
	var node: Node = get_parent()
	while node:
		if node is CharacterBody2D:
			return node
		node = node.get_parent()
	return null


## 获取当前状态（供外部调用）
func get_current_state() -> State:
	return current_state
