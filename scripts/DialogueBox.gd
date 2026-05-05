extends PanelContainer

@onready var dialogue_text: Label = $MarginContainer/VBoxContainer/DialogueText
@onready var continue_btn: Button = $MarginContainer/VBoxContainer/ContinueBtn

var dialogue_queue: Array = []
var on_complete: Callable = Callable()


func _ready() -> void:
	visible = false
	continue_btn.text = "继续 ▶"
	continue_btn.pressed.connect(_on_continue_pressed)


func show_dialogue(lines: Array, complete_callback: Callable = Callable()) -> void:
	dialogue_queue = lines.duplicate()
	on_complete = complete_callback
	visible = true
	_show_next_line()

func _show_next_line() -> void:
	if dialogue_queue.is_empty():
		_finish()
		return
	dialogue_text.text = dialogue_queue.pop_front()


func _on_continue_pressed() -> void:
	_show_next_line()


func _finish() -> void:
	visible = false
	if on_complete.is_valid():
		on_complete.call()
