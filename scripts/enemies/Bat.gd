# Bat.gd
# 蝙蝠敌人 - 空中飞行，俯冲攻击

extends "res://scripts/EnemyBase.gd"

## 蝙蝠特有属性
@export var fly_speed := 80.0
@export var dive_speed := 200.0
@export var fly_height := 50.0
@export var detection_range := 150.0
@export var dive_damage := 12

var is_diving := false
var dive_target := Vector2.ZERO
var original_y := 0.0
var fly_time := 0.0

func _ready():
	super._ready()
	enemy_type = EnemyType.BAT
	max_health = 15
	health = max_health
	move_speed = fly_speed
	attack_damage = dive_damage
	coin_reward = 5
	experience_reward = 12

	# 蝙蝠不受重力影响
	gravity = 0

	# 记录初始高度
	original_y = global_position.y

func _physics_process(delta):
	if not is_alive:
		return

	fly_time += delta

	if is_diving:
		perform_dive(delta)
	else:
		perform_fly(delta)
		check_for_dive()

	super._physics_process(delta)

func perform_fly(delta: float):
	"""飞行状态"""
	# 波浪形飞行
	var wave_offset = sin(fly_time * 3.0) * 20.0
	var target_y = original_y + wave_offset

	# 水平移动
	velocity.x = move_speed * (1 if not sprite.flip_h else -1)
	velocity.y = (target_y - global_position.y) * 5.0

	# 检测边缘转向
	if is_on_wall():
		sprite.flip_h = not sprite.flip_h

func check_for_dive():
	"""检查是否俯冲攻击"""
	if Game.player and global_position.distance_to(Game.player.global_position) < detection_range:
		# 玩家在下方时俯冲
		if Game.player.global_position.y > global_position.y:
			start_dive()

func start_dive():
	"""开始俯冲"""
	is_diving = true
	dive_target = Game.player.global_position

	# 俯冲动画
	sprite.modulate = Color(1, 0.3, 0.3)

func perform_dive(delta: float):
	"""执行俯冲"""
	var direction = (dive_target - global_position).normalized()
	velocity = direction * dive_speed

	# 到达目标位置后恢复飞行
	if global_position.distance_to(dive_target) < 20:
		end_dive()

	# 超时恢复
	await get_tree().create_timer(2.0).timeout
	if is_diving:
		end_dive()

func end_dive():
	"""结束俯冲"""
	is_diving = false
	sprite.modulate = Color.WHITE
	original_y = global_position.y - fly_height

func take_damage(damage: int, attacker_position: Vector2) -> bool:
	"""受到伤害"""
	# 受伤时取消俯冲
	if is_diving:
		end_dive()

	return super.take_damage(damage, attacker_position)

func die():
	"""死亡"""
	super.die()

	# 掉落
	gravity = 980.0
	velocity = Vector2.ZERO
