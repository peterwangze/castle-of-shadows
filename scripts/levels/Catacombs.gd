# Catacombs.gd
# 地下墓穴关卡 - 第三关卡

extends Node2D

## 关卡配置
@export var level_name := "catacombs"
@export var next_level := "banquet_hall"

## 节点引用
@onready var player_spawn := $PlayerSpawn
@onready var enemies_container := $Enemies

## 状态
var enemies_defeated := 0
var total_enemies := 0

func _ready():
	print("加载关卡: 地下墓穴")
	Game.current_level = level_name
	EventBus.play_music.emit("bgm_catacombs", 1.0)
	spawn_player()
	connect_signals()

func spawn_player():
	var player_scene = load("res://scenes/player/Player.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.global_position = player_spawn.global_position if player_spawn else Vector2(100, 300)
		add_child(player)

func connect_signals():
	var exit = $LevelExit
	if exit:
		exit.body_entered.connect(_on_exit)

	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		checkpoint.body_entered.connect(_on_checkpoint.bind(checkpoint))

func _on_exit(body):
	if body.is_in_group("player"):
		EventBus.level_completed.emit(level_name)
		Game.change_level(next_level)

func _on_checkpoint(body, checkpoint):
	if body.is_in_group("player"):
		var data = Game.CheckpointData.new()
		data.level = level_name
		data.position = body.global_position
		data.player_health = body.health
		data.player_energy = body.shadow_energy
		EventBus.checkpoint_reached.emit(checkpoint.name, data.serialize())
