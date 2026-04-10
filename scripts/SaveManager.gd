# SaveManager.gd
# 存档管理器 - 处理游戏存档和加载
# 配置为 Autoload 单例

extends Node

## ========== 存档配置 ==========
const SAVE_SLOT_COUNT := 3
const AUTO_SAVE_SLOT := -1
const SAVE_VERSION := "1.0.0"

## 当前存档槽
var current_slot := 0

## ========== 存档数据类 ==========
class SaveData:
	var version: String
	var timestamp: int
	var player_data: Dictionary
	var current_level: String
	var current_checkpoint: String
	var game_time: float
	var enemies_defeated: int
	var coins_collected: int
	var secrets_found: Array
	var checkpoints: Dictionary

	func serialize() -> Dictionary:
		return {
			"version": version,
			"timestamp": timestamp,
			"player_data": player_data,
			"current_level": current_level,
			"current_checkpoint": current_checkpoint,
			"game_time": game_time,
			"enemies_defeated": enemies_defeated,
			"coins_collected": coins_collected,
			"secrets_found": secrets_found,
			"checkpoints": checkpoints
		}

	static func deserialize(data: Dictionary) -> SaveData:
		var save = SaveData.new()
		save.version = data.get("version", "1.0.0")
		save.timestamp = data.get("timestamp", 0)
		save.player_data = data.get("player_data", {})
		save.current_level = data.get("current_level", "")
		save.current_checkpoint = data.get("current_checkpoint", "")
		save.game_time = data.get("game_time", 0.0)
		save.enemies_defeated = data.get("enemies_defeated", 0)
		save.coins_collected = data.get("coins_collected", 0)
		save.secrets_found = data.get("secrets_found", [])
		save.checkpoints = data.get("checkpoints", {})
		return save

## ========== 初始化 ==========
func _ready():
	# 连接 EventBus 信号
	EventBus.save_started.connect(_on_save_started)
	EventBus.load_started.connect(_on_load_started)

	print("SaveManager 初始化完成")

## ========== 存档操作 ==========
func save_game(slot: int = -1) -> bool:
	"""保存游戏到指定槽位"""
	if slot == -1:
		slot = current_slot

	var save_data = SaveData.new()
	save_data.version = SAVE_VERSION
	save_data.timestamp = Time.get_unix_time_from_system()

	# 收集玩家数据
	if Game.player_data:
		save_data.player_data = Game.player_data.serialize()
	else:
		save_data.player_data = {}

	save_data.current_level = Game.current_level
	save_data.current_checkpoint = Game.current_checkpoint
	save_data.game_time = Game.game_time

	# 收集统计信息
	if Game.player_data:
		save_data.enemies_defeated = Game.player_data.enemies_defeated
		save_data.coins_collected = Game.player_data.coins_collected
		save_data.secrets_found = Game.player_data.secrets_found

	# 序列化检查点
	save_data.checkpoints = _serialize_checkpoints()

	# 写入文件
	var path = get_save_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)

	if file:
		file.store_var(save_data.serialize())
		file.close()

		# 发射保存完成信号
		EventBus.save_completed.emit(slot, true)
		EventBus.show_save_indicator.emit()

		print("游戏已保存到槽位 %d" % slot)
		return true

	push_error("保存失败：无法写入文件")
	EventBus.save_completed.emit(slot, false)
	return false

func load_game(slot: int) -> bool:
	"""从指定槽位加载游戏"""
	var path = get_save_path(slot)

	if not FileAccess.file_exists(path):
		push_warning("存档不存在：槽位 %d" % slot)
		EventBus.load_completed.emit(slot, false)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("读取失败：无法打开文件")
		EventBus.load_completed.emit(slot, false)
		return false

	var raw_data = file.get_var()
	file.close()

	var save_data = SaveData.deserialize(raw_data)

	# 版本校验
	if not _validate_version(save_data.version):
		push_error("存档版本不兼容：%s vs %s" % [save_data.version, SAVE_VERSION])
		EventBus.load_completed.emit(slot, false)
		return false

	# 恢复游戏状态
	if Game.player_data:
		Game.player_data.deserialize(save_data.player_data)

	Game.current_level = save_data.current_level
	Game.current_checkpoint = save_data.current_checkpoint
	Game.game_time = save_data.game_time

	# 恢复检查点
	_deserialize_checkpoints(save_data.checkpoints)

	current_slot = slot

	# 加载关卡
	if save_data.current_level != "" and save_data.current_level in Game.levels:
		Game.change_level(save_data.current_level)

	print("游戏已从槽位 %d 加载" % slot)
	EventBus.load_completed.emit(slot, true)
	return true

func delete_save(slot: int) -> bool:
	"""删除指定槽位的存档"""
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("存档槽位 %d 已删除" % slot)
		return true
	return false

func auto_save() -> bool:
	"""自动保存"""
	var result = save_game(AUTO_SAVE_SLOT)
	if result:
		print("自动保存完成")
	return result

## ========== 存档槽信息 ==========
func get_save_path(slot: int) -> String:
	"""获取存档文件路径"""
	if slot == AUTO_SAVE_SLOT:
		return "user://autosave.dat"
	return "user://save_slot_%d.dat" % slot

func get_all_save_slots() -> Array[Dictionary]:
	"""获取所有存档槽信息"""
	var slots: Array[Dictionary] = []

	for i in range(SAVE_SLOT_COUNT):
		var path = get_save_path(i)
		var slot_info = {"slot": i, "empty": true}

		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var raw_data = file.get_var()
				var save_data = SaveData.deserialize(raw_data)
				slot_info["empty"] = false
				slot_info["level"] = save_data.current_level
				slot_info["time"] = format_play_time(save_data.game_time)
				slot_info["date"] = Time.get_datetime_string_from_unix_time(save_data.timestamp)
				slot_info["progress"] = calculate_progress(save_data)

		slots.append(slot_info)

	return slots

func has_save(slot: int) -> bool:
	"""检查指定槽位是否有存档"""
	return FileAccess.file_exists(get_save_path(slot))

## ========== 辅助方法 ==========
func _validate_version(save_version: String) -> bool:
	"""版本校验"""
	var current_major = SAVE_VERSION.split(".")[0]
	var save_major = save_version.split(".")[0]
	return current_major == save_major

func _serialize_checkpoints() -> Dictionary:
	"""序列化检查点数据"""
	var serialized := {}
	for key in Game.checkpoints.keys():
		if Game.checkpoints[key] is Game.CheckpointData:
			serialized[key] = Game.checkpoints[key].serialize()
	return serialized

func _deserialize_checkpoints(data: Dictionary):
	"""反序列化检查点数据"""
	Game.checkpoints.clear()
	for key in data.keys():
		var checkpoint = Game.CheckpointData.new()
		checkpoint.deserialize(data[key])
		Game.checkpoints[key] = checkpoint

func format_play_time(seconds: float) -> String:
	"""格式化游戏时间"""
	var hours = int(seconds / 3600)
	var minutes = int((seconds - hours * 3600) / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

func calculate_progress(save_data: SaveData) -> float:
	"""计算游戏进度百分比"""
	var level_order = [
		"castle_exterior",
		"main_hall",
		"catacombs",
		"banquet_hall",
		"clock_tower",
		"throne_room"
	]

	var current_index = level_order.find(save_data.current_level)
	if current_index == -1:
		return 0.0

	return float(current_index + 1) / level_order.size() * 100.0

## ========== 信号回调 ==========
func _on_save_started(slot: int):
	"""保存开始信号回调"""
	save_game(slot)

func _on_load_started(slot: int):
	"""加载开始信号回调"""
	load_game(slot)
