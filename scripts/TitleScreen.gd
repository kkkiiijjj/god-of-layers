extends Control


func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/pearl/LevelPearl.tscn")
