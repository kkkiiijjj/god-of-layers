extends Node2D


func _ready() -> void:
	GameState.start_level("pearl")
	_setup_camera()
	_connect_signals()
	
	# 调试：打印所有已注册图层
	await get_tree().process_frame
	print("=== 已注册图层数量：", LayerManager.get_layer_count(), " ===")
	for i in LayerManager.layers.size():
		var l = LayerManager.layers[i]
		print("  [", i, "] ", l.get_meta("layer_id", "无ID"))


func _setup_camera() -> void:
	$Camera2D.position = Vector2(640, 360)  # 画面中心


# 后续阶段推进逻辑都从这里扩展
func _on_puzzle_stage_changed(stage: int) -> void:
	match stage:
		1:
			print("阶段一完成：图层整理")
		2:
			print("阶段二完成：发现小怪物")
		3:
			print("阶段三完成：颜料收集完毕")
		4:
			print("阶段四完成：珍珠线索齐全")
		5:
			_on_level_complete()


func _on_level_complete() -> void:
	GameState.complete_level()


func _connect_signals() -> void:
	EventBus.puzzle_stage_changed.connect(_on_puzzle_stage_changed)
