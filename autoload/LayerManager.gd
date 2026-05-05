extends Node

# 当前所有图层，按显示顺序排列（index 0 = 最底层）
var layers: Array[Node] = []


# ───────────────────────────────
#  注册 / 注销
# ───────────────────────────────

func register_layer(layer: Node) -> void:
	if layer not in layers:
		layers.append(layer)
	_refresh_z_index()


func unregister_layer(layer: Node) -> void:
	layers.erase(layer)
	_refresh_z_index()


# ───────────────────────────────
#  核心操作
# ───────────────────────────────

# 调整图层顺序：把 layer 移动到 target_index 位置
func reorder_layer(layer: Node, target_index: int) -> void:
	if layer not in layers:
		return
	layers.erase(layer)
	target_index = clamp(target_index, 0, layers.size())
	layers.insert(target_index, layer)
	_refresh_z_index()
	EventBus.layer_reordered.emit()


# 设置透明度
func set_opacity(layer_id: String, opacity: float) -> void:
	var layer = _find_layer(layer_id)
	if layer:
		layer.modulate.a = clamp(opacity, 0.0, 1.0)
		EventBus.layer_opacity_changed.emit(layer_id, opacity)


# 显示 / 隐藏图层
func set_visible(layer_id: String, visible: bool) -> void:
	var layer = _find_layer(layer_id)
	if layer:
		layer.visible = visible
		EventBus.layer_visibility_changed.emit(layer_id, visible)


# 复制图层（用于结局：复制一份留给老板，原件还给美人鱼）
func copy_layer(layer_id: String, new_id: String) -> Node:
	var layer = _find_layer(layer_id)
	if not layer:
		return null
	var copy = layer.duplicate()
	copy.set_meta("layer_id", new_id)
	layer.get_parent().add_child(copy)
	register_layer(copy)
	EventBus.layer_copied.emit(layer_id, new_id)
	return copy


# 合并图层（永久，对应重要叙事时刻）
func merge_layers(layer_a_id: String, layer_b_id: String) -> void:
	var layer_a = _find_layer(layer_a_id)
	var layer_b = _find_layer(layer_b_id)
	if not layer_a or not layer_b:
		return
	# 把 layer_b 的所有子节点移入 layer_a
	for child in layer_b.get_children():
		layer_b.remove_child(child)
		layer_a.add_child(child)
	unregister_layer(layer_b)
	layer_b.queue_free()
	EventBus.layer_merged.emit(layer_a_id, layer_b_id)


# ───────────────────────────────
#  查询
# ───────────────────────────────

func get_layer_index(layer_id: String) -> int:
	var layer = _find_layer(layer_id)
	return layers.find(layer)


func get_layer_count() -> int:
	return layers.size()


# ───────────────────────────────
#  内部工具
# ───────────────────────────────

# 根据 layer_id 找到对应节点
func _find_layer(layer_id: String) -> Node:
	for layer in layers:
		if layer.get_meta("layer_id", "") == layer_id:
			return layer
	return null


func _refresh_z_index() -> void:
	for i in layers.size():
		layers[i].z_index = i
		layers[i].z_as_relative = false
		# 同步场景树顺序
		var parent = layers[i].get_parent()
		if parent:
			parent.move_child(layers[i], i)
