# Cross.gd
# 十字架投掷物 - 全屏攻击，造成范围伤害

extends "res://scripts/BaseProjectile.gd"

## 十字架特有属性
@export var wave_damage := 15  # 波浪伤害
@export var wave_speed := 800.0  # 波浪速度
@export var wave_width := 100.0  # 波浪宽度
@export var hit_cooldown := 0.5  # 同一敌人受击冷却

var hit_enemies := {}  # 已击中的敌人及其冷却时间

func _ready():
	super._ready()
	damage = wave_damage
	lifetime = 2.0

	# 初始不可见
	if sprite:
		sprite.visible = false

	# 禁用碰撞（使用自定义检测）
	if collision:
		collision.disabled = true

	# 创建波浪效果
	create_wave_effect()

func create_wave_effect():
	"""创建波浪攻击效果"""
	# 创建横向波浪
	var wave_tween = create_tween()
	wave_tween.set_parallel(true)

	# 向右扩散
	var right_wave = create_wave_sprite()
	right_wave.position = Vector2.ZERO
	add_child(right_wave)

	wave_tween.tween_property(right_wave, "position:x", 1000, 1.5)
	wave_tween.set_parallel(false)
	wave_tween.tween_callback(right_wave.queue_free)

	# 向左扩散
	await get_tree().create_timer(0.1).timeout
	var left_wave = create_wave_sprite()
	left_wave.position = Vector2.ZERO
	left_wave.flip_h = true
	add_child(left_wave)

	var left_tween = create_tween()
	left_tween.tween_property(left_wave, "position:x", -1000, 1.5)
	left_tween.tween_callback(left_wave.queue_free)

	# 持续检测敌人
	while time_alive < lifetime:
		detect_and_damage_enemies()
		update_hit_cooldowns()
		await get_tree().create_timer(0.1).timeout

	queue_free()

func create_wave_sprite() -> Sprite2D:
	"""创建波浪精灵"""
	var wave = Sprite2D.new()
	wave.modulate = Color(1, 1, 0.8, 0.8)
	wave.scale = Vector2(2, 20)  # 宽而扁的波浪
	# 如果有波浪纹理则使用，否则用占位符
	var tex = load("res://assets/art/effects/cross_wave.png")
	if tex:
		wave.texture = tex
	return wave

func detect_and_damage_enemies():
	"""检测并伤害敌人"""
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		# 检查冷却
		if enemy in hit_enemies and hit_enemies[enemy] > 0:
			continue

		# 检查距离（在波浪宽度范围内）
		var distance = abs(enemy.global_position.x - global_position.x)
		if distance < wave_width:
			# 造成伤害
			if enemy.has_method("take_damage"):
				enemy.take_damage(wave_damage, global_position)

			# 设置冷却
			hit_enemies[enemy] = hit_cooldown

func update_hit_cooldowns():
	"""更新受击冷却"""
	for enemy in hit_enemies.keys():
		hit_enemies[enemy] -= 0.1
		if hit_enemies[enemy] <= 0:
			hit_enemies.erase(enemy)
