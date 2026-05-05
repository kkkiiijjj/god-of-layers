extends Node2D

# 正确的图层顺序，从下到上
# 每条规则：[下层id, 上层id]，表示前者必须在后者下面
const ORDER_RULES = [
	["sky", "sun"],
	["sky", "sunset"],
	["sky", "seagull"],
	["sunset", "seagull"],
	["sunset", "coconut_tree"],
	["sun", "sea_back"],
	["sea_back", "sea_front"],
	["beach", "sea_front"],
	["sea_back","beach"],
	["beach", "rock"],
	["beach", "coconut_tree"],
	["beach", "family"],
	["beach", "icecream"],
	["rock", "coconut_tree"],
]

func _ready() -> void:
	GameState.start_level("pearl")
	_setup_camera()
	_connect_signals()
	
	# 先按场景树顺序初始化
	LayerManager.layers.clear()
	for child in $Layers.get_children():
		if child.has_meta("layer_id"):
			LayerManager.layers.append(child)
	LayerManager._refresh_z_index()
	
	# 再打乱
	_shuffle_layers()
	
	await get_tree().process_frame
	print("=== 已注册图层数量：", LayerManager.get_layer_count(), " ===")
	for i in LayerManager.layers.size():
		var l = LayerManager.layers[i]
		print("  [", i, "] ", l.get_meta("layer_id", "无ID"), " z_index=", l.z_index)

func _setup_camera() -> void:
	$Camera2D.position = Vector2(640, 360)


func _connect_signals() -> void:
	EventBus.puzzle_stage_changed.connect(_on_puzzle_stage_changed)
	EventBus.layer_reordered.connect(_on_layer_reordered)


func _shuffle_layers() -> void:
	# 固定打乱顺序，index 0 = 最底层
	var shuffled_ids = [
		"sunset",
		"beach",
		"sea_back",
		"icecream",
		"seagull",
		"sun",
		"sky",
		"coconut_tree",
		"rock",
		"sea_front",
	]
	
	for i in shuffled_ids.size():
		var layer = _find_layer(shuffled_ids[i])
		if layer:
			LayerManager.reorder_layer(layer, i)

	# 怪物和酒馆初始隐藏
	for monster_id in ["monster_blue", "monster_red", "monster_green", "monster_white"]:
		LayerManager.set_visible(monster_id, false)
	LayerManager.set_visible("tavern", false)


func _on_layer_reordered() -> void:
	if GameState.current_stage == 0:
		_check_stage_one()


func _check_stage_one() -> void:
	for rule in ORDER_RULES:
		var lower_id = rule[0]
		var upper_id = rule[1]
		var lower_index = _get_layer_index(lower_id)
		var upper_index = _get_layer_index(upper_id)
		if lower_index == -1 or upper_index == -1:
			print("找不到图层：", lower_id, " 或 ", upper_id)
			return
		if lower_index >= upper_index:
			print("约束未满足：", lower_id, "(", lower_index, ") 应该在 ", upper_id, "(", upper_index, ") 下面")
			return
	print("阶段一完成！图层顺序正确")
	GameState.advance_stage()


func _get_layer_index(layer_id: String) -> int:
	for i in LayerManager.layers.size():
		if LayerManager.layers[i].get_meta("layer_id", "") == layer_id:
			return i
	return -1


func _find_layer(layer_id: String) -> Node:
	for layer in LayerManager.layers:
		if layer.get_meta("layer_id", "") == layer_id:
			return layer
	return null


func _on_puzzle_stage_changed(stage: int) -> void:
	match stage:
		1:
			print(">>> 进入阶段二：发现小怪物")
			# 怪物图层在面板里显示出来，但画面仍然隐藏
			_reveal_monsters_in_panel()
		2:
			print(">>> 进入阶段三：收集颜料")
		3:
			print(">>> 进入阶段四：珍珠线索")
		4:
			print(">>> 进入阶段五：解锁酒馆")
		5:
			_on_level_complete()
			


func _on_level_complete() -> void:
	GameState.complete_level()
	print("=== 关卡完成！===")
	
func _reveal_monsters_in_panel() -> void:
	print("执行 _reveal_monsters_in_panel")
	var panel = $UI/HUD/LayerPanel
	if not panel:
		print("找不到 LayerPanel！")
		return
	for monster_id in ["monster_blue", "monster_red", "monster_green", "monster_white"]:
		print("显示面板行：", monster_id)
		panel.show_layer_in_panel(monster_id)
