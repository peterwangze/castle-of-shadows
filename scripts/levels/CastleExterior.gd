# CastleExterior.gd
# 城堡外围关卡控制器

extends Node2D

## 关卡配置
@export var level_name := "castle_exterior"
@export var next_level := "main_hall"

## 节点引用
@onready var player_spawn := $PlayerSpawn
@onready var enemies_container := $Enemies
@onready var collectibles_container := $Collectibles

## 状态
var enemies_defeated := 0
var total_enemies := 0
var coins_collected := 0
var total_coins := 0

func _ready():
	"""初始化关卡"""
	print("加载关卡: 城堡外围")

	# 注册关卡
	Game.current_level = level_name

	# 计算敌人和收集品数量
	count_level_content()

	# 播放关卡音乐
	EventBus.play_music.emit("bgm_castle_exterior", 1.0)

	# 生成玩家
	spawn_player()

	# 连接敌人信号
	connect_enemy_signals()

	# 连接关卡出口信号
	var exit = $LevelExit
	if exit:
		exit.body_entered.connect(_on_level_exit_body_entered)

	# 连接检查点信号
	var checkpoint = $Checkpoint1
	if checkpoint:
		checkpoint.body_entered.connect(_on_checkpoint_body_entered)

func count_level_content():
	"""计算关卡内容数量"""
	if enemies_container:
		total_enemies = enemies_container.get_child_count()

	if collectibles_container:
		for child in collectibles_container.get_children():
			if child.is_in_group("coin"):
				total_coins += 1

	print("关卡统计: 敌人=%d, 金币=%d" % [total_enemies, total_coins])

func spawn_player():
	"""生成玩家"""
	var player_scene = load("res://scenes/player/Player.tscn")

	# 如果玩家场景不存在，使用简单版
	if not player_scene:
		player_scene = load("res://scenes/DebugTest.tscn")

	if player_scene:
		var player = player_scene.instantiate()
		if player_spawn:
			player.global_position = player_spawn.global_position
		else:
			player.global_position = Vector2(100, 200)
		add_child(player)

		print("玩家生成在: ", player.global_position)

func connect_enemy_signals():
	"""连接敌人信号"""
	if enemies_container:
		for enemy in enemies_container.get_children():
			if enemy.has_signal("died"):
				enemy.died.connect(_on_enemy_died.bind(enemy))

func _on_enemy_died(enemy: Node2D):
	"""敌人死亡处理"""
	enemies_defeated += 1

	# 检查是否清除所有敌人
	if enemies_defeated >= total_enemies:
		on_level_cleared()

func on_level_cleared():
	"""关卡清除"""
	print("关卡清除！")

	# 发射关卡完成事件
	EventBus.level_completed.emit(level_name)

func _on_level_exit_body_entered(body):
	"""关卡出口检测"""
	if body.is_in_group("player"):
		# 进入下一关
		print("进入下一关: ", next_level)
		Game.change_level(next_level)

func _on_checkpoint_body_entered(body):
	"""检查点激活"""
	if body.is_in_group("player"):
		# 保存检查点
		var checkpoint_data = Game.CheckpointData.new()
		checkpoint_data.level = level_name
		checkpoint_data.position = body.global_position
		checkpoint_data.player_health = body.health
		checkpoint_data.player_energy = body.shadow_energy

		EventBus.checkpoint_reached.emit("checkpoint_1", checkpoint_data.serialize())

		# 视觉反馈
		var checkpoint_node = $Checkpoint1
		if checkpoint_node:
			var sprite = checkpoint_node.get_node("Sprite2D")
			if sprite:
				sprite.modulate = Color(0, 1, 0, 1)

func get_progress() -> Dictionary:
	"""获取关卡进度"""
	return {
		"enemies_defeated": enemies_defeated,
		"total_enemies": total_enemies,
		"coins_collected": coins_collected,
		"total_coins": total_coins,
		"completion_rate": float(enemies_defeated) / max(total_enemies, 1) * 100
	}
