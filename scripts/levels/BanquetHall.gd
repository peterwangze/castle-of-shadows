# BanquetHall.gd - 第四关卡
# ClockTower.gd - 第五关卡
# ThroneRoom.gd - 第六关卡（最终Boss）

extends Node2D

@export var level_name := "banquet_hall"
@export var next_level := "clock_tower"

func _ready():
	Game.current_level = level_name
	EventBus.play_music.emit("bgm_banquet_hall", 1.0)
