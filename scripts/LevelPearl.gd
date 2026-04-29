extends Node2D

# 正确的图层顺序，从下到上
const CORRECT_ORDER = [
	"underwater",  # 0 最底层
	"monster_blue",  # 藏在海底和海浪之间
	"wave",
	"monster_red",   # 藏在海浪和沙滩之间
	"beach",
	"monster_green", # 藏在沙滩和远海之间
	"sea_far",
	"monster_white", # 藏在远海和天空之间
	"sky",           # 最顶层
	"tavern",        # 酒馆初始隐藏，暂时放最上面
]

func _ready() -> void:
	GameState.start_level("pearl")
	_setup_camera()
	_connect_signals()
	_shuffle_layers()

	await get_tree().process_frame
	print("=== 已注册图层数量：", LayerManager.get_layer_count(), " ===")
	for i in LayerManager.layers.size():
		var l = LayerManager.layers[i]
		print("  [", i, "] ", l.get_meta("layer_id", "无ID"))


func _setup_camera() -> void:
	$Camera2D.position = Vector2(640, 360)


func _connect_signals() -> void:
	EventBus.puzzle_stage_changed.connect(_on_puzzle_stage_changed)
	EventBus.layer_reordered.connect(_on_layer_reordered)


func _shuffle_layers() -> void:
	# 只打乱背景图层，怪物图层初始隐藏
	var bg_ids = ["underwater", "wave", "beach", "sea_far", "sky"]
	bg_ids.shuffle()
	for i in bg_ids.size():
		var layer = _find_layer(bg_ids[i])
		if layer:
			LayerManager.reorder_layer(layer, i)

	# 怪物图层初始隐藏
	for monster_id in ["monster_blue", "monster_red", "monster_green", "monster_white"]:
		LayerManager.set_visible(monster_id, false)

	# 酒馆初始隐藏
	LayerManager.set_visible("tavern", false)


func _on_layer_reordered() -> void:
	if GameState.current_stage == 0:
		_check_stage_one()


func _check_stage_one() -> void:
	var bg_correct = ["underwater", "wave", "beach", "sea_far", "sky"]
	var bg_actual = []
	for layer in LayerManager.layers:
		var lid = layer.get_meta("layer_id", "")
		if lid in bg_correct:
			bg_actual.append(lid)

	if bg_actual == bg_correct:
		print("阶段一完成！图层顺序正确")
		GameState.advance_stage()


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
