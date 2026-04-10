# BossBase.gd
# Boss基类 - 所有Boss的父类

extends "res://scripts/EnemyBase.gd"

## Boss属性
@export var boss_name := "Unknown Boss"
@export var boss_health_bar := true
@export var phases := 3

## Boss阶段
var current_phase := 1
var phase_health_thresholds := []

## 特殊攻击
var special_attack_cooldown := 5.0
var special_attack_timer := 0.0

## 节点引用
var health_bar_node: ProgressBar

func _ready():
	super._ready()

	# Boss通常更强
	coin_reward = 50
	experience_reward = 100

	# 设置阶段血量阈值
	setup_phases()

	# 创建Boss血条
	if boss_health_bar:
		create_boss_health_bar()

func setup_phases():
	"""设置阶段血量阈值"""
	phase_health_thresholds.clear()
	for i in range(phases):
		phase_health_thresholds.append(float(phases - i) / phases * max_health)

func create_boss_health_bar():
	"""创建Boss血条"""
	health_bar_node = ProgressBar.new()
	health_bar_node.name = "BossHealthBar"
	health_bar_node.position = Vector2(320, 20)
	health_bar_node.size = Vector2(640, 30)
	health_bar_node.max_value = max_health
	health_bar_node.value = health
	health_bar_node.show_percentage = false

	get_tree().current_scene.add_child(health_bar_node)

func _physics_process(delta):
	super._physics_process(delta)

	# 更新血条
	if health_bar_node and is_instance_valid(health_bar_node):
		health_bar_node.value = health

	# 特殊攻击冷却
	if special_attack_timer > 0:
		special_attack_timer -= delta

	# 检查阶段转换
	check_phase_transition()

func check_phase_transition():
	"""检查阶段转换"""
	for i in range(phase_health_thresholds.size()):
		if health <= phase_health_thresholds[i] and current_phase <= i + 1:
			transition_to_phase(i + 2)
			break

func transition_to_phase(new_phase: int):
	"""转换到新阶段"""
	if new_phase <= phases and new_phase > current_phase:
		current_phase = new_phase
		on_phase_enter(new_phase)

func on_phase_enter(phase: int):
	"""进入新阶段（子类重写）"""
	print("%s 进入第 %d 阶段" % [boss_name, phase])

	# 通用：阶段转换特效
	sprite.modulate = Color(1, 0, 0, 1.0)
	await get_tree().create_timer(0.3).timeout
	sprite.modulate = Color.WHITE

func perform_special_attack():
	"""执行特殊攻击（子类重写）"""
	if special_attack_timer <= 0:
		special_attack_timer = special_attack_cooldown
		return true
	return false

func die():
	"""Boss死亡"""
	# 移除血条
	if health_bar_node and is_instance_valid(health_bar_node):
		health_bar_node.queue_free()

	super.die()

	# Boss死亡事件
	EventBus.enemy_died.emit(self, global_position)

	# 可能触发胜利
	if has_signal("boss_defeated"):
		emit_signal("boss_defeated")
