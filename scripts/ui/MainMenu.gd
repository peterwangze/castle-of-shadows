# MainMenu.gd
# 主菜单控制器

extends Control

## 节点引用
@onready var title_label := $VBoxContainer/TitleLabel
@onready var new_game_button := $VBoxContainer/ButtonContainer/NewGameButton
@onready var continue_button := $VBoxContainer/ButtonContainer/ContinueButton
@onready var settings_button := $VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button := $VBoxContainer/ButtonContainer/QuitButton
@onready var version_label := $VersionLabel

## 动画
@onready var animation_player := $AnimationPlayer

func _ready():
	"""初始化"""
	# 连接按钮信号
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 检查是否有存档
	var has_save = _check_save_exists()
	continue_button.disabled = not has_save

	# 显示版本号
	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "1.0.0")

	# 播放入场动画
	animation_player.play("fade_in")

	# 播放菜单音乐
	EventBus.play_music.emit("bgm_menu", 1.0)

func _check_save_exists() -> bool:
	"""检查是否存在存档"""
	return FileAccess.file_exists("user://save_slot_0.dat") or \
		   FileAccess.file_exists("user://autosave.dat")

func _on_new_game_pressed():
	"""新游戏按钮"""
	EventBus.play_sound.emit("ui/confirm", 0.0)

	# 过渡动画
	animation_player.play("fade_out")
	await animation_player.animation_finished

	# 开始新游戏
	Game.start_new_game()

func _on_continue_pressed():
	"""继续游戏按钮"""
	EventBus.play_sound.emit("ui/confirm", 0.0)

	# 过渡动画
	animation_player.play("fade_out")
	await animation_player.animation_finished

	# 加载游戏
	if FileAccess.file_exists("user://save_slot_0.dat"):
		Game.load_game()
	else:
		Game.load_game()  # 会自动加载自动存档

func _on_settings_pressed():
	"""设置按钮"""
	EventBus.play_sound.emit("ui/select", 0.0)

	# TODO: 打开设置界面
	print("打开设置界面")

func _on_quit_pressed():
	"""退出按钮"""
	EventBus.play_sound.emit("ui/cancel", 0.0)

	# 确认退出对话框
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _input(event: InputEvent):
	"""输入处理"""
	if event.is_action_pressed("ui_cancel"):
		# ESC 键退出
		_on_quit_pressed()
