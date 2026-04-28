class_name LayerRow
extends HBoxContainer

var panel: Control = null
var layer_id: String = ""


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("layer_id")


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if panel:
		panel._drop_data_fw(self, _pos, data)
