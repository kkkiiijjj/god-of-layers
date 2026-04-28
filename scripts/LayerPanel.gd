extends PanelContainer

# 每个图层对应一个按钮行
var layer_buttons: Dictionary = {}


func _ready() -> void:
	# 等一帧让 LayerManager 注册完所有图层
	await get_tree().process_frame
	_build_panel()
	EventBus.layer_reordered.connect(_rebuild_panel)


func _build_panel() -> void:
	var vbox = $VBoxContainer
	
	# 清空旧按钮（重建时用）
	for child in vbox.get_children():
		if child.name != "Title":
			child.queue_free()
	layer_buttons.clear()
	
	# 从上到下显示图层（最上层在面板顶部）
	var layers_reversed = LayerManager.layers.duplicate()
	layers_reversed.reverse()
	
	for layer in layers_reversed:
		var layer_id = layer.get_meta("layer_id", "")
		var row = _create_layer_row(layer, layer_id)
		vbox.add_child(row)


func _create_layer_row(layer: Node, layer_id: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.set_meta("layer_id", layer_id)
	
	# 眼睛按钮（显示/隐藏）
	var eye_btn = Button.new()
	eye_btn.text = "👁"
	eye_btn.toggle_mode = true
	eye_btn.button_pressed = true
	eye_btn.pressed.connect(func():
		LayerManager.set_visible(layer_id, eye_btn.button_pressed)
	)
	
	# 图层名称标签
	var label = Label.new()
	label.text = layer.get_meta("layer_id", layer_id)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	row.add_child(eye_btn)
	row.add_child(label)
	layer_buttons[layer_id] = row
	return row


func _rebuild_panel() -> void:
	_build_panel()
