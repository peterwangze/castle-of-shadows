# ThroneRoom.gd - 王座室（最终Boss战）

extends Node2D

@export var level_name := "throne_room"

@onready var player_spawn := $PlayerSpawn
@onready var boss_spawn := $BossSpawn
@onready var boss_node := $DraculaBoss

var boss: CharacterBody2D = null

func _ready():
	print("加载关卡: 王座室 - 最终决战")
	Game.current_level = level_name

	# 连接胜利信号
	EventBus.game_victory.connect(_on_game_victory)

	spawn_player()
	setup_boss()

func spawn_player():
	"""生成玩家"""
	var player_scene = load("res://scenes/player/Player.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.global_position = player_spawn.global_position if player_spawn else Vector2(150, 340)
		add_child(player)
		print("玩家在王座室生成")

func setup_boss():
	"""设置Boss"""
	if boss_node:
		boss = boss_node
		print("德古拉Boss已就位")
	elif boss_spawn:
		# 如果场景中没有Boss，动态生成
		var boss_scene = load("res://scenes/enemies/DraculaBoss.tscn")
		if boss_scene:
			boss = boss_scene.instantiate()
			boss.global_position = boss_spawn.global_position
			add_child(boss)
			print("动态生成德古拉Boss")

	# 播放Boss音乐
	EventBus.play_music.emit("bgm_boss", 1.0)

func _on_game_victory():
	"""游戏胜利处理"""
	print("游戏胜利！德古拉被击败！")

	# 显示胜利画面
	await get_tree().create_timer(2.0).timeout

	# 切换到胜利场景
	var victory_scene = load("res://scenes/ui/Victory.tscn")
	if victory_scene:
		get_tree().change_scene_to_packed(victory_scene)
	else:
		# 如果没有胜利场景，返回主菜单
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
