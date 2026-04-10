# Gargoyle.gd
# 石像鬼敌人 - 石化状态，快速突袭

extends "res://scripts/EnemyBase.gd"

## 石像鬼特有属性
@export var stone_form_duration := 3.0
@export var charge_speed := 300.0
@export var charge_damage := 25
@export var detection_range := 200.0

var is_stone_form := true
var charge_target := Vector2.ZERO
var is_charging := false

func _ready():
	super._ready()
	enemy_type = EnemyType.GARGOYLE
	max_health = 60
	health = max_health
	move_speed = 0.0  # 石像鬼不主动移动
	attack_damage = charge_damage
	coin_reward = 15
	experience_reward = 35

	# 初始为石化状态
	enter_stone_form()

func _physics_process(delta):
	if not is_alive:
		return

	if is_stone_form:
		check_player_proximity()
	elif is_charging:
		perform_charge(delta)
	else:
		super._physics_process(delta)

func enter_stone_form():
	"""进入石化状态"""
	is_stone_form = true

	# 石化外观
	sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)

	# 无敌状态
	set_collision_layer_value(2, false)

	# 停止移动
	velocity = Vector2.ZERO

func exit_stone_form():
	"""解除石化"""
	is_stone_form = false

	# 恢复外观
	sprite.modulate = Color(1, 1, 1, 1)

	# 恢复碰撞
	set_collision_layer_value(2, true)

	# 开始冲锋
	start_charge()

func check_player_proximity():
	"""检测玩家接近"""
	if not Game.player:
		return

	var distance = global_position.distance_to(Game.player.global_position)
	if distance < detection_range:
		exit_stone_form()

func start_charge():
	"""开始冲锋"""
	if not Game.player:
		return

	is_charging = true
	charge_target = Game.player.global_position

	# 冲锋方向
	var direction = (charge_target - global_position).normalized()
	velocity = direction * charge_speed

	# 冲锋动画
	sprite.modulate = Color(1, 0.5, 0.5, 1.0)

	# 2秒后停止
	await get_tree().create_timer(1.5).timeout
	end_charge()

func perform_charge(delta: float):
	"""执行冲锋"""
	move_and_slide()

	# 撞墙停止
	if is_on_wall():
		end_charge()

func end_charge():
	"""结束冲锋"""
	is_charging = false
	velocity = Vector2.ZERO

	# 短暂休息
	await get_tree().create_timer(1.0).timeout

	# 返回石化状态
	enter_stone_form()

func take_damage(damage: int, attacker_position: Vector2) -> bool:
	"""受到伤害"""
	# 石化状态减伤50%
	if is_stone_form:
		damage = int(damage * 0.5)

	return super.take_damage(damage, attacker_position)
