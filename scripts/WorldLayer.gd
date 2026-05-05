extends Node2D

@export var layer_id: String = ""
@export var layer_name: String = ""
@export var draggable: bool = true
@export var placeholder_color: Color = Color.WHITE
@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			$Content/Sprite2D.texture = value


func _ready() -> void:
	set_meta("layer_id", layer_id)
	# 不在这里注册，由 LevelPearl 统一管理
	z_as_relative = false
	if texture:
		$Content/Sprite2D.texture = texture


func _exit_tree() -> void:
	LayerManager.unregister_layer(self)


func get_items() -> Array[Node]:
	var items: Array[Node] = []
	for child in $Content.get_children():
		if child.has_meta("interactable"):
			items.append(child)
	return items
