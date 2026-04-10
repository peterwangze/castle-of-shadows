# EventBus.gd
# 全局事件总线 - 使用 Godot 原生信号系统
# 配置为 Autoload 单例

extends Node

## ========== 游戏生命周期事件 ==========
signal game_started
signal game_paused
signal game_resumed
signal game_over
signal game_victory

## ========== 玩家事件 ==========
signal player_died
signal player_respawned
signal player_level_up(new_level: int)
signal player_health_changed(health: int, max_health: int)
signal player_energy_changed(energy: int, max_energy: int)

## ========== 敌人事件 ==========
signal enemy_died(enemy: Node2D, position: Vector2)
signal enemy_spawned(enemy: Node2D)
signal enemy_damaged(enemy: Node2D, damage: int)

## ========== 战斗事件 ==========
signal damage_dealt(target: Node2D, damage: int, damage_type: String)
signal damage_received(source: Node2D, damage: int)
signal weapon_equipped(weapon_type: int)
signal subweapon_used(subweapon_type: int)
signal attack_performed(attacker: Node2D, attack_data: Dictionary)

## ========== 关卡事件 ==========
signal level_loaded(level_name: String)
signal level_completed(level_name: String)
signal level_transition_started(from_level: String, to_level: String)
signal checkpoint_reached(checkpoint_id: String, checkpoint_data: Dictionary)

## ========== 收集事件 ==========
signal coin_collected(amount: int)
signal item_collected(item_type: String, item_data: Dictionary)
signal secret_found(secret_id: String)
signal achievement_unlocked(achievement_id: String)

## ========== UI事件 ==========
signal show_pause_menu
signal hide_pause_menu
signal show_game_over(stats: Dictionary)
signal show_victory(stats: Dictionary)
signal show_save_indicator
signal show_tutorial(tutorial_id: String)
signal show_dialog(dialog_id: String, speaker: String, text: String)
signal hide_dialog
signal update_hud(data: Dictionary)
signal show_damage_number(position: Vector2, damage: int, is_critical: bool)

## ========== 音频事件 ==========
signal play_sound(sound_name: String, volume_db: float)
signal play_music(music_name: String, fade_duration: float)
signal stop_music(fade_duration: float)
signal pause_music
signal resume_music
signal set_volume(bus_name: String, volume: float)

## ========== 存档事件 ==========
signal save_started(slot: int)
signal save_completed(slot: int, success: bool)
signal load_started(slot: int)
signal load_completed(slot: int, success: bool)
signal auto_save_triggered

## ========== 调试事件 ==========
signal debug_mode_toggled(mode: String, enabled: bool)
signal debug_log(message: String, category: String)
signal debug_draw_requested(draw_data: Dictionary)

## ========== 辅助方法 ==========

func emit_safe(signal_name: String, args: Array = []) -> void:
	"""安全发射信号，避免参数错误"""
	match signal_name:
		"player_died", "player_respawned", "game_started", "game_paused", "game_resumed", "game_over", "game_victory":
			emit(signal_name)
		"player_level_up":
			if args.size() >= 1:
				player_level_up.emit(args[0])
		"player_health_changed":
			if args.size() >= 2:
				player_health_changed.emit(args[0], args[1])
		"player_energy_changed":
			if args.size() >= 2:
				player_energy_changed.emit(args[0], args[1])
		"enemy_died":
			if args.size() >= 2:
				enemy_died.emit(args[0], args[1])
		"enemy_spawned":
			if args.size() >= 1:
				enemy_spawned.emit(args[0])
		"coin_collected":
			if args.size() >= 1:
				coin_collected.emit(args[0])
		"item_collected":
			if args.size() >= 2:
				item_collected.emit(args[0], args[1])
		"level_loaded", "level_completed":
			if args.size() >= 1:
				emit(signal_name, args[0])
		"checkpoint_reached":
			if args.size() >= 2:
				checkpoint_reached.emit(args[0], args[1])
		"play_sound":
			if args.size() >= 1:
				var vol = args[1] if args.size() >= 2 else 0.0
				play_sound.emit(args[0], vol)
		"play_music":
			if args.size() >= 1:
				var fade = args[1] if args.size() >= 2 else 1.0
				play_music.emit(args[0], fade)
		_:
			push_warning("未知信号: " + signal_name)

static func connect_safe(signal_name: String, callable: Callable) -> void:
	"""安全连接信号，避免重复连接"""
	var instance = EventBus
	if not instance:
		push_error("EventBus 单例未初始化")
		return

	if not instance.is_connected(signal_name, callable):
		instance.connect(signal_name, callable)

static func disconnect_safe(signal_name: String, callable: Callable) -> void:
	"""安全断开信号连接"""
	var instance = EventBus
	if not instance:
		return

	if instance.is_connected(signal_name, callable):
		instance.disconnect(signal_name, callable)
