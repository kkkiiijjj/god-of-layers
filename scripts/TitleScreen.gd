extends Control

@onready var title_image = $TitleImage


func _ready() -> void:
	title_image.pivot_offset = title_image.size / 2
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_effect()
		else:
			_release_effect()


func _press_effect() -> void:
	var tween = create_tween()
	tween.tween_property(title_image, "scale", Vector2(0.97, 0.97), 0.1)


func _release_effect() -> void:
	var tween = create_tween()
	tween.tween_property(title_image, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/pearl/LevelPearl.tscn")
