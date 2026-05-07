extends PanelContainer

@onready var bubble_text: Label = $MarginContainer/BubbleText

func show_bubble(text: String, position: Vector2, duration: float = 0.0) -> void:
	bubble_text.text = text
	global_position = position
	visible = true
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		hide_bubble()


func hide_bubble() -> void:
	visible = false
