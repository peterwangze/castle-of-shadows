extends Node2D

@export var level_name := "throne_room"

func _ready():
	Game.current_level = level_name
	EventBus.play_music.emit("bgm_throne_room", 1.0)
	EventBus.play_music.emit("bgm_boss", 0.5)  # Boss音乐
