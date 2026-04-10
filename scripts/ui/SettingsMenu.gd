# SettingsMenu.gd
# 设置菜单控制器

extends CanvasLayer

## 节点引用
@onready var panel := $Panel
@onready var master_slider := $Panel/VBoxContainer/MasterContainer/MasterSlider
@onready var music_slider := $Panel/VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider := $Panel/VBoxContainer/SFXContainer/SFXSlider
@onready var fullscreen_check := $Panel/VBoxContainer/FullscreenCheck
@onready var vsync_check := $Panel/VBoxContainer/VSyncCheck
@onready var back_button := $Panel/VBoxContainer/BackButton

## 状态
var settings_changed := false

func _ready():
	"""初始化"""
	# 连接信号
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	back_button.pressed.connect(_on_back_pressed)

	# 加载当前设置
	load_current_settings()

	# 初始隐藏
	visible = false

func load_current_settings():
	"""加载当前设置"""
	master_slider.value = AudioManager.master_volume
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume

	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	vsync_check.button_pressed = ProjectSettings.get_setting("display/window/vsync/vsync_mode") == 1

func show_settings():
	"""显示设置菜单"""
	visible = true
	settings_changed = false

	# 入场动画
	panel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func hide_settings():
	"""隐藏设置菜单"""
	# 保存设置
	if settings_changed:
		Game.save_game_settings()

	# 退出动画
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)

func _on_master_volume_changed(value: float):
	"""主音量改变"""
	AudioManager.set_master_volume(value)
	settings_changed = true
	EventBus.play_sound.emit("ui/select", 0.0)

func _on_music_volume_changed(value: float):
	"""音乐音量改变"""
	AudioManager.set_music_volume(value)
	settings_changed = true

func _on_sfx_volume_changed(value: float):
	"""音效音量改变"""
	AudioManager.set_sfx_volume(value)
	settings_changed = true
	EventBus.play_sound.emit("ui/select", 0.0)

func _on_fullscreen_toggled(enabled: bool):
	"""全屏切换"""
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	settings_changed = true

func _on_vsync_toggled(enabled: bool):
	"""垂直同步切换"""
	ProjectSettings.set_setting("display/window/vsync/vsync_mode", 1 if enabled else 0)
	settings_changed = true

func _on_back_pressed():
	"""返回按钮"""
	EventBus.play_sound.emit("ui/cancel", 0.0)
	hide_settings()
