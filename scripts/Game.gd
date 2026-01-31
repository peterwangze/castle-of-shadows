# Game.gd
# 游戏全局管理器

extends Node

## 单例实例
static var instance: Game = null

## 全局变量
var player: Node2D = null
var player_data: PlayerData = null
var current_level: String = ""
var game_paused := false
var game_time := 0.0
var enemies := []  # 当前场景中所有敌人
var checkpoints := {}  # 检查点数据
var current_checkpoint := ""

## 游戏状态
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}
var game_state := GameState.MENU

## 调试系统
var debug_mode := false
var debug_ui_node: CanvasLayer = null
var debug_label: Label = null
var invincible_mode := false
var one_hit_kill_mode := false
var infinite_energy_mode := false

## 资源引用
var levels := {
	"castle_exterior": "res://levels/CastleExterior.tscn",
	"main_hall": "res://levels/MainHall.tscn",
	"catacombs": "res://levels/Catacombs.tscn",
	"banquet_hall": "res://levels/BanquetHall.tscn",
	"clock_tower": "res://levels/ClockTower.tscn",
	"throne_room": "res://levels/ThroneRoom.tscn"
}

var player_scene := "res://scenes/player/Player.tscn"

func _ready():
	"""游戏初始化"""
	# 设置单例
	if instance == null:
		instance = self
		process_mode = PROCESS_MODE_ALWAYS  # 永远运行
	else:
		queue_free()
		return

	# 初始化系统
	initialize_systems()
	load_game_settings()

	print("游戏管理器初始化完成")

func initialize_systems():
	"""初始化所有子系统"""
	# 初始化玩家数据
	player_data = PlayerData.new()

	# 连接信号
	EventBus.connect("player_died", _on_player_died)
	EventBus.connect("enemy_died", _on_enemy_died)
	EventBus.connect("checkpoint_reached", _on_checkpoint_reached)
	EventBus.connect("level_completed", _on_level_completed)

	# 初始化音频
	initialize_audio()

	# 初始化UI
	initialize_ui()

func start_new_game():
	"""开始新游戏"""
	print("开始新游戏")

	# 重置游戏状态
	reset_game_state()

	# 加载初始关卡
	change_level("castle_exterior")

	# 生成玩家
	spawn_player_at_start()

	# 设置游戏状态
	game_state = GameState.PLAYING
	game_time = 0.0

	# 播放开始音效
	play_sound("game_start")

	# 显示教程提示
	show_tutorial("movement")

func change_level(level_name: String):
	"""切换关卡"""
	if not level_name in levels:
		push_error("关卡不存在: " + level_name)
		return

	# 保存当前关卡数据
	if current_level != "":
		save_level_state(current_level)

	# 加载新关卡
	var level_path = levels[level_name]
	var level_scene = load(level_path)

	if level_scene:
		# 移除旧关卡
		if has_node("CurrentLevel"):
			get_node("CurrentLevel").queue_free()

		# 添加新关卡
		var level_instance = level_scene.instantiate()
		level_instance.name = "CurrentLevel"
		add_child(level_instance)

		current_level = level_name

		# 加载关卡状态
		load_level_state(level_name)

		print("切换到关卡: " + level_name)

		# 播放关卡音乐
		play_level_music(level_name)

func spawn_player_at_start():
	"""在关卡起点生成玩家"""
	if player and is_instance_valid(player):
		player.queue_free()

	var player_scene_res = load(player_scene)
	if player_scene_res:
		player = player_scene_res.instantiate()

		# 寻找生成点
		var spawn_point = find_spawn_point()
		if spawn_point:
			player.global_position = spawn_point.global_position
		else:
			player.global_position = Vector2(100, 300)

		get_node("CurrentLevel").add_child(player)

		# 连接玩家信号
		player.connect("died", _on_player_died)

		print("玩家生成在位置: " + str(player.global_position))

func spawn_player_at_checkpoint(checkpoint_id: String):
	"""在检查点生成玩家"""
	if not checkpoint_id in checkpoints:
		push_error("检查点不存在: " + checkpoint_id)
		spawn_player_at_start()
		return

	var checkpoint_data = checkpoints[checkpoint_id]

	# 加载关卡
	if checkpoint_data.level != current_level:
		change_level(checkpoint_data.level)

	# 生成玩家
	if player and is_instance_valid(player):
		player.queue_free()

	var player_scene_res = load(player_scene)
	if player_scene_res:
		player = player_scene_res.instantiate()
		player.global_position = checkpoint_data.position

		# 恢复玩家状态
		player.health = checkpoint_data.player_health
		player.shadow_energy = checkpoint_data.player_energy

		get_node("CurrentLevel").add_child(player)

		current_checkpoint = checkpoint_id

		print("玩家在检查点重生: " + checkpoint_id)

func find_spawn_point() -> Node2D:
	"""寻找关卡中的生成点"""
	var current_level_node = get_node_or_null("CurrentLevel")
	if not current_level_node:
		return null

	# 寻找PlayerSpawn节点
	for child in current_level_node.get_children():
		if child.name == "PlayerSpawn":
			return child

	# 寻找标记为spawn的Marker2D
	for child in current_level_node.get_children():
		if child is Marker2D and child.name.contains("spawn"):
			return child

	return null

func pause_game():
	"""暂停游戏"""
	if game_state == GameState.PLAYING:
		game_state = GameState.PAUSED
		game_paused = true
		Engine.time_scale = 0.0

		# 显示暂停菜单
		show_pause_menu()

		play_sound("pause")

func resume_game():
	"""恢复游戏"""
	if game_state == GameState.PAUSED:
		game_state = GameState.PLAYING
		game_paused = false
		Engine.time_scale = 1.0

		# 隐藏暂停菜单
		hide_pause_menu()

		play_sound("unpause")

func toggle_pause():
	"""切换暂停状态"""
	if game_state == GameState.PLAYING:
		pause_game()
	elif game_state == GameState.PAUSED:
		resume_game()

func game_over():
	"""游戏结束"""
	game_state = GameState.GAME_OVER

	# 停止游戏时间
	game_paused = true

	# 显示游戏结束画面
	show_game_over_screen()

	# 播放游戏结束音效
	play_sound("game_over")

	print("游戏结束")

func victory():
	"""游戏胜利"""
	game_state = GameState.VICTORY

	# 停止游戏时间
	game_paused = true

	# 显示胜利画面
	show_victory_screen()

	# 播放胜利音效
	play_sound("victory")

	# 保存通关记录
	save_completion_data()

	print("游戏胜利！")

func save_game():
	"""保存游戏"""
	var save_data = {
		"checkpoints": serialize_checkpoints(),
		"player_data": player_data.serialize(),
		"current_level": current_level,
		"current_checkpoint": current_checkpoint,
		"game_time": game_time,
		"enemies_defeated": player_data.enemies_defeated
	}

	var save_file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()
		print("游戏已保存")

		# 显示保存提示
		show_save_indicator()

func load_game():
	"""加载游戏"""
	if not FileAccess.file_exists("user://save_game.dat"):
		push_error("存档文件不存在")
		return false

	var save_file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if save_file:
		var save_data = save_file.get_var()
		save_file.close()

		# 恢复数据
		deserialize_checkpoints(save_data.checkpoints)
		player_data.deserialize(save_data.player_data)
		current_level = save_data.current_level
		current_checkpoint = save_data.current_checkpoint
		game_time = save_data.game_time

		# 加载关卡
		change_level(current_level)

		# 在检查点生成玩家
		spawn_player_at_checkpoint(current_checkpoint)

		game_state = GameState.PLAYING

		print("游戏已加载")
		return true

	return false

func register_enemy(enemy: Node2D):
	"""注册敌人到管理器"""
	if not enemy in enemies:
		enemies.append(enemy)

func unregister_enemy(enemy: Node2D):
	"""从管理器移除敌人"""
	var index = enemies.find(enemy)
	if index != -1:
		enemies.remove_at(index)

		# 更新玩家数据
		player_data.enemies_defeated += 1

func respawn_player():
	"""重生玩家"""
	if current_checkpoint != "":
		spawn_player_at_checkpoint(current_checkpoint)
	else:
		spawn_player_at_start()

	# 重生音效
	play_sound("respawn")

func reset_game_state():
	"""重置游戏状态"""
	# 清空敌人列表
	enemies.clear()

	# 重置检查点
	checkpoints.clear()
	current_checkpoint = ""

	# 重置玩家数据
	player_data.reset()

	# 重置游戏时间
	game_time = 0.0

func save_level_state(level_name: String):
	"""保存关卡状态"""
	# 保存敌人状态、可收集物品状态等
	# 这里简化实现
	print("保存关卡状态: " + level_name)

func load_level_state(level_name: String):
	"""加载关卡状态"""
	# 加载敌人状态、可收集物品状态等
	# 这里简化实现
	print("加载关卡状态: " + level_name)

func serialize_checkpoints() -> Dictionary:
	"""序列化检查点数据"""
	var serialized = {}
	for key in checkpoints.keys():
		serialized[key] = checkpoints[key].serialize()
	return serialized

func deserialize_checkpoints(data: Dictionary):
	"""反序列化检查点数据"""
	checkpoints.clear()
	for key in data.keys():
		var checkpoint = CheckpointData.new()
		checkpoint.deserialize(data[key])
		checkpoints[key] = checkpoint

func _process(delta: float):
	"""每帧更新"""
	if game_state == GameState.PLAYING and not game_paused:
		game_time += delta

		# 更新玩家数据中的游戏时间
		player_data.play_time = game_time

		# 检查胜利条件
		check_victory_condition()

	# 更新调试信息
	update_debug_info()

func _input(event: InputEvent):
	"""输入处理"""
	if event.is_action_pressed("pause"):
		toggle_pause()

	# 调试快捷键
	if event.is_action_pressed("debug_restart"):
		start_new_game()

	if event.is_action_pressed("debug_save"):
		save_game()

	if event.is_action_pressed("debug_load"):
		load_game()

	if event.is_action_pressed("debug_regenerate"):
		regenerate_level()

	if event.is_action_pressed("debug_clear"):
		clear_enemies()

	if event.is_action_pressed("debug_toggle"):
		toggle_debug_mode()

	if event.is_action_pressed("debug_invincible"):
		toggle_invincible_mode()

	if event.is_action_pressed("debug_one_hit_kill"):
		toggle_one_hit_kill_mode()

	if event.is_action_pressed("debug_infinite_energy"):
		toggle_infinite_energy_mode()

func _on_player_died():
	"""玩家死亡处理"""
	print("玩家死亡")

	# 延迟后重生
	await get_tree().create_timer(2.0).timeout

	if player_data.lives > 0:
		player_data.lives -= 1
		respawn_player()
	else:
		game_over()

func _on_enemy_died(enemy: Node2D, position: Vector2):
	"""敌人死亡处理"""
	# 更新玩家数据已在unregister_enemy中处理
	pass

func _on_checkpoint_reached(checkpoint_id: String, checkpoint_data: CheckpointData):
	"""检查点到达处理"""
	checkpoints[checkpoint_id] = checkpoint_data
	current_checkpoint = checkpoint_id

	# 自动保存
	save_game()

	print("检查点到达: " + checkpoint_id)

func _on_level_completed(level_name: String):
	"""关卡完成处理"""
	print("关卡完成: " + level_name)

	# 根据关卡名决定下一关
	var next_level = get_next_level(level_name)
	if next_level:
		change_level(next_level)
	else:
		# 所有关卡完成，游戏胜利
		victory()

func initialize_audio():
	"""初始化音频系统"""
	# 创建音频总线
	AudioServer.add_bus(1)  # 音乐总线
	AudioServer.add_bus(2)  # 音效总线
	AudioServer.add_bus(3)  # 语音总线

	# 设置总线音量
	AudioServer.set_bus_volume_db(1, -5)   # 音乐
	AudioServer.set_bus_volume_db(2, -10)  # 音效
	AudioServer.set_bus_volume_db(3, -8)   # 语音

	print("音频系统初始化")

func initialize_ui():
	"""初始化UI系统"""
	# 获取GameUI节点（已在Main.tscn中）
	debug_ui_node = get_node_or_null("GameUI")
	if debug_ui_node:
		# 获取调试标签
		debug_label = debug_ui_node.get_node_or_null("HUD/DebugPanel/DebugLabel")
		if debug_label:
			print("调试UI初始化完成")
		else:
			print("警告: 未找到DebugLabel节点")
	else:
		print("警告: 未找到GameUI节点")

func toggle_debug_mode():
	"""切换调试模式"""
	debug_mode = not debug_mode

	if debug_ui_node and debug_label:
		var debug_panel = debug_ui_node.get_node_or_null("HUD/DebugPanel")
		if debug_panel:
			debug_panel.visible = debug_mode

	print("调试模式: " + ("开启" if debug_mode else "关闭"))

func toggle_invincible_mode():
	"""切换无敌模式"""
	invincible_mode = not invincible_mode
	print("无敌模式: " + ("开启" if invincible_mode else "关闭"))

func toggle_one_hit_kill_mode():
	"""切换一击必杀模式"""
	one_hit_kill_mode = not one_hit_kill_mode
	print("一击必杀模式: " + ("开启" if one_hit_kill_mode else "关闭"))

func toggle_infinite_energy_mode():
	"""切换无限能量模式"""
	infinite_energy_mode = not infinite_energy_mode
	print("无限能量模式: " + ("开启" if infinite_energy_mode else "关闭"))

func update_debug_info():
	"""更新调试信息"""
	if not debug_mode or not debug_label:
		return

	var debug_text = ""
	debug_text += "=== 调试信息 ===\n"
	debug_text += "游戏时间: " + str(game_time) + "s\n"
	debug_text += "游戏状态: " + GameState.keys()[game_state] + "\n"
	debug_text += "当前关卡: " + current_level + "\n"
	debug_text += "敌人数量: " + str(enemies.size()) + "\n"
	debug_text += "检查点: " + current_checkpoint + "\n"
	debug_text += "无敌模式: " + ("开启" if invincible_mode else "关闭") + "\n"
	debug_text += "一击必杀: " + ("开启" if one_hit_kill_mode else "关闭") + "\n"
	debug_text += "无限能量: " + ("开启" if infinite_energy_mode else "关闭") + "\n"

	if player and is_instance_valid(player):
		debug_text += "玩家位置: (" + str(player.global_position.x) + ", " + str(player.global_position.y) + ")\n"
		debug_text += "玩家生命: " + str(player.health) + "/" + str(player.max_health if player.has_method("get_max_health") else 100) + "\n"
		if player.has_method("get_shadow_energy"):
			debug_text += "暗影能量: " + str(player.shadow_energy) + "/" + str(player.shadow_energy_max if player.has_method("get_shadow_energy_max") else 100) + "\n"

	debug_text += "\n调试命令:\n"
	debug_text += "F1: 切换调试面板\n"
	debug_text += "F2: 无敌模式\n"
	debug_text += "F3: 一击必杀模式\n"
	debug_text += "F4: 无限能量模式\n"
	debug_text += "F5: 重新开始游戏\n"
	debug_text += "F6: 重新生成关卡\n"
	debug_text += "F7: 清除所有敌人\n"
	debug_text += "F8/F9: 保存/加载游戏\n"

	debug_label.text = debug_text

func play_sound(sound_name: String):
	"""播放音效"""
	# 通过音频管理器播放
	EventBus.emit_signal("play_sound", sound_name)

func play_level_music(level_name: String):
	"""播放关卡音乐"""
	var music_name = "bgm_" + level_name
	EventBus.emit_signal("play_music", music_name)

func show_pause_menu():
	"""显示暂停菜单"""
	EventBus.emit_signal("show_pause_menu")

func hide_pause_menu():
	"""隐藏暂停菜单"""
	EventBus.emit_signal("hide_pause_menu")

func show_game_over_screen():
	"""显示游戏结束画面"""
	EventBus.emit_signal("show_game_over")

func show_victory_screen():
	"""显示胜利画面"""
	EventBus.emit_signal("show_victory")

func show_save_indicator():
	"""显示保存指示器"""
	EventBus.emit_signal("show_save_indicator")

func show_tutorial(tutorial_id: String):
	"""显示教程提示"""
	EventBus.emit_signal("show_tutorial", tutorial_id)

func save_game_settings():
	"""保存游戏设置"""
	var settings = {
		"master_volume": AudioServer.get_bus_volume_db(0),
		"music_volume": AudioServer.get_bus_volume_db(1),
		"sfx_volume": AudioServer.get_bus_volume_db(2),
		"fullscreen": DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
		"vsync": ProjectSettings.get_setting("display/window/vsync/vsync_mode")
	}

	var config_file = ConfigFile.new()
	for key in settings.keys():
		config_file.set_value("settings", key, settings[key])

	config_file.save("user://settings.cfg")
	print("游戏设置已保存")

func load_game_settings():
	"""加载游戏设置"""
	var config_file = ConfigFile.new()
	var error = config_file.load("user://settings.cfg")

	if error == OK:
		# 加载音量设置
		var master_volume = config_file.get_value("settings", "master_volume", -5.0)
		var music_volume = config_file.get_value("settings", "music_volume", -5.0)
		var sfx_volume = config_file.get_value("settings", "sfx_volume", -10.0)

		AudioServer.set_bus_volume_db(0, master_volume)
		AudioServer.set_bus_volume_db(1, music_volume)
		AudioServer.set_bus_volume_db(2, sfx_volume)

		# 加载显示设置
		var fullscreen = config_file.get_value("settings", "fullscreen", false)
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

		var vsync = config_file.get_value("settings", "vsync", 1)
		ProjectSettings.set_setting("display/window/vsync/vsync_mode", vsync)

		print("游戏设置已加载")
	else:
		print("使用默认游戏设置")

func save_completion_data():
	"""保存通关数据"""
	var completion_data = {
		"completion_time": game_time,
		"completion_date": Time.get_date_string_from_system(),
		"enemies_defeated": player_data.enemies_defeated,
		"coins_collected": player_data.coins_collected,
		"secrets_found": player_data.secrets_found
	}

	var completion_file = FileAccess.open("user://completion.dat", FileAccess.WRITE)
	if completion_file:
		completion_file.store_var(completion_data)
		completion_file.close()

func check_victory_condition():
	"""检查胜利条件"""
	# 这里可以检查Boss是否被击败等条件
	pass

func regenerate_level():
	"""重新生成当前关卡（调试功能）"""
	print("调试: 重新生成关卡")

	if current_level != "":
		# 保存当前玩家位置和状态
		var player_pos = Vector2.ZERO
		var player_health = 100
		var player_energy = 100

		if player and is_instance_valid(player):
			player_pos = player.global_position
			player_health = player.health
			player_energy = player.shadow_energy

		# 重新加载关卡
		change_level(current_level)

		# 恢复玩家状态
		if player and is_instance_valid(player):
			player.global_position = player_pos
			player.health = player_health
			player.shadow_energy = player_energy

		print("关卡已重新生成")
	else:
		print("没有当前关卡，无法重新生成")

func clear_enemies():
	"""清除所有敌人（调试功能）"""
	print("调试: 清除所有敌人")

	var enemy_count = enemies.size()
	for enemy in enemies.duplicate():  # 使用副本遍历，因为队列释放会修改原数组
		if is_instance_valid(enemy):
			enemy.queue_free()

	enemies.clear()
	print("已清除 " + str(enemy_count) + " 个敌人")

func get_next_level(current_level_name: String) -> String:
	"""获取下一关卡"""
	var level_order = [
		"castle_exterior",
		"main_hall",
		"catacombs",
		"banquet_hall",
		"clock_tower",
		"throne_room"
	]

	var current_index = level_order.find(current_level_name)
	if current_index != -1 and current_index + 1 < level_order.size():
		return level_order[current_index + 1]

	return ""

# 辅助类
class CheckpointData:
	var level: String
	var position: Vector2
	var player_health: int
	var player_energy: int

	func serialize() -> Dictionary:
		return {
			"level": level,
			"position": {"x": position.x, "y": position.y},
			"player_health": player_health,
			"player_energy": player_energy
		}

	func deserialize(data: Dictionary):
		level = data.get("level", "")
		var pos_data = data.get("position", {"x": 0, "y": 0})
		position = Vector2(pos_data.x, pos_data.y)
		player_health = data.get("player_health", 100)
		player_energy = data.get("player_energy", 100)

# 信号总线（简化版）
class EventBus:
	static var signals := {}

	static func connect(signal_name: String, callable: Callable):
		if not signal_name in signals:
			signals[signal_name] = []
		signals[signal_name].append(callable)

	static func emit_signal(signal_name: String, arg = null):
		if signal_name in signals:
			for callable in signals[signal_name]:
				if arg != null:
					callable.call(arg)
				else:
					callable.call()