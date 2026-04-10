# HolyWater.gd
# 圣水投掷物 - 投掷后在地面产生持续伤害区域

extends "res://scripts/BaseProjectile.gd"

## 圣水特有属性
@export var area_damage := 5  # 区域每秒伤害
@export var area_duration := 3.0  # 区域持续时间
@export var area_radius := 40.0  # 区域半径

var has_landed := false

func on_hit_terrain(_body):
	"""落地时产生伤害区域"""
	if not has_landed:
		has_landed = true
		create_damage_area()

func on_hit_enemy(_enemy):
	"""圣水穿透敌人"""
	pass  # 不消失，继续飞行

func create_damage_area():
	"""创建持续伤害区域"""
	# 停止移动
	velocity = Vector2.ZERO

	# 创建伤害区域
	var damage_area = Area2D.new()
	damage_area.name = "DamageArea"
	damage_area.position = Vector2.ZERO

	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = area_radius
	collision_shape.shape = circle

	damage_area.add_child(collision_shape)
	add_child(damage_area)

	# 连接信号
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)

	# 视觉效果
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 1.0, 0.7)

	# 持续伤害计时器
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_apply_area_damage)

	# 持续时间后消失
	await get_tree().create_timer(area_duration).timeout
	queue_free()

var bodies_in_area := []

func _on_damage_area_body_entered(body):
	"""敌人进入伤害区域"""
	if body.is_in_group("enemy"):
		bodies_in_area.append(body)

func _on_damage_area_body_exited(body):
	"""敌人离开伤害区域"""
	bodies_in_area.erase(body)

func _apply_area_damage():
	"""对区域内敌人造成伤害"""
	for body in bodies_in_area:
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(area_damage, global_position)
