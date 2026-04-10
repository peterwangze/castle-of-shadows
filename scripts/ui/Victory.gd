# Victory.gd
# 胜利画面控制器

extends CanvasLayer

## 节点引用
@onready var panel := $Panel
@onready var victory_label := $Panel/VBoxContainer/VictoryLabel
@onready var stats_label := $Panel/VBoxContainer/StatsLabel
@onready var main_menu_button := $Panel/VBoxContainer/MainMenuButton

## 统计数据
var stats := {}

func _ready():
	"""初始化"""
	# 连接按钮信号
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# 连接 EventBus
	EventBus.show_victory.connect(_on_show_victory)

	# 初始隐藏
	visible = false

func _on_show_victory(game_stats: Dictionary):
	"""显示胜利画面"""
	stats = game_stats
	visible = true

	# 更新统计信息
	update_stats_display()

	# 播放胜利音乐
	EventBus.play_music.emit("bgm_victory", 0.5)

	# 入场动画
	panel.modulate.a = 0
	panel.scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.8)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.8).set_trans(Tween.TRANS_ELASTIC)

func update_stats_display():
	"""更新统计信息显示"""
	var stats_text = "=== 通关统计 ===\n\n"
	stats_text += "游戏时间: " + format_time(stats.get("game_time", 0.0)) + "\n"
	stats_text += "击败敌人: " + str(stats.get("enemies_defeated", 0)) + "\n"
	stats_text += "收集金币: " + str(stats.get("coins_collected", 0)) + "\n"
	stats_text += "最高等级: " + str(stats.get("max_level", 1)) + "\n"
	stats_text += "发现秘密: " + str(stats.get("secrets_found", 0)) + "\n\n"

	# 评价
	var rating = calculate_rating()
	stats_text += "评价: " + rating

	stats_label.text = stats_text

func format_time(seconds: float) -> String:
	"""格式化时间"""
	var hours = int(seconds / 3600)
	var minutes = int((seconds - hours * 3600) / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

func calculate_rating() -> String:
	"""计算评价"""
	var score = 0

	# 时间评价
	if stats.get("game_time", 9999) < 1800:  # 30分钟内
		score += 2
	elif stats.get("game_time", 9999) < 3600:  # 1小时内
		score += 1

	# 敌人评价
	if stats.get("enemies_defeated", 0) >= 100:
		score += 2
	elif stats.get("enemies_defeated", 0) >= 50:
		score += 1

	# 收集评价
	if stats.get("coins_collected", 0) >= 200:
		score += 1

	# 秘密评价
	if stats.get("secrets_found", 0) >= 5:
		score += 1

	# 评级
	match score:
		6:
			return "S 完美通关！"
		5:
			return "A 出色表现！"
		4:
			return "B 优秀通关"
		3:
			return "C 良好通关"
		2:
			return "D 普通关卡"
		_:
			return "E 继续努力"

func _on_main_menu_pressed():
	"""返回主菜单"""
	EventBus.play_sound.emit("ui/confirm", 0.0)

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
