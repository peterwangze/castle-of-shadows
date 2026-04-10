# BaseProjectile.gd
# 投掷物基类 - 所有副武器的父类

extends Area2D

## 基础属性
@export var damage := 10
@export var speed := 300.0
@export var lifetime := 3.0
@export var knockback_force := 100.0

## 状态
var direction := Vector2.RIGHT
var velocity := Vector2.ZERO
var time_alive := 0.0

## 节点引用
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D

func _ready():
	"""初始化"""
	add_to_group("projectile")

	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	"""物理更新"""
	# 移动
	position += velocity * delta

	# 生命周期检测
	time_alive += delta
	if time_alive >= lifetime:
		on_lifetime_expired()

func initialize(dir: Vector2, spd: float = speed):
	"""初始化投掷物方向和速度"""
	direction = dir.normalized()
	velocity = direction * spd

	# 根据方向翻转精灵
	if sprite and direction.x < 0:
		sprite.flip_h = true

func _on_body_entered(body):
	"""碰撞到实体"""
	if body.is_in_group("enemy"):
		on_hit_enemy(body)
	elif body.is_in_group("terrain") or body.is_in_group("platform"):
		on_hit_terrain(body)

func _on_area_entered(area):
	"""碰撞到区域"""
	if area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			on_hit_enemy(enemy)

func on_hit_enemy(enemy: Node2D):
	"""击中敌人"""
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, global_position)

	# 击退效果
	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(direction * knockback_force)

	# 命中特效
	on_hit()

func on_hit_terrain(_body):
	"""击中地形"""
	on_hit()

func on_hit():
	"""命中处理（子类可重写）"""
	# 默认：消失
	queue_free()

func on_lifetime_expired():
	"""生命周期结束"""
	queue_free()

func set_damage(new_damage: int):
	"""设置伤害"""
	damage = new_damage

func set_speed(new_speed: float):
	"""设置速度"""
	speed = new_speed
	velocity = direction * speed
