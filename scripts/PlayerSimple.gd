# PlayerSimple.gd
# 简化版玩家控制脚本 - 用于调试

extends CharacterBody2D

## 基础属性
@export var max_health := 100
@export var move_speed := 200.0
@export var jump_velocity := -400.0
@export var double_jump_velocity := -300.0
@export var attack_damage := 15

## 状态变量
var health: int
var is_alive := true
var double_jump_available := false
var is_dashing := false
var dash_cooldown := 0.0
var attack_cooldown := 0.0

## 节点引用
@onready var sprite := $Sprite2D
@onready var camera := $Camera2D
var health_label: Label
var attack_area: Area2D

## 输入变量
var input_direction := Vector2.ZERO
var is_jumping := false
var is_attacking := false

## 物理常量
const GRAVITY := 980.0
const DASH_SPEED := 500.0
const DASH_DURATION := 0.2
const DASH_COOLDOWN_TIME := 0.5
const ATTACK_COOLDOWN_TIME := 0.3

func _ready():
	"""初始化玩家"""
	health = max_health
	print("简化版玩家初始化完成")
	print("控制说明:")
	print("  左右方向键/A/D: 移动")
	print("  上方向键/W/空格: 跳跃")
	print("  J/鼠标左键: 攻击")
	print("  Shift: 冲刺")

	# 初始化UI
	setup_ui()

	# 设置相机
	setup_camera()

	# 设置攻击检测区域
	setup_attack_hitbox()

func _physics_process(delta: float):
	"""每帧物理更新"""
	if not is_alive:
		return

	process_input()
	update_timers(delta)
	process_movement(delta)
	process_attack()
	update_animation()
	update_ui()

	# 应用移动
	move_and_slide()

func process_input():
	"""处理玩家输入"""
	input_direction.x = Input.get_axis("move_left", "move_right")
	is_jumping = Input.is_action_just_pressed("jump")
	is_attacking = Input.is_action_just_pressed("attack")

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
		velocity.x = lerp(velocity.x, target_velocity, 0.2)

		# 跳跃
		if is_jumping:
			velocity.y = jump_velocity
			print("跳跃!")

	# 空中移动
	else:
		# 空中控制（减少）
		var air_speed = move_speed * 0.7
		var target_velocity = input_direction.x * air_speed
		velocity.x = lerp(velocity.x, target_velocity, 0.1)

		# 二段跳
		if is_jumping and double_jump_available:
			velocity.y = double_jump_velocity
			double_jump_available = false
			print("二段跳!")

		# 冲刺
		if Input.is_action_just_pressed("dash") and dash_cooldown <= 0:
			start_dash()

func process_attack():
	"""处理攻击"""
	if is_attacking and attack_cooldown <= 0:
		perform_attack()

func perform_attack():
	"""执行攻击"""
	attack_cooldown = ATTACK_COOLDOWN_TIME

	print("攻击! 伤害: " + str(attack_damage))

	# 启用攻击检测
	if attack_area:
		# 更新攻击区域位置（根据玩家朝向）
		var attack_shape = attack_area.get_child(0) as CollisionShape2D
		if attack_shape:
			# 根据玩家朝向设置位置
			if sprite.flip_h:  # 面向左
				attack_shape.position = Vector2(-20, 0)
			else:  # 面向右
				attack_shape.position = Vector2(20, 0)

		attack_area.monitoring = true
		attack_area.monitorable = true

		# 检测攻击命中
		var hit_enemies = []
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("enemy"):
				# 对敌人造成伤害
				if body.has_method("take_damage"):
					if body.take_damage(attack_damage, global_position):
						hit_enemies.append(body)

		# 攻击反馈
		if hit_enemies.size() > 0:
			print("击中 " + str(hit_enemies.size()) + " 个敌人!")
			# 轻微击退
			velocity.x = -100 if sprite.flip_h else 100
		else:
			print("未击中敌人")

		# 短暂后禁用检测
		await get_tree().create_timer(0.1).timeout
		attack_area.monitoring = false
		attack_area.monitorable = false
	else:
		print("警告: 攻击区域未初始化")

	# 简单攻击效果
	sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

	# 屏幕轻微震动
	camera.offset = Vector2(randf_range(-2, 2), randf_range(-2, 2))
	await get_tree().create_timer(0.05).timeout
	camera.offset = Vector2.ZERO

func start_dash():
	"""开始冲刺"""
	is_dashing = true
	dash_cooldown = DASH_COOLDOWN_TIME

	# 冲刺速度
	var dash_direction = Vector2.RIGHT if input_direction.x > 0 else Vector2.LEFT
	if input_direction.x == 0:
		dash_direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT

	velocity = dash_direction * DASH_SPEED

	print("冲刺!")

	# 冲刺视觉效果
	sprite.modulate = Color(0.8, 0.8, 1.0, 0.8)
	await get_tree().create_timer(DASH_DURATION).timeout
	sprite.modulate = Color.WHITE
	is_dashing = false

func update_timers(delta: float):
	"""更新所有冷却计时器"""
	if dash_cooldown > 0:
		dash_cooldown -= delta

	if attack_cooldown > 0:
		attack_cooldown -= delta

func update_animation():
	"""更新角色动画"""
	if not is_alive:
		return

	# 翻转精灵朝向
	if input_direction.x > 0:
		sprite.flip_h = false
	elif input_direction.x < 0:
		sprite.flip_h = true

	# 简单的颜色变化表示状态
	if is_dashing:
		sprite.modulate = Color(0.8, 0.8, 1.0, 0.8)
	elif attack_cooldown > 0:
		sprite.modulate = Color(1.2, 1.2, 1.0, 1.0)
	else:
		sprite.modulate = Color.WHITE

func take_damage(damage: int, attacker_position: Vector2):
	"""受到伤害"""
	if not is_alive:
		return false

	health -= damage

	print("受到伤害: " + str(damage) + ", 剩余生命: " + str(health))

	# 击退效果
	var knockback_direction = (global_position - attacker_position).normalized()
	velocity = knockback_direction * 200 + Vector2.UP * 150

	# 受伤视觉效果
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color.WHITE

	# 死亡检查
	if health <= 0:
		die()

	return true

func die():
	"""玩家死亡"""
	is_alive = false
	print("玩家死亡!")

	# 死亡视觉效果
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)

	# 停止所有移动
	velocity = Vector2.ZERO
	set_physics_process(false)

func heal(amount: int):
	"""治疗玩家"""
	health = min(health + amount, max_health)
	print("治疗: +" + str(amount) + " 生命值, 当前: " + str(health))

	sprite.modulate = Color.GREEN
	await get_tree().create_timer(0.3).timeout
	sprite.modulate = Color.WHITE

func _on_hurtbox_area_entered(area: Area2D):
	"""受到攻击区域进入"""
	print("碰撞到区域: " + area.name)

	# 模拟敌人攻击
	if area.name == "TestEnemy":
		take_damage(10, area.global_position)

func _on_collectible_area_entered(area: Area2D):
	"""收集品区域进入"""
	print("收集到物品: " + area.name)

	if area.name.begins_with("Coin"):
		heal(5)
		area.queue_free()

func setup_ui():
	"""设置UI元素"""
	# 创建生命值标签
	var label = Label.new()
	label.name = "HealthLabel"
	label.text = "生命值: " + str(health) + "/" + str(max_health)
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(label)
	health_label = label

func setup_camera():
	"""设置相机跟随"""
	if camera:
		# 设置相机平滑跟随
		camera.smoothing_enabled = true
		camera.smoothing_speed = 5.0
		camera.drag_margin_h_enabled = true
		camera.drag_margin_v_enabled = true
		camera.drag_margin_left = 0.2
		camera.drag_margin_right = 0.2
		camera.drag_margin_top = 0.2
		camera.drag_margin_bottom = 0.2

		# 设置相机边界（可根据关卡调整）
		camera.limit_left = -1000
		camera.limit_right = 1000
		camera.limit_top = -1000
		camera.limit_bottom = 1000

func update_ui():
	"""更新UI显示"""
	if health_label:
		health_label.text = "生命值: " + str(health) + "/" + str(max_health)

func setup_attack_hitbox():
	"""设置攻击检测区域"""
	# 创建攻击区域
	var area = Area2D.new()
	area.name = "AttackHitbox"

	# 创建碰撞形状
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 20)  # 攻击范围
	shape.shape = rect
	# 初始位置（右侧）
	shape.position = Vector2(20, 0)

	area.add_child(shape)
	add_child(area)
	attack_area = area

	# 默认禁用碰撞
	attack_area.monitoring = false
	attack_area.monitorable = false

	print("攻击检测区域已创建")

