# Coin.gd
# 金币收集品

extends Area2D

## 属性
@export var value := 1
@export var attract_range := 50.0
@export var attract_speed := 200.0

## 状态
var is_attracting := false
var target: Node2D

@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D

func _ready():
	"""初始化"""
	add_to_group("coin")
	body_entered.connect(_on_body_entered)

	# 初始动画
	sprite.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.2)

	# 漂浮动画
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(sprite, "position:y", -3, 0.5)
	float_tween.tween_property(sprite, "position:y", 0, 0.5)

func _physics_process(delta):
	"""物理更新"""
	if is_attracting and target and is_instance_valid(target):
		# 向玩家移动
		var direction = (target.global_position - global_position).normalized()
		position += direction * attract_speed * delta

		# 检查是否到达玩家
		if global_position.distance_to(target.global_position) < 10:
			collect()

func _on_body_entered(body):
	"""碰撞检测"""
	if body.is_in_group("player"):
		collect()

func collect():
	"""收集金币"""
	# 发射事件
	EventBus.coin_collected.emit(value)

	# 收集特效
	play_collect_effect()

	# 消失
	queue_free()

func play_collect_effect():
	"""播放收集特效"""
	# 创建闪光粒子
	var particles = GPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	get_parent().add_child(particles)

	# 延迟移除粒子
	await get_tree().create_timer(0.5).timeout
	particles.queue_free()

func start_attracting(player: Node2D):
	"""开始被吸引"""
	is_attracting = true
	target = player
