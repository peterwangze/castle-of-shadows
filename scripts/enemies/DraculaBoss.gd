# DraculaBoss.gd
# 德古拉·暗影 - 最终Boss

extends "res://scripts/enemies/BossBase.gd"

## Boss名称
const BOSS_NAME := "德古拉·暗影"

## 阶段配置
enum Phase {ONE, TWO, THREE}
var current_phase_enum := Phase.ONE

## 攻击模式
enum Attack {MELEE, BAT_SWARM, BLOOD_WAVE, DARK_CHARGE, SOUL_DRAIN}
var current_attack := Attack.MELEE

## 攻击参数
@export var melee_damage := 25
@export var bat_damage := 10
@export var blood_wave_damage := 20
@export var dark_charge_damage := 35

## 特殊能力
var bat_scene: PackedScene
var blood_wave_scene: PackedScene
var attack_hitbox: Area2D

## 状态
var is_attacking := false
var attack_cooldown_timer := 0.0
var teleport_cooldown := 5.0
var teleport_timer := 0.0

func _ready():
	boss_name = BOSS_NAME
	attack_hitbox = get_node_or_null("AttackHitbox")
	super._ready()

	enemy_type = EnemyType.GARGOYLE  # 复用类型
	max_health = 500
	health = max_health
	attack_damage = melee_damage
	coin_reward = 200
	experience_reward = 500

	# 加载子场景
	bat_scene = load("res://scenes/enemies/Bat.tscn")

	# 阶段设置
	phases = 3
	setup_phases()

	print("%s 觉醒！" % BOSS_NAME)

func _physics_process(delta):
	if not is_alive:
		return

	# 更新冷却
	attack_cooldown_timer -= delta
	teleport_timer -= delta

	# 根据阶段选择行为
	match current_phase_enum:
		Phase.ONE:
			phase_one_behavior(delta)
		Phase.TWO:
			phase_two_behavior(delta)
		Phase.THREE:
			phase_three_behavior(delta)

	super._physics_process(delta)

func phase_one_behavior(_delta: float):
	"""第一阶段行为"""
	if not is_attacking and attack_cooldown_timer <= 0:
		choose_attack([Attack.MELEE, Attack.BAT_SWARM])

func phase_two_behavior(_delta: float):
	"""第二阶段行为"""
	if not is_attacking and attack_cooldown_timer <= 0:
		choose_attack([Attack.MELEE, Attack.BAT_SWARM, Attack.BLOOD_WAVE])

func phase_three_behavior(_delta: float):
	"""第三阶段行为"""
	if not is_attacking and attack_cooldown_timer <= 0:
		choose_attack([Attack.MELEE, Attack.BAT_SWARM, Attack.BLOOD_WAVE, Attack.DARK_CHARGE])

	# 第三阶段可以瞬移
	if teleport_timer <= 0 and randf() < 0.3:
		teleport_behind_player()
		teleport_timer = teleport_cooldown

func choose_attack(available_attacks: Array):
	"""选择攻击"""
	current_attack = available_attacks.pick_random()
	execute_attack()

func execute_attack():
	"""执行攻击"""
	is_attacking = true

	match current_attack:
		Attack.MELEE:
			melee_attack()
		Attack.BAT_SWARM:
			bat_swarm_attack()
		Attack.BLOOD_WAVE:
			blood_wave_attack()
		Attack.DARK_CHARGE:
			dark_charge_attack()
		Attack.SOUL_DRAIN:
			soul_drain_attack()

func melee_attack():
	"""近战攻击"""
	animation_player.play("attack")
	await get_tree().create_timer(0.5).timeout

	# 检测命中
	for body in attack_hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(melee_damage, global_position)

	attack_cooldown_timer = 1.5
	is_attacking = false

func bat_swarm_attack():
	"""蝙蝠群攻击"""
	# 生成3-5只蝙蝠
	var bat_count = 3 + current_phase_enum

	for i in range(bat_count):
		var bat = bat_scene.instantiate() if bat_scene else create_fallback_bat()
		if bat:
			bat.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-30, 30))
			get_parent().add_child(bat)

	attack_cooldown_timer = 3.0
	is_attacking = false

func create_fallback_bat() -> CharacterBody2D:
	"""创建备用蝙蝠"""
	var bat = CharacterBody2D.new()
	bat.add_to_group("enemy")
	bat.add_to_group("bat")
	# 简化实现
	return bat

func blood_wave_attack():
	"""血浪攻击"""
	# 创建血浪区域
	var wave = Area2D.new()
	wave.collision_layer = 0
	wave.collision_mask = 1

	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(300, 50)
	collision.shape = rect
	wave.add_child(collision)

	wave.global_position = global_position + Vector2(150 if not sprite.flip_h else -150, 0)
	get_parent().add_child(wave)

	# 检测伤害
	wave.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(blood_wave_damage, global_position)
	)

	# 0.5秒后消失
	await get_tree().create_timer(0.5).timeout
	wave.queue_free()

	attack_cooldown_timer = 4.0
	is_attacking = false

func dark_charge_attack():
	"""暗影冲锋"""
	sprite.modulate = Color(0.5, 0, 0.5, 1.0)

	# 向玩家冲锋
	if Game.player:
		var direction = (Game.player.global_position - global_position).normalized()
		velocity = direction * 400

		await get_tree().create_timer(1.0).timeout
		velocity = Vector2.ZERO

	sprite.modulate = Color.WHITE
	attack_cooldown_timer = 5.0
	is_attacking = false

func soul_drain_attack():
	"""灵魂吸取"""
	# 恢复生命值
	health = min(health + 30, max_health)

	# 对玩家造成伤害
	if Game.player and Game.player.has_method("take_damage"):
		Game.player.take_damage(15, global_position)

	attack_cooldown_timer = 6.0
	is_attacking = false

func teleport_behind_player():
	"""瞬移到玩家身后"""
	sprite.modulate.a = 0
	await get_tree().create_timer(0.2).timeout

	if Game.player:
		var offset = Vector2(80, 0) if Game.player.sprite.flip_h else Vector2(-80, 0)
		global_position = Game.player.global_position + offset

	sprite.modulate.a = 1

func on_phase_enter(phase: int):
	"""阶段转换"""
	super.on_phase_enter(phase)

	match phase:
		2:
			current_phase_enum = Phase.TWO
			print("%s 进入第二阶段 - 血之狂怒！" % BOSS_NAME)
		3:
			current_phase_enum = Phase.THREE
			print("%s 进入最终阶段 - 暗影之王！" % BOSS_NAME)

			# 最终阶段强化
			melee_damage = int(melee_damage * 1.5)
			move_speed *= 1.3

func die():
	"""Boss死亡"""
	print("%s 被击败！" % BOSS_NAME)

	# 特殊死亡动画
	sprite.modulate = Color(0.2, 0, 0.2, 1.0)
	await get_tree().create_timer(2.0).timeout

	# 触发胜利
	EventBus.game_victory.emit()

	super.die()
