# Knife.gd
# 匕首投掷物 - 快速直线飞行，可穿透敌人

extends "res://scripts/BaseProjectile.gd"

## 匕首特有属性
@export var penetration_count := 3  # 穿透次数
@export var damage_reduction_per_hit := 0.2  # 每次穿透伤害衰减

var hits := 0

func _ready():
	super._ready()
	speed = 500.0  # 匕首速度较快
	lifetime = 2.0

func on_hit_enemy(enemy: Node2D):
	"""击中敌人"""
	if enemy.has_method("take_damage"):
		# 计算衰减后的伤害
		var current_damage = damage * pow(1.0 - damage_reduction_per_hit, hits)
		enemy.take_damage(int(current_damage), global_position)

	hits += 1

	# 检查穿透次数
	if hits >= penetration_count:
		on_hit()
	else:
		# 视觉反馈：穿透后稍微变淡
		if sprite:
			sprite.modulate.a = 1.0 - (hits * 0.2)
