extends Node2D

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

@onready var dialogue_box = $UI/HUD/DialogueBox



func _ready() -> void:
	GameState.start_level("pearl")
	_setup_camera()
	_connect_signals()
	
	LayerManager.layers.clear()
	for child in $Layers.get_children():
		if child.has_meta("layer_id"):
			LayerManager.layers.append(child)
	LayerManager._refresh_z_index()
	
	_shuffle_layers()
	
	await get_tree().process_frame
	print("=== 已注册图层数量：", LayerManager.get_layer_count(), " ===")
	for i in LayerManager.layers.size():
		var l = LayerManager.layers[i]
		print("  [", i, "] ", l.get_meta("layer_id", "无ID"))
	
	_trigger_stage_one_start()


func _setup_camera() -> void:
	$Camera2D.position = Vector2(640, 360)


func _connect_signals() -> void:
	EventBus.puzzle_stage_changed.connect(_on_puzzle_stage_changed)
	EventBus.layer_reordered.connect(_on_layer_reordered)


func _shuffle_layers() -> void:
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
	for monster_id in ["monster_blue", "monster_red", "monster_green", "monster_white"]:
		LayerManager.set_visible(monster_id, false)
	LayerManager.set_visible("tavern", false)
	for sea_id in ["sea_bg4", "lanternfish", "sea_layer5", "sea_layer6"]:
		LayerManager.set_visible(sea_id, false)
	LayerManager.set_visible("?", false)


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


func _trigger_stage_one_start() -> void:
	dialogue_box.show_dialogue([
		"欢迎。检测到图层顺序异常，请将它们恢复至正确位置。这是基础操作，应该难不倒你的。"
	])


func _trigger_stage_two_intro() -> void:
	dialogue_box.show_dialogue([
		"很好，顺序已恢复——",
		"……等一下。",
		"画面存在异常缺口。这、这不在我的工作手册里。",
		"好，冷静。你先用隐藏图层功能调查一下那些缺口，方法是点击图层旁边的眼睛图标。",
		"我去上报这个情况，很快回来。应该很快。大概。",
	], _start_guide_timer)


func _start_guide_timer() -> void:
	var timer = get_tree().create_timer(300.0)
	timer.timeout.connect(_guide_returns)


func _guide_returns() -> void:
	var bugs_cleared = true
	for monster_id in ["monster_blue", "monster_red", "monster_green", "monster_white"]:
		var layer = _find_layer(monster_id)
		if layer and layer.visible:
			bugs_cleared = false
			break
	
	if bugs_cleared:
		dialogue_box.show_dialogue([
			"我回来了——咦？",
			"缺口里的东西……消失了？",
			"你做的？",
			"这不在我的预期流程里。我需要记录一下。",
			"……总之，做得不错。下面我们来修补这些缺口。",
		])
	else:
		dialogue_box.show_dialogue([
			"我回来了。上面说这种情况他们也没见过，让我自己处理……",
			"没关系，交给我。",
			"好，处理完毕。下面我来教你修补这些缺口。",
		])


func _on_puzzle_stage_changed(stage: int) -> void:
	match stage:
		1:
			_show_holes()
			_reveal_sea_layers()
			_position_monsters()
			_reveal_monsters_in_panel()
			var panel = $UI/HUD/LayerPanel
			for sea_id in ["sea_bg4", "sea_layer5", "lanternfish", "sea_layer6"]:
				panel.show_layer_in_panel(sea_id)
			_trigger_stage_two_intro()
			LayerManager.set_visible("?", true)
			panel.show_layer_in_panel("?")
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
	var panel = $UI/HUD/LayerPanel
	if not panel:
		return
	for monster_id in ["monster_blue", "monster_red", "monster_green", "monster_white"]:
		panel.show_layer_in_panel(monster_id)
		



func _show_holes() -> void:
	var hole_layer = $UI/HoleLayer
	print("HoleLayer: ", hole_layer)
	if not hole_layer:
		print("找不到 HoleLayer！")
		return
	$UI/HoleLayer/HoleRed.visible = true
	$UI/HoleLayer/HoleBlue.visible = true
	$UI/HoleLayer/HoleGreen.visible = true
	$UI/HoleLayer/HoleWhite.visible = true

func _reveal_sea_layers() -> void:
	var sea_back_index = _get_layer_index("sea_back")
	LayerManager.set_visible("sea_back", false)
	
	var new_layers = ["sea_layer6", "sea_layer5", "sea_bg4", "lanternfish"]
	for i in new_layers.size():
		var layer = _find_layer(new_layers[i])
		if layer:
			LayerManager.set_visible(new_layers[i], true)
			LayerManager.reorder_layer(layer, sea_back_index + i)
			
func _position_monsters() -> void:
	var placements = {
		"monster_red": "sun",
		"monster_green": "coconut_tree",
		"monster_blue": "sea_layer5",
		"monster_white": "sea_front",
	}
	for monster_id in placements:
		var target_id = placements[monster_id]
		var target_index = _get_layer_index(target_id)
		var monster = _find_layer(monster_id)
		if monster and target_index != -1:
			LayerManager.reorder_layer(monster, target_index)
			# 强制刷新 CanvasLayer 显示状态
			monster.visible = false
			monster.visible = true
