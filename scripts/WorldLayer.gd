extends Node2D

@export var layer_id: String = ""
@export var layer_name: String = ""
@export var draggable: bool = true
@export var placeholder_color: Color = Color.WHITE


func _ready() -> void:
	set_meta("layer_id", layer_id)
	LayerManager.register_layer(self)
	
	# 设置占位色块颜色
	var rect = $Content/ColorRect
	if rect:
		rect.color = placeholder_color


func _exit_tree() -> void:
	LayerManager.unregister_layer(self)


func get_items() -> Array[Node]:
	var items: Array[Node] = []
	for child in $Content.get_children():
		if child.has_meta("interactable"):
			items.append(child)
	return items
