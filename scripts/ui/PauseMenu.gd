# PauseMenu.gd
# 暂停菜单控制器

extends CanvasLayer

## 节点引用
@onready var panel := $Panel
@onready var resume_button := $Panel/VBoxContainer/ResumeButton
@onready var settings_button := $Panel/VBoxContainer/SettingsButton
@onready var main_menu_button := $Panel/VBoxContainer/MainMenuButton

## 状态
var is_paused := false

func _ready():
	"""初始化"""
	# 连接按钮信号
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# 连接 EventBus
	EventBus.show_pause_menu.connect(_on_show_pause_menu)
	EventBus.hide_pause_menu.connect(_on_hide_pause_menu)

	# 初始隐藏
	visible = false

func _input(event: InputEvent):
	"""输入处理"""
	if event.is_action_pressed("pause"):
		if is_paused:
			_on_resume_pressed()
		else:
			_on_show_pause_menu()

func _on_show_pause_menu():
	"""显示暂停菜单"""
	is_paused = true
	visible = true

	# 暂停游戏
	Game.pause_game()

	# 播放音效
	EventBus.play_sound.emit("ui/pause", 0.0)

	# 暂停音乐
	EventBus.pause_music.emit()

	# 入场动画
	panel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _on_hide_pause_menu():
	"""隐藏暂停菜单"""
	is_paused = false

	# 恢复游戏
	Game.resume_game()

	# 恢复音乐
	EventBus.resume_music.emit()

	# 退出动画
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)

func _on_resume_pressed():
	"""继续游戏"""
	EventBus.play_sound.emit("ui/confirm", 0.0)
	_on_hide_pause_menu()

func _on_settings_pressed():
	"""设置"""
	EventBus.play_sound.emit("ui/select", 0.0)
	# TODO: 打开设置界面
	print("打开设置界面")

func _on_main_menu_pressed():
	"""返回主菜单"""
	EventBus.play_sound.emit("ui/cancel", 0.0)

	# 确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "返回主菜单将丢失未保存的进度，确定吗？"
	dialog.title = "确认"
	dialog.confirmed.connect(_confirm_return_to_main_menu)
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func _confirm_return_to_main_menu():
	"""确认返回主菜单"""
	# 隐藏暂停菜单
	is_paused = false
	visible = false

	# 恢复游戏时间
	Game.game_state = Game.GameState.MENU
	Engine.time_scale = 1.0

	# 停止音乐
	EventBus.stop_music.emit(0.5)

	# 返回主菜单
	var main_menu = load("res://scenes/ui/MainMenu.tscn")
	if main_menu:
		get_tree().change_scene_to_packed(main_menu)
