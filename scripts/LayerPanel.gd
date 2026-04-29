extends PanelContainer

var layer_buttons: Dictionary = {}
var dragging_id: String = ""
var drag_preview: Control = null
var drop_indicator: Control = null
var is_dragging: bool = false
var insert_index: int = -1
var selected_id: String = ""
var opacity_slider: HSlider = null
var opacity_label: Label = null


func _ready() -> void:
	await get_tree().process_frame
	_build_panel()
	_create_drop_indicator()
	EventBus.layer_reordered.connect(_rebuild_panel)
	EventBus.layer_visibility_changed.connect(_on_visibility_changed)


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
		if child.name != "Title" and child != drop_indicator and child.name != "OpacityRow" and child.name != "Separator":
			child.queue_free()
	layer_buttons.clear()

	# 透明度区域插在 Title 后面
	_build_opacity_row(vbox)

	var layers_reversed = LayerManager.layers.duplicate()
	layers_reversed.reverse()

	for layer in layers_reversed:
		var layer_id = layer.get_meta("layer_id", "")
		var row = _create_layer_row(layer, layer_id)
		vbox.add_child(row) 
		# 同步隐藏状态
		row.visible = layer.visible


func _build_opacity_row(vbox: VBoxContainer) -> void:
	# 如果已经存在就跳过
	if vbox.has_node("OpacityRow"):
		return

	# 透明度行容器
	var opacity_row = VBoxContainer.new()
	opacity_row.name = "OpacityRow"
	opacity_row.custom_minimum_size = Vector2(180, 56)

	# 上方：标签 + 数值
	var top_row = HBoxContainer.new()
	var opacity_title = Label.new()
	opacity_title.text = "不透明度"
	opacity_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	opacity_label = Label.new()
	opacity_label.text = "100%"
	opacity_label.custom_minimum_size = Vector2(40, 0)
	opacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	top_row.add_child(opacity_title)
	top_row.add_child(opacity_label)

	# 滑条
	opacity_slider = HSlider.new()
	opacity_slider.min_value = 0.0
	opacity_slider.max_value = 1.0
	opacity_slider.step = 0.01
	opacity_slider.value = 1.0
	opacity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opacity_slider.value_changed.connect(_on_opacity_changed)

	opacity_row.add_child(top_row)
	opacity_row.add_child(opacity_slider)

	# 分隔线
	var sep = HSeparator.new()
	sep.name = "Separator"

	vbox.add_child(opacity_row)
	vbox.add_child(sep)


func _on_opacity_changed(value: float) -> void:
	if selected_id == "":
		return
	LayerManager.set_opacity(selected_id, value)
	opacity_label.text = str(int(value * 100)) + "%"


func _select_layer(layer_id: String) -> void:
	# 取消上一个选中的高亮
	if selected_id != "" and layer_buttons.has(selected_id):
		layer_buttons[selected_id].modulate = Color.WHITE

	selected_id = layer_id

	# 高亮新选中行
	if layer_buttons.has(selected_id):
		layer_buttons[selected_id].modulate = Color(0.5, 0.8, 1.0)

	# 同步滑条到当前图层的透明度
	var layer = _find_layer_by_id(layer_id)
	if layer and opacity_slider:
		var current_opacity = layer.modulate.a
		opacity_slider.value = current_opacity
		opacity_label.text = str(int(current_opacity * 100)) + "%"


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

	# 图层名称，点击选中
	var label = Button.new()
	label.text = layer_id
	label.flat = true
	label.alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.pressed.connect(func():
		_select_layer(layer_id)
	)

	row.add_child(handle)
	row.add_child(eye_btn)
	row.add_child(label)
	layer_buttons[layer_id] = row
	return row


func _on_handle_input(event: InputEvent, layer_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_select_layer(layer_id)
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
		if child.name != "Title" and child != drop_indicator and child.name != "OpacityRow" and child.name != "Separator":
			rows.append(child)

	insert_index = rows.size()

	for i in rows.size():
		var child = rows[i]
		var child_mid = child.position.y + child.size.y / 2.0
		if mouse_pos.y < child_mid:
			insert_index = i
			break

	var indicator_y: float
	if rows.size() == 0:
		indicator_y = 0
	elif insert_index == 0:
		indicator_y = rows[0].position.y - 1
	elif insert_index >= rows.size():
		var last = rows[rows.size() - 1]
		indicator_y = last.position.y + last.size.y - 1
	else:
		indicator_y = rows[insert_index].position.y - 1

	drop_indicator.visible = true
	drop_indicator.position = Vector2(0, indicator_y)
	vbox.move_child(drop_indicator, vbox.get_child_count() - 1)


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
		if child.name != "Title" and child != drop_indicator and child.name != "OpacityRow" and child.name != "Separator":
			rows.append(child)

	var total = LayerManager.layers.size()
	var from_layer = _find_layer_by_id(dragging_id)

	if from_layer and insert_index >= 0:
		var from_index = LayerManager.layers.find(from_layer)
		var panel_from = total - 1 - from_index
		var adjusted_insert = insert_index
		if insert_index > panel_from:
			adjusted_insert = insert_index - 1
		var to_index = clamp(total - 1 - adjusted_insert, 0, total - 1)
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
		
func _on_visibility_changed(layer_id: String, visible: bool) -> void:
	if layer_buttons.has(layer_id):
		layer_buttons[layer_id].visible = visible
