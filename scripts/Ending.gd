extends CanvasLayer

@onready var bg = $Background
@onready var ending_image = $EndingImage
@onready var bubble1 = $EndingBubble1
@onready var bubble2 = $EndingBubble2
@onready var credits = $Credits
@onready var credits_label = $Credits/CreditsLabel

var ending_textures: Array = []
var current_image: int = 0


func _ready() -> void:
	# 加载四张结局图
	ending_textures = [
		preload("res://assets/sprites/ending_1.png"),
		preload("res://assets/sprites/ending_2.png"),
		preload("res://assets/sprites/ending_3.png"),
		preload("res://assets/sprites/ending_4.png"),
	]
	bubble1.visible = false
	bubble2.visible = false
	ending_image.visible = false
	_start_ending()


func _start_ending() -> void:
	# 黑屏淡入第一张图
	await get_tree().create_timer(0.5).timeout
	_show_image(0)
	await get_tree().create_timer(1.0).timeout
	# ending_1：琳达和美人鱼对话
	bubble2.show_bubble("怎么这么晚才来，不会是把我忘了吧？", Vector2(100, 400), 0.0)
	await get_tree().create_timer(3.0).timeout
	bubble1.show_bubble("不是不是！我弄丢了我的珍珠项链，刚刚才找到，我戴上漂亮吧？", Vector2(700, 200), 0.0)
	await get_tree().create_timer(4.0).timeout
	bubble1.hide_bubble()
	bubble2.hide_bubble()
	# ending_2：无对话，停留2秒
	_show_image(1)
	await get_tree().create_timer(2.5).timeout
	# ending_3：琳达回应
	_show_image(2)
	await get_tree().create_timer(1.0).timeout
	bubble2.show_bubble("非常非常漂亮。", Vector2(700, 200), 0.0)
	await get_tree().create_timer(3.0).timeout
	bubble2.show_bubble("舞会已经开始了，走，我们一起去跳舞。", Vector2(700, 200), 0.0)
	await get_tree().create_timer(3.0).timeout
	bubble2.hide_bubble()
	# ending_4：双鱼共舞
	_show_image(3)
	await get_tree().create_timer(3.0).timeout
	# 显示结语
	_show_final_text()


func _show_image(index: int) -> void:
	# 淡出当前图
	if ending_image.visible:
		var tween = create_tween()
		tween.tween_property(ending_image, "modulate:a", 0.0, 0.8)
		await tween.finished
	# 切换图片
	ending_image.texture = ending_textures[index]
	ending_image.visible = true
	ending_image.scale = Vector2(1, 1)
	# 淡入新图
	ending_image.modulate.a = 0.0
	var tween2 = create_tween()
	tween2.tween_property(ending_image, "modulate:a", 1.0, 0.8)
	await tween2.finished

#
#func _show_final_text() -> void:
	#bubble1.show_bubble("没有人知道发生过什么。", Vector2(440, 600), 0.0)

func _show_final_text() -> void:
	#bubble1.show_bubble("没有人知道发生过什么。", Vector2(440, 600), 4.0)
	await get_tree().create_timer(4.5).timeout
	_start_credits()


func _start_credits() -> void:
	# 黑屏
	ending_image.visible = false
	bg.color = Color.BLACK
	credits.visible = true
	
	# 把 label 放在屏幕下方
	credits_label.position = Vector2(0, 720)
	credits_label.custom_minimum_size = Vector2(1280, 0)
	
	# 滚动到屏幕上方
	var tween = create_tween()
	tween.tween_property(credits_label, "position:y", -credits_label.size.y, 8.0).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	
	# 结束，回到开始界面
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
