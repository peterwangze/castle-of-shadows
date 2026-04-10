# MainHall.gd
# 主大厅关卡控制器 - 第二关卡

extends Node2D

## 关卡配置
@export var level_name := "main_hall"
@export var next_level := "catacombs"

## 节点引用
@onready var player_spawn := $PlayerSpawn
@onready var enemies_container := $Enemies
@onready var collectibles_container := $Collectibles

## 状态
var enemies_defeated := 0
var total_enemies := 0
var coins_collected := 0
var total_coins := 0
var boss_defeated := false

func _ready():
	"""初始化关卡"""
	print("加载关卡: 主大厅")

	# 注册关卡
	Game.current_level = level_name

	# 计算关卡内容
	count_level_content()

	# 播放关卡音乐
	EventBus.play_music.emit("bgm_main_hall", 1.0)

	# 生成玩家
	spawn_player()

	# 连接信号
	connect_signals()

func count_level_content():
	"""计算关卡内容"""
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
	if not player_scene:
		player_scene = load("res://scenes/DebugTest.tscn")

	if player_scene:
		var player = player_scene.instantiate()
		if player_spawn:
			player.global_position = player_spawn.global_position
		else:
			player.global_position = Vector2(100, 200)
		add_child(player)

func connect_signals():
	"""连接信号"""
	# 关卡出口
	var exit = $LevelExit
	if exit:
		exit.body_entered.connect(_on_level_exit_body_entered)

	# 检查点
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		if checkpoint.is_in_parent_tree(self):
			checkpoint.body_entered.connect(_on_checkpoint_body_entered.bind(checkpoint))

func _on_level_exit_body_entered(body):
	"""关卡出口"""
	if body.is_in_group("player"):
		if boss_defeated or enemies_defeated >= total_enemies * 0.8:
			print("进入下一关: ", next_level)
			EventBus.level_completed.emit(level_name)
			Game.change_level(next_level)

func _on_checkpoint_body_entered(body, checkpoint):
	"""检查点激活"""
	if body.is_in_group("player"):
		var checkpoint_data = Game.CheckpointData.new()
		checkpoint_data.level = level_name
		checkpoint_data.position = body.global_position
		checkpoint_data.player_health = body.health
		checkpoint_data.player_energy = body.shadow_energy

		EventBus.checkpoint_reached.emit(checkpoint.name, checkpoint_data.serialize())

		# 视觉反馈
		var sprite = checkpoint.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = Color(0, 1, 0, 1)

func _on_boss_defeated():
	"""Boss被击败"""
	boss_defeated = true
	print("Boss被击败！可以离开关卡了。")

	# 开启出口
	var exit = $LevelExit
	if exit:
		var sprite = exit.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = Color(0, 1, 0, 1)
