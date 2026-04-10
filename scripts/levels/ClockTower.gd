extends Node2D

@export var level_name := "clock_tower"
@export var next_level := "throne_room"

func _ready():
	Game.current_level = level_name
	EventBus.play_music.emit("bgm_clock_tower", 1.0)
