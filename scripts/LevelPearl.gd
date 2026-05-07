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
@onready var layer_panel = $UI/HUD/LayerPanel
@onready var bubble_dialogue = $UI/HUD/BubbleDialogue
@onready var bubble_dialogue2 = $UI/HUD/BubbleDialogue2
var icecream_puzzle_done: bool = false

var watermelon_broken: bool = false
var family_bubble_shown: bool = false
var brush_unlocked: bool = false


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


func _process(_delta: float) -> void:
	if not layer_panel.eraser_mode:
		return
	if Input.is_action_just_pressed("mouse_left"):
		_on_eraser_activated()


func _setup_camera() -> void:
	$Camera2D.position = Vector2(640, 360)


func _connect_signals() -> void:
	EventBus.puzzle_stage_changed.connect(_on_puzzle_stage_changed)
	EventBus.layer_reordered.connect(_on_layer_reordered)
	EventBus.layer_reordered.connect(_check_watermelon_puzzle)
	EventBus.layer_reordered.connect(_check_family_bubble)
	EventBus.layer_visibility_changed.connect(_on_layer_visibility_changed_check)
	EventBus.layer_reordered.connect(_check_icecream_puzzle)


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
	LayerManager.set_visible("stone", false)
	LayerManager.set_visible("watermelon", false)
	LayerManager.set_visible("watermelon_open", false)
	LayerManager.set_visible("history", false)
	LayerManager.set_visible("fam_buy_ice", false)


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
	var timer = get_tree().create_timer(10.0)
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
			"哦？",
			"您已经找到橡皮擦了。",
			"……这届比上一届聪明。那个本来是之后的教学内容的。",
			"看来我得把它藏得更隐蔽一些。记录在案。",
			"不过，它们留下的这些缺口……我的数据库里没有任何相关记录。",
			"这种损伤从未出现过。也许只有您能处理——毕竟，您来自我们创造者的族群。",
		], _unlock_brush)
	else:
		dialogue_box.show_dialogue([
			"我回来了。上面说这种情况他们也没见过，让我自己处理……",
			"没关系，交给我。",
		], _guide_clear_bugs)


func _guide_clear_bugs() -> void:
	for monster_id in ["monster_blue", "monster_red", "monster_green", "monster_white"]:
		LayerManager.set_visible(monster_id, false)
		if layer_panel.layer_buttons.has(monster_id):
			layer_panel.layer_buttons[monster_id].visible = false
	dialogue_box.show_dialogue([
		"处理完毕。",
		"它们留下的这些缺口……我的数据库里没有任何相关记录。",
		"这种损伤从未出现过。也许只有您能处理——毕竟，您来自我们创造者的族群。",
	], _unlock_brush)


func _check_all_bugs_cleared() -> void:
	dialogue_box.show_dialogue([
		"哦？",
		"您已经找到橡皮擦了。",
		"……这届比上一届聪明。那个本来是之后的教学内容的。",
		"看来我得把它藏得更隐蔽一些。记录在案。",
		"不过，它们留下的这些缺口……我的数据库里没有任何相关记录。",
		"这种损伤从未出现过。也许只有您能处理——毕竟，您来自我们创造者的族群。",
	], _unlock_brush)


func _unlock_brush() -> void:
	brush_unlocked = true
	dialogue_box.show_dialogue([
		"这支画笔交给您。",
		"看到画面中的椰子了吗？画笔会自动吸取颜料并填补对应的漏洞。",
	], _fill_white_hole)


func _fill_white_hole() -> void:
	$UI/HoleLayer/HoleWhite.visible = false
	GameState.collect_paint("white")
	print("白色漏洞已填补！")


func _on_eraser_activated() -> void:
	var cover_layers = ["sun", "coconut_tree", "sea_layer5", "sea_front"]
	for lid in cover_layers:
		var layer = _find_layer(lid)
		if layer and layer.visible:
			return
	_clear_all_bugs()


func _clear_all_bugs() -> void:
	for monster_id in ["monster_blue", "monster_red", "monster_green", "monster_white"]:
		LayerManager.set_visible(monster_id, false)
		if layer_panel.layer_buttons.has(monster_id):
			layer_panel.layer_buttons[monster_id].visible = false
	layer_panel.eraser_mode = false
	layer_panel.eraser_btn.modulate = Color.WHITE
	_check_all_bugs_cleared()


func _on_puzzle_stage_changed(stage: int) -> void:
	match stage:
		1:
			_show_holes()
			_reveal_sea_layers()
			_position_monsters()
			_reveal_monsters_in_panel()
			for sea_id in ["sea_bg4", "sea_layer5", "lanternfish", "sea_layer6"]:
				layer_panel.show_layer_in_panel(sea_id)
			_trigger_stage_two_intro()
			LayerManager.set_visible("?", true)
			layer_panel.show_layer_in_panel("?")
			LayerManager.set_visible("stone", true)
			LayerManager.set_visible("watermelon", true)
			layer_panel.show_layer_in_panel("stone")
			layer_panel.show_layer_in_panel("watermelon")
			var sea_bg4_idx = _get_layer_index("sea_bg4")
			var stone_layer = _find_layer("stone")
			if stone_layer:
				LayerManager.reorder_layer(stone_layer, sea_bg4_idx - 1)
			LayerManager.set_visible("history", true)
			layer_panel.show_layer_in_panel("history")
			# history 放到 icecream 下层
			var icecream_idx = _get_layer_index("icecream")
			var history_layer = _find_layer("history")
			if history_layer:
				LayerManager.reorder_layer(history_layer, icecream_idx - 1)
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
	for monster_id in ["monster_blue", "monster_red", "monster_green", "monster_white"]:
		layer_panel.show_layer_in_panel(monster_id)


func _show_holes() -> void:
	var hole_layer = $UI/HoleLayer
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
			monster.visible = false
			monster.visible = true


func _check_family_bubble() -> void:
	if GameState.current_stage != 1:
		return
	if not brush_unlocked:
		return
	if family_bubble_shown:
		return
	var family_layer = _find_layer("family")
	if not family_layer or not family_layer.visible:
		return
	var family_index = _get_layer_index("family")
	var must_be_below = ["sea_layer6", "sea_layer5", "sea_bg4", "lanternfish", "beach", "sea_front"]
	for lid in must_be_below:
		var idx = _get_layer_index(lid)
		if idx == -1:
			continue
		if idx >= family_index:
			return
	family_bubble_shown = true
	bubble_dialogue.show_bubble("买了西瓜但是没有刀，怎么打开呢？", Vector2(400, 300))


func _check_watermelon_puzzle() -> void:
	if GameState.current_stage != 1:
		return
	if watermelon_broken:
		return
	var stone_index = _get_layer_index("stone")
	var watermelon_index = _get_layer_index("watermelon")
	if stone_index == -1 or watermelon_index == -1:
		return
	if stone_index == watermelon_index + 1:
		watermelon_broken = true
		bubble_dialogue.show_bubble("有了，就用那个石头砸开吧！", Vector2(400, 300))
		await get_tree().create_timer(2.0).timeout
		_trigger_watermelon_break()


func _trigger_watermelon_break() -> void:
	bubble_dialogue.hide_bubble()
	LayerManager.set_visible("watermelon", false)
	LayerManager.set_visible("watermelon_open", true)
	layer_panel.show_layer_in_panel("watermelon_open")
	LayerManager.set_visible("stone", false)
	if layer_panel.layer_buttons.has("stone"):
		layer_panel.layer_buttons["stone"].visible = false
	$UI/HoleLayer/HoleRed.visible = false
	GameState.collect_paint("red")
	print("红色漏洞已填补！")
	_show_watermelon_done_bubble()


func _on_layer_visibility_changed_check(_layer_id: String, _visible: bool) -> void:
	_check_family_bubble()


func _show_watermelon_done_bubble() -> void:
	bubble_dialogue.show_bubble("太好了，有西瓜吃了。", Vector2(300, 350))
	bubble_dialogue2.show_bubble("我不想吃西瓜，我想吃冰淇淋。", Vector2(500, 350))
	await get_tree().create_timer(3.0).timeout
	bubble_dialogue.show_bubble("冰淇淋太贵了，回家再给你买。", Vector2(300, 350))
	bubble_dialogue2.hide_bubble()
	await get_tree().create_timer(3.0).timeout
	bubble_dialogue.hide_bubble()


func _check_icecream_puzzle() -> void:
	if GameState.current_stage != 1:
		return
	if icecream_puzzle_done:
		return
	if not brush_unlocked:
		return
	var history_index = _get_layer_index("history")
	var icecream_index = _get_layer_index("icecream")
	if history_index == -1 or icecream_index == -1:
		return
	if history_index == icecream_index + 1:
		icecream_puzzle_done = true
		_trigger_icecream_puzzle()


func _trigger_icecream_puzzle() -> void:
	bubble_dialogue.hide_bubble()
	bubble_dialogue2.hide_bubble()
	bubble_dialogue.show_bubble("爸爸你看，冰淇淋降价了！", Vector2(500, 350))
	await get_tree().create_timer(2.0).timeout
	bubble_dialogue2.show_bubble("好吧，那给你买一个。", Vector2(300, 350))
	await get_tree().create_timer(2.0).timeout
	bubble_dialogue.hide_bubble()
	bubble_dialogue2.hide_bubble()
	# 替换 family 为 fam_buy_ice
	LayerManager.set_visible("family", false)
	LayerManager.set_visible("fam_buy_ice", true)
	layer_panel.show_layer_in_panel("fam_buy_ice")
	if layer_panel.layer_buttons.has("family"):
		layer_panel.layer_buttons["family"].visible = false
	# 填补绿色漏洞
	$UI/HoleLayer/HoleGreen.visible = false
	GameState.collect_paint("green")
	print("绿色漏洞已填补！")
