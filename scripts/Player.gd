# Player.gd
# 玩家控制脚本 - 艾登·夜行者

extends CharacterBody2D

## 玩家属性
@export var max_health := 100
@export var move_speed := 200.0
@export var jump_velocity := -400.0
@export var double_jump_velocity := -300.0
@export var air_control_factor := 0.7
@export var attack_damage := 15
@export var shadow_energy_max := 100
@export var shadow_energy_regen := 5  # 每秒恢复

## 状态变量
var health: int
var shadow_energy: int
var coins: int = 0
var is_alive := true
var double_jump_available := false
var is_dashing := false
var dash_cooldown := 0.0
var attack_cooldown := 0.0
var is_in_shadow_form := false
var shadow_form_timer := 0.0

## 装备系统
enum WeaponType {SWORD, AXE, MACE}
var current_weapon := WeaponType.SWORD
var weapon_damage_multiplier := {
	WeaponType.SWORD: 1.0,
	WeaponType.AXE: 1.3,
	WeaponType.MACE: 1.5
}

enum SubWeapon {NONE, HOLY_WATER, KNIFE, AXE, CROSS}
var current_subweapon := SubWeapon.NONE
var subweapon_ammo := {
	SubWeapon.HOLY_WATER: 5,
	SubWeapon.KNIFE: 10,
	SubWeapon.AXE: 3,
	SubWeapon.CROSS: 1
}

## 节点引用
@onready var sprite := $Sprite2D
@onready var animation_player := $AnimationPlayer
@onready var attack_hitbox := $AttackHitbox
@onready var shadow_particles := $ShadowParticles
@onready var camera := $Camera2D

## 输入变量
var input_direction := Vector2.ZERO
var is_jumping := false
var is_attacking := false
var is_using_subweapon := false
var is_dash_pressed := false

## 物理常量
const GRAVITY := 980.0
const DASH_SPEED := 500.0
const DASH_DURATION := 0.2
const DASH_COOLDOWN_TIME := 0.5
const ATTACK_COOLDOWN_TIME := 0.3
const SHADOW_FORM_DURATION := 3.0
const SHADOW_FORM_COST := 30

func _ready():
	"""初始化玩家"""
	health = max_health
	shadow_energy = shadow_energy_max
	setup_camera()
	Game.player = self
	print("玩家初始化完成 - 艾登准备就绪")

func _physics_process(delta: float):
	"""每帧物理更新"""
	if not is_alive:
		return

	process_input()
	update_timers(delta)
	process_movement(delta)
	process_abilities(delta)
	update_animation()
	update_hud()

	# 应用移动
	move_and_slide()

func process_input():
	"""处理玩家输入"""
	input_direction.x = Input.get_axis("move_left", "move_right")
	is_jumping = Input.is_action_just_pressed("jump")
	is_attacking = Input.is_action_just_pressed("attack")
	is_using_subweapon = Input.is_action_just_pressed("subweapon")
	is_dash_pressed = Input.is_action_just_pressed("dash")

func process_movement(delta: float):
	"""处理移动逻辑"""
	# 应用重力
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 地面移动
	if is_on_floor():
		double_jump_available = true

		# 地面水平移动
		var target_velocity = input_direction.x * move_speed
		if is_dashing and dash_cooldown <= 0:
			start_dash()

		velocity.x = lerp(velocity.x, target_velocity, 0.2)

		# 跳跃
		if is_jumping:
			velocity.y = jump_velocity
			play_sound("jump")

	# 空中移动
	else:
		# 空中控制（减少）
		var air_speed = move_speed * air_control_factor
		var target_velocity = input_direction.x * air_speed
		velocity.x = lerp(velocity.x, target_velocity, 0.1)

		# 二段跳
		if is_jumping and double_jump_available:
			velocity.y = double_jump_velocity
			double_jump_available = false
			play_sound("double_jump")

		# 空中冲刺
		if is_dash_pressed and dash_cooldown <= 0 and shadow_energy >= 10:
			start_dash()

func process_abilities(delta: float):
	"""处理特殊能力"""
	# 攻击
	if is_attacking and attack_cooldown <= 0:
		perform_attack()

	# 副武器
	if is_using_subweapon and current_subweapon != SubWeapon.NONE:
		use_subweapon()

	# 暗影形态
	if Input.is_action_pressed("shadow_form") and not is_in_shadow_form:
		activate_shadow_form()

	# 暗影形态持续
	if is_in_shadow_form:
		shadow_form_timer -= delta
		if shadow_form_timer <= 0:
			deactivate_shadow_form()

	# 能量恢复
	if not is_in_shadow_form:
		shadow_energy = min(shadow_energy + shadow_energy_regen * delta, shadow_energy_max)

func perform_attack():
	"""执行攻击"""
	attack_cooldown = ATTACK_COOLDOWN_TIME

	# 计算伤害
	var damage = attack_damage * weapon_damage_multiplier[current_weapon]

	# 动画和音效
	animation_player.play("attack_" + str(current_weapon).to_lower())
	play_sound("attack")

	# 检测命中
	var hit_enemies = []
	for area in attack_hitbox.get_overlapping_areas():
		if area.is_in_group("enemy"):
			var enemy = area.get_parent()
			if enemy.take_damage(damage, global_position):
				hit_enemies.append(enemy)

	# 击中反馈
	if hit_enemies.size() > 0:
		# 轻微击退
		velocity.x = -100 if sprite.flip_h else 100
		# 屏幕震动
		camera.add_trauma(0.3)
		# 击中音效
		play_sound("hit_enemy")

func use_subweapon():
	"""使用副武器"""
	if current_subweapon == SubWeapon.NONE:
		return

	# 检查弹药
	if subweapon_ammo[current_subweapon] <= 0:
		play_sound("out_of_ammo")
		return

	# 消耗弹药
	subweapon_ammo[current_subweapon] -= 1

	match current_subweapon:
		SubWeapon.HOLY_WATER:
			throw_holy_water()
		SubWeapon.KNIFE:
			throw_knife()
		SubWeapon.AXE:
			throw_axe()
		SubWeapon.CROSS:
			use_cross()

	play_sound("subweapon_" + str(current_subweapon).to_lower())

func throw_holy_water():
	"""投掷圣水瓶"""
	var holy_water_scene = load("res://scenes/projectiles/HolyWater.tscn")
	var holy_water = holy_water_scene.instantiate()
	holy_water.direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
	holy_water.global_position = global_position + Vector2(0, -16)
	get_parent().add_child(holy_water)

func throw_knife():
	"""投掷匕首"""
	var knife_scene = load("res://scenes/projectiles/Knife.tscn")
	var knife = knife_scene.instantiate()
	knife.direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
	knife.global_position = global_position + Vector2(0, -8)
	get_parent().add_child(knife)

func throw_axe():
	"""投掷斧头（抛物线）"""
	var axe_scene = load("res://scenes/projectiles/Axe.tscn")
	var axe = axe_scene.instantiate()
	axe.direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
	axe.velocity = Vector2(300 if not sprite.flip_h else -300, -200)
	axe.global_position = global_position + Vector2(0, -16)
	get_parent().add_child(axe)

func use_cross():
	"""使用十字架（全屏攻击）"""
	var cross_scene = load("res://scenes/projectiles/Cross.tscn")
	var cross = cross_scene.instantiate()
	cross.global_position = global_position
	get_parent().add_child(cross)

func activate_shadow_form():
	"""激活暗影形态"""
	if shadow_energy < SHADOW_FORM_COST:
		return

	shadow_energy -= SHADOW_FORM_COST
	is_in_shadow_form = true
	shadow_form_timer = SHADOW_FORM_DURATION

	# 视觉效果
	shadow_particles.emitting = true
	sprite.modulate = Color(0.5, 0.5, 1.0, 0.7)
	collision_layer = 0  # 暂时无碰撞
	collision_mask = 0

	# 音效
	play_sound("shadow_form")

	# 能力增强
	move_speed *= 1.5
	jump_velocity *= 1.2

func deactivate_shadow_form():
	"""退出暗影形态"""
	is_in_shadow_form = false

	# 恢复视觉效果
	shadow_particles.emitting = false
	sprite.modulate = Color.WHITE
	collision_layer = 1
	collision_mask = 1

	# 恢复能力
	move_speed /= 1.5
	jump_velocity /= 1.2

func start_dash():
	"""开始冲刺"""
	if shadow_energy < 10:
		return

	shadow_energy -= 10
	is_dashing = true
	dash_cooldown = DASH_COOLDOWN_TIME

	# 冲刺速度
	var dash_direction = Vector2.RIGHT if input_direction.x > 0 else Vector2.LEFT
	if input_direction.x == 0:
		dash_direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT

	velocity = dash_direction * DASH_SPEED

	# 特效
	animation_player.play("dash")
	play_sound("dash")

	# 短暂无敌
	set_invincible(0.2)

func take_damage(damage: int, attacker_position: Vector2):
	"""受到伤害"""
	if not is_alive or is_in_shadow_form:
		return false

	# 计算实际伤害（考虑防御）
	var actual_damage = max(1, damage - 5)  # 简单防御计算
	health -= actual_damage

	# 击退效果
	var knockback_direction = (global_position - attacker_position).normalized()
	velocity = knockback_direction * 200 + Vector2.UP * 150

	# 视觉效果
	animation_player.play("hit")
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_callback(func(): sprite.modulate = Color.WHITE).set_delay(0.2)

	# 屏幕震动
	camera.add_trauma(0.5)

	# 音效
	play_sound("player_hurt")

	# 死亡检查
	if health <= 0:
		die()

	return true

func die():
	"""玩家死亡"""
	is_alive = false
	animation_player.play("death")
	play_sound("player_death")

	# 停止所有移动
	velocity = Vector2.ZERO
	set_physics_process(false)

	# 死亡后处理
	await get_tree().create_timer(2.0).timeout
	Game.respawn_player()

func heal(amount: int):
	"""治疗玩家"""
	health = min(health + amount, max_health)
	play_sound("heal")

func add_coins(amount: int):
	"""添加金币"""
	coins += amount
	play_sound("coin")

func update_timers(delta: float):
	"""更新所有冷却计时器"""
	if dash_cooldown > 0:
		dash_cooldown -= delta
		if dash_cooldown <= 0:
			is_dashing = false

	if attack_cooldown > 0:
		attack_cooldown -= delta

func update_animation():
	"""更新角色动画"""
	if not is_alive:
		return

	var anim_name = "idle"

	# 根据状态选择动画
	if is_in_shadow_form:
		anim_name = "shadow_" + ("idle" if velocity.x == 0 else "run")
	elif abs(velocity.x) > 10:
		anim_name = "run"
		sprite.flip_h = velocity.x < 0
	elif not is_on_floor():
		anim_name = "jump" if velocity.y < 0 else "fall"

	# 播放动画（如果不在攻击中）
	if not animation_player.current_animation.begins_with("attack"):
		animation_player.play(anim_name)

func update_hud():
	"""更新HUD显示（简化版）"""
	if Game.player_data:
		Game.player_data.health = health
		Game.player_data.max_health = max_health
		Game.player_data.shadow_energy = shadow_energy
		Game.player_data.coins = coins

func setup_camera():
	"""设置相机"""
	if camera:
		camera.limit_left = -1000
		camera.limit_right = 1000
		camera.limit_top = -1000
		camera.limit_bottom = 1000
		camera.drag_margin_h_enabled = true
		camera.drag_margin_v_enabled = true

func set_invincible(duration: float):
	"""设置短暂无敌"""
	set_collision_layer_value(2, false)  # 暂时禁用敌人碰撞层
	sprite.modulate = Color(1, 1, 1, 0.5)

	await get_tree().create_timer(duration).timeout

	if is_alive:
		set_collision_layer_value(2, true)
		sprite.modulate = Color.WHITE

func play_sound(sound_name: String):
	"""播放音效（简化实现）"""
	# 实际实现会使用音频管理器
	print("播放音效: ", sound_name)

func _on_hurtbox_area_entered(area: Area2D):
	"""受到攻击区域进入"""
	if area.is_in_group("enemy_attack"):
		var enemy = area.get_parent()
		var damage = enemy.attack_damage if enemy.has_method("get_attack_damage") else 10
		take_damage(damage, enemy.global_position)

func _on_collectible_area_entered(area: Area2D):
	"""收集品区域进入"""
	if area.is_in_group("coin"):
		add_coins(area.value if area.has_method("get_value") else 1)
		area.queue_free()
	elif area.is_in_group("health_potion"):
		heal(area.heal_amount if area.has_method("get_heal_amount") else 20)
		area.queue_free()
	elif area.is_in_group("weapon"):
		equip_weapon(area.weapon_type)
		area.queue_free()

func equip_weapon(weapon_type: WeaponType):
	"""装备武器"""
	current_weapon = weapon_type
	play_sound("equip_weapon")
	print("装备武器: ", weapon_type)