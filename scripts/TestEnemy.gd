# TestEnemy.gd
# 简化测试敌人，用于验证攻击碰撞

extends CharacterBody2D

## 敌人属性
@export var max_health := 30
@export var move_speed := 50.0
@export var attack_damage := 10

## 状态变量
var health: int
var is_alive := true

## 节点引用
@onready var sprite := $Sprite2D
@onready var collision_shape := $CollisionShape2D

func _ready():
	"""敌人初始化"""
	health = max_health
	add_to_group("enemy")
	print("测试敌人生成，生命值: " + str(health))

func _physics_process(delta: float):
	"""物理更新"""
	if not is_alive:
		return

	# 简单左右移动
	velocity.x = move_speed * sin(Time.get_ticks_msec() * 0.001)
	move_and_slide()

func take_damage(damage: int, attacker_position: Vector2) -> bool:
	"""受到伤害"""
	if not is_alive:
		return false

	health -= damage
	print("测试敌人受到伤害: " + str(damage) + ", 剩余生命: " + str(health))

	# 击退效果
	var knockback_direction = (global_position - attacker_position).normalized()
	velocity = knockback_direction * 100 + Vector2.UP * 50

	# 受伤视觉效果
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color.WHITE

	# 死亡检查
	if health <= 0:
		die()

	return true

func die():
	"""敌人死亡"""
	is_alive = false
	print("测试敌人死亡")

	# 死亡视觉效果
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)
	collision_shape.disabled = true

	# 延迟后消失
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_hurtbox_area_entered(area: Area2D):
	"""受到攻击区域进入（备用检测）"""
	print("测试敌人被攻击区域击中")
	# 这里可以处理来自玩家攻击区域的伤害
	# 但伤害已经在take_damage中处理