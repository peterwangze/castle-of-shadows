# ClockTower.gd - 钟楼关卡完整版

extends Node2D

@export var level_name := "clock_tower"
@export var next_level := "throne_room"

@onready var player_spawn := $PlayerSpawn

func _ready():
	print("加载关卡: 钟楼")
	Game.current_level = level_name
	EventBus.play_music.emit("bgm_clock_tower", 1.0)
	spawn_player()
	connect_signals()

func spawn_player():
	var player_scene = load("res://scenes/player/Player.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.global_position = player_spawn.global_position if player_spawn else Vector2(100, 400)
		add_child(player)

func connect_signals():
	var exit = $LevelExit
	if exit:
		exit.body_entered.connect(_on_exit)

func _on_exit(body):
	if body.is_in_group("player"):
		EventBus.level_completed.emit(level_name)
		Game.change_level(next_level)
