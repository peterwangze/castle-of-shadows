# GameOver.gd
# 游戏结束画面控制器

extends CanvasLayer

## 节点引用
@onready var panel := $Panel
@onready var game_over_label := $Panel/VBoxContainer/GameOverLabel
@onready var stats_label := $Panel/VBoxContainer/StatsLabel
@onready var retry_button := $Panel/VBoxContainer/ButtonContainer/RetryButton
@onready var main_menu_button := $Panel/VBoxContainer/ButtonContainer/MainMenuButton

## 统计数据
var stats := {}

func _ready():
	"""初始化"""
	# 连接按钮信号
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# 连接 EventBus
	EventBus.show_game_over.connect(_on_show_game_over)

	# 初始隐藏
	visible = false

func _on_show_game_over(game_stats: Dictionary):
	"""显示游戏结束画面"""
	stats = game_stats
	visible = true

	# 更新统计信息
	update_stats_display()

	# 播放音效
	EventBus.play_sound.emit("ui/game_over", 0.0)

	# 入场动画
	panel.modulate.a = 0
	panel.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK)

func update_stats_display():
	"""更新统计信息显示"""
	var stats_text = ""
	stats_text += "游戏时间: " + format_time(stats.get("game_time", 0.0)) + "\n"
	stats_text += "击败敌人: " + str(stats.get("enemies_defeated", 0)) + "\n"
	stats_text += "收集金币: " + str(stats.get("coins_collected", 0)) + "\n"
	stats_text += "最高等级: " + str(stats.get("max_level", 1)) + "\n"
	stats_text += "到达关卡: " + stats.get("current_level", "未知")

	stats_label.text = stats_text

func format_time(seconds: float) -> String:
	"""格式化时间"""
	var hours = int(seconds / 3600)
	var minutes = int((seconds - hours * 3600) / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

func _on_retry_pressed():
	"""重试"""
	EventBus.play_sound.emit("ui/confirm", 0.0)

	# 隐藏画面
	visible = false

	# 重置游戏状态
	Game.reset_game_state()

	# 重新开始
	Game.start_new_game()

func _on_main_menu_pressed():
	"""返回主菜单"""
	EventBus.play_sound.emit("ui/cancel", 0.0)

	# 隐藏画面
	visible = false

	# 重置游戏状态
	Game.game_state = Game.GameState.MENU

	# 停止音乐
	EventBus.stop_music.emit(0.5)

	# 返回主菜单
	var main_menu = load("res://scenes/ui/MainMenu.tscn")
	if main_menu:
		get_tree().change_scene_to_packed(main_menu)
