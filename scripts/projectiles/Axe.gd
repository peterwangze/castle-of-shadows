# Axe.gd
# 斧头投掷物 - 抛物线飞行，可多次命中

extends "res://scripts/BaseProjectile.gd"

## 斧头特有属性
@export var gravity := 400.0  # 重力
@export var rotation_speed := 5.0  # 旋转速度
@export var bounce_count := 2  # 弹跳次数
@export var damage_per_bounce := 0.8  # 每次弹跳伤害衰减

var initial_velocity := Vector2.ZERO
var bounces := 0

func _ready():
	super._ready()
	speed = 250.0
	lifetime = 5.0

func initialize(dir: Vector2, spd: float = speed):
	"""初始化斧头（抛物线运动）"""
	direction = dir.normalized()

	# 设置初始速度（包含向上的分量）
	initial_velocity = Vector2(dir.x * spd, -spd * 0.8)
	velocity = initial_velocity

func _physics_process(delta):
	"""物理更新（应用重力）"""
	# 应用重力
	velocity.y += gravity * delta

	# 移动
	position += velocity * delta

	# 旋转斧头
	if sprite:
		sprite.rotation += rotation_speed * (1 if direction.x > 0 else -1)

	# 生命周期检测
	time_alive += delta
	if time_alive >= lifetime:
		on_lifetime_expired()

func on_hit_terrain(body):
	"""落地时弹跳"""
	if bounces < bounce_count:
		bounces += 1

		# 弹跳：反转Y速度并衰减
		velocity.y = -abs(velocity.y) * 0.6
		velocity.x *= 0.8

		# 伤害衰减
		damage = int(damage * damage_per_bounce)

		# 弹跳次数用完
		if bounces >= bounce_count:
			on_hit()
	else:
		on_hit()

func on_hit_enemy(enemy: Node2D):
	"""击中敌人"""
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, global_position)

	# 斧头可以多次命中，不消失
	# 但伤害衰减
	damage = int(damage * 0.7)
