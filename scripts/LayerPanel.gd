extends PanelContainer

var layer_buttons: Dictionary = {}
var dragging_id: String = ""
var drag_preview: Control = null
var drop_indicator: Control = null
var is_dragging: bool = false
var insert_index: int = -1 


func _ready() -> void:
	await get_tree().process_frame
	_build_panel()
	_create_drop_indicator()
	EventBus.layer_reordered.connect(_rebuild_panel)


func _create_drop_indicator() -> void:
	drop_indicator = ColorRect.new()
	drop_indicator.color = Color(0.2, 0.6, 1.0, 0.9)
	drop_indicator.custom_minimum_size = Vector2(180, 3)
	drop_indicator.visible = false
	drop_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$VBoxContainer.add_child(drop_indicator)


func _build_panel() -> void:
	var vbox = $VBoxContainer
	for child in vbox.get_children():
		if child.name != "Title" and child != drop_indicator:
			child.queue_free()
	layer_buttons.clear()

	var layers_reversed = LayerManager.layers.duplicate()
	layers_reversed.reverse()

	for layer in layers_reversed:
		var layer_id = layer.get_meta("layer_id", "")
		var row = _create_layer_row(layer, layer_id)
		vbox.add_child(row)


func _create_layer_row(layer: Node, layer_id: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.set_meta("layer_id", layer_id)
	row.custom_minimum_size = Vector2(180, 40)

	# 拖拽把手
	var handle = Label.new()
	handle.text = "⠿"
	handle.custom_minimum_size = Vector2(24, 0)
	handle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.gui_input.connect(func(event):
		_on_handle_input(event, layer_id)
	)

	# 眼睛按钮
	var eye_btn = Button.new()
	eye_btn.text = "👁"
	eye_btn.toggle_mode = true
	eye_btn.button_pressed = true
	eye_btn.custom_minimum_size = Vector2(32, 0)
	eye_btn.toggled.connect(func(pressed: bool):
		LayerManager.set_visible(layer_id, pressed)
		eye_btn.text = "👁" if pressed else "🙈"
		eye_btn.modulate = Color.WHITE if pressed else Color(1, 1, 1, 0.4)
	)

	# 图层名称
	var label = Label.new()
	label.text = layer_id
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	row.add_child(handle)
	row.add_child(eye_btn)
	row.add_child(label)
	layer_buttons[layer_id] = row
	return row


func _on_handle_input(event: InputEvent, layer_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_id = layer_id
			is_dragging = true
			_show_drag_preview(layer_id)
		else:
			_end_drag()


func _process(_delta: float) -> void:
	if not is_dragging:
		return

	if drag_preview:
		drag_preview.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)

	_update_drop_indicator()

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_drag()


func _update_drop_indicator() -> void:
	var vbox = $VBoxContainer
	var mouse_pos = vbox.get_local_mouse_position()
	var rows = []
	for child in vbox.get_children():
		if child.name != "Title" and child != drop_indicator:
			rows.append(child)

	insert_index = rows.size()  # 默认插入到最底部

	for i in rows.size():
		var child = rows[i]
		var child_mid = child.position.y + child.size.y / 2.0
		if mouse_pos.y < child_mid:
			insert_index = i
			break

	# 计算蓝线 y 位置
	var indicator_y: float
	if insert_index == 0:
		indicator_y = rows[0].position.y - 1
	elif insert_index >= rows.size():
		var last = rows[rows.size() - 1]
		indicator_y = last.position.y + last.size.y - 1
	else:
		indicator_y = rows[insert_index].position.y - 1

	drop_indicator.visible = true
	drop_indicator.position = Vector2(0, indicator_y)
	vbox.move_child(drop_indicator, vbox.get_child_count() - 1)

	# 调试
	print("insert_index: ", insert_index, " / ", rows.size())



func _show_drag_preview(layer_id: String) -> void:
	if drag_preview:
		drag_preview.queue_free()
	drag_preview = PanelContainer.new()
	drag_preview.custom_minimum_size = Vector2(180, 40)
	drag_preview.z_index = 100
	var label = Label.new()
	label.text = "  " + layer_id
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_preview.add_child(label)
	drag_preview.modulate = Color(1, 1, 1, 0.75)
	get_tree().root.add_child(drag_preview)


func _end_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	drop_indicator.visible = false

	var vbox = $VBoxContainer
	var rows = []
	for child in vbox.get_children():
		if child.name != "Title" and child != drop_indicator:
			rows.append(child)

	var total = LayerManager.layers.size()
	var from_layer = _find_layer_by_id(dragging_id)

	if from_layer and insert_index >= 0:
		# 面板从上到下是 layers[total-1] 到 layers[0]
		# insert_index=0 表示面板最顶部，对应 LayerManager index = total-1
		var from_index = LayerManager.layers.find(from_layer)
		var panel_from = total - 1 - from_index  # 被拖层在面板里的位置

		# 从上往下拖时（insert_index > panel_from），需要减1修正
		var adjusted_insert = insert_index
		if insert_index > panel_from:
			adjusted_insert = insert_index - 1

		var to_index = clamp(total - 1 - adjusted_insert, 0, total - 1)
		print("从: ", dragging_id, " 当前: ", LayerManager.layers.find(from_layer), " 目标: ", to_index)
		LayerManager.reorder_layer(from_layer, to_index)

	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null
	dragging_id = ""
	insert_index = -1

func _find_layer_by_id(layer_id: String) -> Node:
	for layer in LayerManager.layers:
		if layer.get_meta("layer_id", "") == layer_id:
			return layer
	return null


func _rebuild_panel() -> void:
	_build_panel()
	if drop_indicator == null:
		_create_drop_indicator()
