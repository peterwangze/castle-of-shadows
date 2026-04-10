# AudioManager.gd
# 音频管理器 - 处理所有游戏音效和音乐播放
# 配置为 Autoload 单例

extends Node

## ========== 音频设置 ==========
var master_volume := 1.0:
	set(value):
		master_volume = clamp(value, 0.0, 1.0)
		AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

var music_volume := 0.8:
	set(value):
		music_volume = clamp(value, 0.0, 1.0)
		AudioServer.set_bus_volume_db(1, linear_to_db(music_volume))

var sfx_volume := 1.0:
	set(value):
		sfx_volume = clamp(value, 0.0, 1.0)
		AudioServer.set_bus_volume_db(2, linear_to_db(sfx_volume))

## ========== 音频资源缓存 ==========
var sound_cache := {}
var music_cache := {}

## ========== 当前播放的音乐 ==========
var current_music: AudioStreamPlayer
var music_fade_duration := 1.0
var music_volume_before_fade := 0.0

## ========== 音效池 ==========
var sfx_pool := []
const SFX_POOL_SIZE := 15

## ========== 初始化 ==========
func _ready():
	# 初始化音频池
	_init_sfx_pool()

	# 连接 EventBus 信号
	EventBus.play_sound.connect(_on_play_sound)
	EventBus.play_music.connect(_on_play_music)
	EventBus.stop_music.connect(_on_stop_music)
	EventBus.pause_music.connect(_on_pause_music)
	EventBus.resume_music.connect(_on_resume_music)
	EventBus.set_volume.connect(_on_set_volume)

	# 预加载常用音效
	preload_common_sounds()

	print("AudioManager 初始化完成")

func _init_sfx_pool():
	"""初始化音效播放器池"""
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_pool.append(player)

## ========== 音效预加载 ==========
func preload_common_sounds():
	"""预加载常用音效"""
	var common_sounds := [
		"player/jump",
		"player/attack",
		"player/hurt",
		"player/land",
		"player/dash",
		"player/heal",
		"player/level_up",
		"enemies/hit",
		"enemies/die",
		"ui/coin",
		"ui/pause",
		"ui/select",
		"ui/confirm",
		"ui/cancel"
	]

	for sound_name in common_sounds:
		var path = "res://assets/sounds/%s.wav" % sound_name
		if ResourceLoader.exists(path):
			sound_cache[sound_name] = load(path)

## ========== 音效播放 ==========
func _on_play_sound(sound_name: String, volume_db: float = 0.0):
	"""播放音效"""
	var stream = sound_cache.get(sound_name)

	if not stream:
		var path = "res://assets/sounds/%s.wav" % sound_name
		if ResourceLoader.exists(path):
			stream = load(path)
			sound_cache[sound_name] = stream
		else:
			# 尝试 .ogg 格式
			path = "res://assets/sounds/%s.ogg" % sound_name
			if ResourceLoader.exists(path):
				stream = load(path)
				sound_cache[sound_name] = stream
			else:
				push_warning("音效文件不存在: " + sound_name)
				return

	var player = _get_available_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
		player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""获取空闲的音效播放器"""
	for player in sfx_pool:
		if not player.playing:
			return player

	# 池满，创建新播放器
	var new_player = AudioStreamPlayer.new()
	new_player.bus = "SFX"
	add_child(new_player)
	sfx_pool.append(new_player)
	return new_player

func play_sound_at_position(sound_name: String, position: Vector2, volume_db: float = 0.0):
	"""在指定位置播放音效（2D空间音效）"""
	var stream = sound_cache.get(sound_name)
	if not stream:
		var path = "res://assets/sounds/%s.wav" % sound_name
		if ResourceLoader.exists(path):
			stream = load(path)
			sound_cache[sound_name] = stream
		else:
			return

	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = position
	player.volume_db = volume_db
	player.max_distance = 500.0
	player.bus = "SFX"
	get_tree().current_scene.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

## ========== 音乐播放 ==========
func _on_play_music(music_name: String, fade_duration: float = 1.0):
	"""播放背景音乐"""
	var path = "res://assets/music/%s.ogg" % music_name
	if not ResourceLoader.exists(path):
		# 尝试 .mp3 格式
		path = "res://assets/music/%s.mp3" % music_name
		if not ResourceLoader.exists(path):
			push_warning("音乐文件不存在: " + music_name)
			return

	var new_stream = music_cache.get(music_name)
	if not new_stream:
		new_stream = load(path)
		music_cache[music_name] = new_stream

	# 相同音乐跳过
	if current_music and current_music.stream == new_stream and current_music.playing:
		return

	# 淡入淡出切换
	fade_to_music(new_stream, fade_duration)

func fade_to_music(new_stream: AudioStream, duration: float):
	"""淡入淡出切换音乐"""
	# 淡出当前音乐
	if current_music and current_music.playing:
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(current_music, "volume_db", -40.0, duration * 0.5)
		fade_out_tween.tween_callback(func():
			current_music.stop()
			current_music.queue_free()
		)

	# 创建新音乐播放器
	var new_player = AudioStreamPlayer.new()
	new_player.stream = new_stream
	new_player.bus = "Music"
	new_player.volume_db = -40.0
	new_player.pitch_scale = 1.0
	add_child(new_player)

	# 淡入
	new_player.play()
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(new_player, "volume_db",
		linear_to_db(music_volume * master_volume), duration)

	current_music = new_player

func _on_stop_music(fade_duration: float = 1.0):
	"""停止音乐"""
	if current_music and current_music.playing:
		var tween = create_tween()
		tween.tween_property(current_music, "volume_db", -40.0, fade_duration)
		tween.tween_callback(func():
			current_music.stop()
		)

func _on_pause_music():
	"""暂停音乐"""
	if current_music and current_music.playing:
		music_volume_before_fade = current_music.volume_db
		var tween = create_tween()
		tween.tween_property(current_music, "volume_db", -20.0, 0.3)
		tween.tween_callback(func():
			current_music.stream_paused = true
		)

func _on_resume_music():
	"""恢复音乐"""
	if current_music and current_music.stream_paused:
		current_music.stream_paused = false
		current_music.volume_db = -20.0
		var tween = create_tween()
		tween.tween_property(current_music, "volume_db",
			linear_to_db(music_volume * master_volume), 0.3)

## ========== 音量控制 ==========
func _on_set_volume(bus_name: String, volume: float):
	"""设置音量"""
	match bus_name:
		"Master":
			master_volume = volume
		"Music":
			music_volume = volume
		"SFX":
			sfx_volume = volume

func set_master_volume(value: float):
	"""设置主音量"""
	master_volume = value

func set_music_volume(value: float):
	"""设置音乐音量"""
	music_volume = value

func set_sfx_volume(value: float):
	"""设置音效音量"""
	sfx_volume = value

## ========== 工具方法 ==========
func is_music_playing() -> bool:
	"""检查音乐是否正在播放"""
	return current_music and current_music.playing and not current_music.stream_paused

func get_current_music_name() -> String:
	"""获取当前播放的音乐名称"""
	if current_music and current_music.stream:
		return current_music.stream.resource_path.get_file().get_basename()
	return ""

func stop_all_sounds():
	"""停止所有音效"""
	for player in sfx_pool:
		if player.playing:
			player.stop()
