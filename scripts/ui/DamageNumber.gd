# DamageNumber.gd
# 伤害数字显示 - 浮动伤害数字效果

extends Node2D

## 动画参数
@export var float_distance := 50.0
@export var float_duration := 0.8
@export var max_scale := 1.5

## 节点引用
@onready var label := $Label

## 状态
var damage_value := 0
var is_critical := false

func _ready():
	"""初始化"""
	# 入场动画
	play_appear_animation()

func setup(damage: int, critical: bool = false):
	"""设置伤害数字"""
	damage_value = damage
	is_critical = critical

	if label:
		label.text = str(damage_value)

		# 暴击显示
		if is_critical:
			label.modulate = Color(1, 0.8, 0, 1)  # 金色
			label.add_theme_font_size_override("font_size", 24)
		else:
			label.modulate = Color(1, 1, 1, 1)
			label.add_theme_font_size_override("font_size", 18)

func play_appear_animation():
	"""播放出现动画"""
	# 缩放动画
	scale = Vector2(0.5, 0.5)
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_BACK)
	scale_tween.tween_property(self, "scale", Vector2(max_scale, max_scale), 0.15)
	scale_tween.tween_property(self, "scale", Vector2(1, 1), 0.1)

	# 上浮动画
	var float_tween = create_tween()
	float_tween.set_parallel()
	float_tween.tween_property(self, "position:y", position.y - float_distance, float_duration)
	float_tween.tween_property(label, "modulate:a", 0.0, float_duration).set_delay(float_duration * 0.5)

	# 水平抖动
	var shake_offset = randf_range(-10, 10)
	float_tween.tween_property(self, "position:x", position.x + shake_offset, float_duration * 0.3)

	# 完成后销毁
	float_tween.tween_callback(queue_free)

func setup_with_position(damage: int, world_position: Vector2, critical: bool = false):
	"""设置伤害数字和位置"""
	global_position = world_position
	setup(damage, critical)
