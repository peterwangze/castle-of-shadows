# EnemyBase.gd
# 敌人基础类，所有敌人的父类

extends CharacterBody2D

## 敌人类型枚举
enum EnemyType {
	SKELETON,      # 骷髅士兵
	GHOST,         # 怨灵
	BAT_SWARM,     # 血蝠群
	GARGOYLE,      # 石像鬼
	CORRUPTED,     # 被侵蚀者
	BOSS           # Boss特殊类
}

## 基础属性
@export var enemy_type := EnemyType.SKELETON
@export var max_health := 30
@export var move_speed := 50.0
@export var attack_damage := 10
@export var attack_range := 50.0
@export var sight_range := 150.0
@export var experience_reward := 10
@export var coin_reward := 3
@export var drop_chance := 0.3  # 掉落物品概率

## 状态变量
var health: int
var is_alive := true
var target = null  # 玩家引用
var state = "idle" # 状态机：idle, patrol, chase, attack, hurt, dead
var state_timer := 0.0
var attack_cooldown := 0.0
var patrol_direction := 1  # 巡逻方向：1右，-1左

## 节点引用
@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer
@onready var detection_area := $DetectionArea
@onready var attack_area := $AttackArea
@onready var health_bar := $HealthBar

## 掉落物品配置
var possible_drops := [
	{"type": "coin", "min": 1, "max": 5, "chance": 0.7},
	{"type": "health_potion", "min": 1, "max": 1, "chance": 0.2},
	{"type": "mana_potion", "min": 1, "max": 1, "chance": 0.1},
	{"type": "weapon_upgrade", "min": 1, "max": 1, "chance": 0.05}
]

func _ready():
	"""敌人初始化"""
	health = max_health
	initialize_enemy()
	Game.register_enemy(self)
	print(str(enemy_type) + " 敌人生成")

func _physics_process(delta: float):
	"""物理更新"""
	if not is_alive:
		return

	update_timers(delta)
	update_state(delta)
	update_movement(delta)
	update_animation()

	move_and_slide()

func initialize_enemy():
	"""根据敌人类型初始化特定属性"""
	match enemy_type:
		EnemyType.SKELETON:
			move_speed = 60.0
			max_health = 30
			attack_damage = 12
			sight_range = 120.0
			attack_range = 40.0

		EnemyType.GHOST:
			move_speed = 40.0
			max_health = 20
			attack_damage = 8
			sight_range = 200.0
			attack_range = 80.0
			set_collision_mask_value(1, false)  # 忽略地形碰撞

		EnemyType.BAT_SWARM:
			move_speed = 80.0
			max_health = 15
			attack_damage = 6
			sight_range = 180.0
			attack_range = 30.0

		EnemyType.GARGOYLE:
			move_speed = 0.0  # 初始静止
			max_health = 50
			attack_damage = 15
			sight_range = 100.0
			attack_range = 70.0

		EnemyType.CORRUPTED:
			move_speed = 70.0
			max_health = 40
			attack_damage = 14
			sight_range = 140.0
			attack_range = 45.0

func update_timers(delta: float):
	"""更新所有计时器"""
	if attack_cooldown > 0:
		attack_cooldown -= delta

	if state_timer > 0:
		state_timer -= delta
		if state_timer <= 0:
			on_state_timeout()

func update_state(delta: float):
	"""更新状态机"""
	var player_distance = get_distance_to_player()

	match state:
		"idle":
			process_idle_state(player_distance)

		"patrol":
			process_patrol_state(player_distance)

		"chase":
			process_chase_state(player_distance)

		"attack":
			process_attack_state(player_distance)

		"hurt":
			process_hurt_state()

		"dead":
			process_dead_state()

func process_idle_state(player_distance: float):
	"""空闲状态处理"""
	# 检测玩家
	if player_distance <= sight_range:
		change_state("chase")
		return

	# 空闲一段时间后开始巡逻
	if state_timer <= 0:
		change_state("patrol")
		state_timer = randf_range(2.0, 5.0)  # 巡逻时间

func process_patrol_state(player_distance: float):
	"""巡逻状态处理"""
	# 检测玩家
	if player_distance <= sight_range:
		change_state("chase")
		return

	# 巡逻移动
	velocity.x = patrol_direction * move_speed * 0.5

	# 检查前方障碍
	if is_wall_ahead():
		patrol_direction *= -1
		state_timer = randf_range(1.0, 2.0)  # 转向后暂停

func process_chase_state(player_distance: float):
	"""追逐状态处理"""
	# 玩家超出视野
	if player_distance > sight_range * 1.5:
		change_state("idle")
		return

	# 进入攻击范围
	if player_distance <= attack_range and attack_cooldown <= 0:
		change_state("attack")
		return

	# 追逐玩家
	var direction_to_player = get_direction_to_player()
	velocity.x = direction_to_player.x * move_speed

	# 更新面向
	if direction_to_player.x != 0:
		sprite.flip_h = direction_to_player.x < 0

func process_attack_state(player_distance: float):
	"""攻击状态处理"""
	# 玩家离开攻击范围
	if player_distance > attack_range * 1.2:
		change_state("chase")
		return

	# 执行攻击
	if state_timer <= 0:
		perform_attack()
		state_timer = 1.0  # 攻击后硬直

func process_hurt_state():
	"""受伤状态处理"""
	# 受伤动画结束后恢复
	if state_timer <= 0:
		change_state("chase")

func process_dead_state():
	"""死亡状态处理"""
	if state_timer <= 0:
		queue_free()

func update_movement(delta: float):
	"""更新移动逻辑"""
	# 应用重力（如果需要）
	if enemy_type != EnemyType.GHOST:  # 幽灵不受重力
		if not is_on_floor():
			velocity.y += 980.0 * delta

	# 地面摩擦
	if is_on_floor() and state != "attack" and state != "hurt":
		velocity.x = lerp(velocity.x, 0.0, 0.1)

func update_animation():
	"""更新动画"""
	var anim_suffix = "_" + str(enemy_type).to_lower()
	var anim_name = state + anim_suffix

	# 特殊动画处理
	if state == "chase" and abs(velocity.x) > 10:
		anim_name = "run" + anim_suffix
	elif state == "attack":
		anim_name = "attack" + anim_suffix
	elif state == "hurt":
		anim_name = "hurt" + anim_suffix
	elif state == "dead":
		anim_name = "die" + anim_suffix

	# 播放动画
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func perform_attack():
	"""执行攻击"""
	attack_cooldown = get_attack_cooldown()

	# 播放攻击动画和音效
	animation_player.play("attack_" + str(enemy_type).to_lower())
	play_sound("enemy_attack")

	# 检测攻击命中
	var hit_player = false
	for area in attack_area.get_overlapping_areas():
		if area.is_in_group("player"):
			var player = area.get_parent()
			if player.take_damage(attack_damage, global_position):
				hit_player = true

	# 攻击反馈
	if hit_player:
		play_sound("attack_hit")

func take_damage(damage: int, attacker_position: Vector2) -> bool:
	"""受到伤害"""
	if not is_alive or state == "dead":
		return false

	health -= damage

	# 显示伤害数字
	show_damage_number(damage)

	# 击退效果
	if enemy_type != EnemyType.GHOST:  # 幽灵不受击退
		var knockback_direction = (global_position - attacker_position).normalized()
		velocity = knockback_direction * 100 + Vector2.UP * 50

	# 更新生命条
	update_health_bar()

	# 受伤状态
	if state != "hurt" and state != "dead":
		change_state("hurt")
		state_timer = 0.3  # 受伤硬直时间

	# 音效
	play_sound("enemy_hurt")

	# 死亡检查
	if health <= 0:
		die()

	return true

func die():
	"""敌人死亡"""
	is_alive = false
	change_state("dead")
	state_timer = 1.0  # 死亡后消失时间

	# 给予奖励
	Game.player.add_coins(coin_reward)
	Game.player.gain_experience(experience_reward)

	# 掉落物品
	try_drop_item()

	# 音效
	play_sound("enemy_death")

	# 从游戏管理器移除
	Game.unregister_enemy(self)

	# 死亡动画
	animation_player.play("die_" + str(enemy_type).to_lower())

func try_drop_item():
	"""尝试掉落物品"""
	for drop_config in possible_drops:
		if randf() <= drop_config.chance:
			drop_item(drop_config)
			break

func drop_item(drop_config: Dictionary):
	"""生成掉落物品"""
	var item_scene_path = "res://scenes/items/"
	match drop_config.type:
		"coin":
			item_scene_path += "Coin.tscn"
		"health_potion":
			item_scene_path += "HealthPotion.tscn"
		"mana_potion":
			item_scene_path += "ManaPotion.tscn"
		"weapon_upgrade":
			item_scene_path += "WeaponUpgrade.tscn"

	var item_scene = load(item_scene_path)
	if item_scene:
		var item = item_scene.instantiate()
		item.global_position = global_position
		get_parent().add_child(item)

func change_state(new_state: String):
	"""改变状态"""
	if state == new_state:
		return

	var old_state = state
	state = new_state

	# 状态进入逻辑
	match new_state:
		"idle":
			velocity.x = 0
			state_timer = randf_range(1.0, 3.0)

		"patrol":
			patrol_direction = 1 if randf() > 0.5 else -1
			state_timer = randf_range(3.0, 6.0)

		"chase":
			play_sound("enemy_alert")

		"attack":
			velocity.x = 0

		"hurt":
			sprite.modulate = Color.RED

		"dead":
			set_collision_layer_value(1, false)
			set_collision_mask_value(1, false)

	# 状态退出清理
	if old_state == "hurt":
		sprite.modulate = Color.WHITE

	print(str(enemy_type) + " 状态改变: " + old_state + " -> " + new_state)

func on_state_timeout():
	"""状态超时处理"""
	match state:
		"idle":
			change_state("patrol")

		"patrol":
			change_state("idle")

		"attack":
			change_state("chase")

func get_distance_to_player() -> float:
	"""获取到玩家的距离"""
	if not Game.player:
		return INF
	return global_position.distance_to(Game.player.global_position)

func get_direction_to_player() -> Vector2:
	"""获取到玩家的方向"""
	if not Game.player:
		return Vector2.ZERO
	return (Game.player.global_position - global_position).normalized()

func is_wall_ahead() -> bool:
	"""检查前方是否有墙壁"""
	var ray_length = 32.0
	var ray_direction = Vector2.RIGHT if patrol_direction > 0 else Vector2.LEFT

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + ray_direction * ray_length,
		collision_mask
	)
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	return result.size() > 0

func update_health_bar():
	"""更新生命条显示"""
	if health_bar:
		var health_percent = float(health) / max_health
		health_bar.value = health_percent
		health_bar.visible = health_percent < 1.0

func show_damage_number(damage: int):
	"""显示伤害数字"""
	var damage_scene = load("res://scenes/ui/DamageNumber.tscn")
	if damage_scene:
		var damage_number = damage_scene.instantiate()
		damage_number.setup(damage, global_position)
		get_parent().add_child(damage_number)

func get_attack_cooldown() -> float:
	"""获取攻击冷却时间"""
	match enemy_type:
		EnemyType.SKELETON: return 1.5
		EnemyType.GHOST: return 2.0
		EnemyType.BAT_SWARM: return 1.0
		EnemyType.GARGOYLE: return 3.0
		EnemyType.CORRUPTED: return 1.8
		_: return 2.0

func play_sound(sound_name: String):
	"""播放音效"""
	# 实际实现会使用音频管理器
	print("敌人音效: " + sound_name)

func _on_detection_area_body_entered(body: Node2D):
	"""检测区域有物体进入"""
	if body.is_in_group("player"):
		target = body
		if state == "idle" or state == "patrol":
			change_state("chase")

func _on_detection_area_body_exited(body: Node2D):
	"""检测区域有物体退出"""
	if body == target:
		target = null

func _on_attack_area_body_entered(body: Node2D):
	"""攻击区域有物体进入"""
	if body.is_in_group("player") and state == "chase" and attack_cooldown <= 0:
		change_state("attack")