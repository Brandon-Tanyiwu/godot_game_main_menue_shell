# state.gd
class_name State
extends Node

## 状态转换信号 - 传递意图而不是具体路径
signal transition_request(intent: String, params: Dictionary)

## 角色引用
#var character: CharacterBody2D
#var animator: AnimationPlayer
#var animation_tree: AnimationTree
var intent_handler_registered: bool
var register_intent_handler
var context
## 进入状态
func enter(_params: Dictionary = {}) -> void:
	pass

## 退出状态
func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

## 请求状态转换 - 子状态只需调用此方法
func request_transition(intent: String) -> void:
	transition_request.emit(intent)
