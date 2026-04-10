# Skeleton.gd
# 骷髅敌人 - 继承自 EnemyBase

extends "res://scripts/EnemyBase.gd"

## 骷髅特有属性
@export var bone_throw_damage := 8
@export var bone_throw_speed := 150.0
@export var bone_throw_interval := 3.0

var bone_throw_timer := 0.0

func _ready():
	super._ready()
	enemy_type = EnemyType.SKELETON
	max_health = 30
	health = max_health
	move_speed = 40.0
	attack_damage = 10
	coin_reward = 5
	experience_reward = 15

func _physics_process(delta):
	super._physics_process(delta)

	# 骨头投掷计时
	if current_state == "chase" or current_state == "patrol":
		bone_throw_timer += delta
		if bone_throw_timer >= bone_throw_interval:
			throw_bone()
			bone_throw_timer = 0.0

func throw_bone():
	"""投掷骨头"""
	if not Game.player:
		return

	# 创建骨头投射物
	var bone = create_bone_projectile()
	if bone:
		# 向玩家方向投掷
		var direction = (Game.player.global_position - global_position).normalized()
		bone.initialize(direction, bone_throw_speed)

		# 添加到场景
		get_parent().add_child(bone)

		# 动画
		play_sound("skeleton_throw")

func create_bone_projectile():
	"""创建骨头投射物"""
	var bone = Area2D.new()
	bone.name = "Bone"

	# 碰撞形状
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 4
	collision.shape = circle
	bone.add_child(collision)

	# 精灵
	var sprite = Sprite2D.new()
	sprite.modulate = Color(1, 1, 0.8)  # 淡黄色
	sprite.scale = Vector2(0.3, 0.3)
	bone.add_child(sprite)

	# 脚本
	bone.script = create_bone_script()

	return bone

func create_bone_script() -> GDScript:
	"""创建骨头脚本"""
	var script = GDScript.new()
	script.source_code = """
extends Area2D

var direction := Vector2.RIGHT
var speed := 150.0
var damage := 8

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta

func initialize(dir: Vector2, spd: float):
	direction = dir.normalized()
	speed = spd

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
	elif body.is_in_group("terrain"):
		queue_free()
"""
	script.reload()
	return script

func on_attack():
	"""攻击时调用"""
	super.on_attack()
	# 骷髅攻击时有概率投掷骨头
	if randf() < 0.3:
		throw_bone()
