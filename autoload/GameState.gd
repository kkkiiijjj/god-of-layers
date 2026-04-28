extends Node

# 当前关卡
var current_level: String = ""

# 已完成的关卡列表（用于画廊显示）
var completed_levels: Array[String] = []

# 当前谜题阶段
var current_stage: int = 0

# 珍珠关：已收集的颜料
var collected_paints: Array[String] = []

# 珍珠关：已解锁的图层
var unlocked_layers: Array[String] = []


func start_level(level_id: String) -> void:
	current_level = level_id
	current_stage = 0
	collected_paints.clear()
	unlocked_layers.clear()


func advance_stage() -> void:
	current_stage += 1
	EventBus.puzzle_stage_changed.emit(current_stage)


func collect_paint(color: String) -> void:
	if color not in collected_paints:
		collected_paints.append(color)
	_check_stage_completion()


func unlock_layer(layer_id: String) -> void:
	if layer_id not in unlocked_layers:
		unlocked_layers.append(layer_id)


func complete_level() -> void:
	if current_level not in completed_levels:
		completed_levels.append(current_level)
	EventBus.puzzle_completed.emit()


func _check_stage_completion() -> void:
	# 四种颜料都收集后推进阶段
	var all_paints = ["white", "red", "green", "blue"]
	if all_paints.all(func(p): return p in collected_paints):
		advance_stage()
