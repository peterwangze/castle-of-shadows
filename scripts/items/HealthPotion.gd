# HealthPotion.gd
# 生命药水收集品

extends Area2D

## 属性
@export var heal_amount := 25
@export var attract_range := 30.0
@export var attract_speed := 150.0

## 状态
var is_attracting := false
var target: Node2D

@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D

func _ready():
	"""初始化"""
	add_to_group("health_potion")
	add_to_group("collectible")
	body_entered.connect(_on_body_entered)

	# 发光动画
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.5)
	glow_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1.0), 0.5)

func _physics_process(delta):
	"""物理更新"""
	if is_attracting and target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		position += direction * attract_speed * delta

		if global_position.distance_to(target.global_position) < 10:
			collect()

func _on_body_entered(body):
	"""碰撞检测"""
	if body.is_in_group("player"):
		collect()

func collect():
	"""收集药水"""
	# 发射事件
	EventBus.item_collected.emit("health_potion", {"heal_amount": heal_amount})

	# 治疗玩家
	if Game.player and Game.player.has_method("heal"):
		Game.player.heal(heal_amount)

	# 收集特效
	play_collect_effect()

	queue_free()

func play_collect_effect():
	"""播放收集特效"""
	# 绿色闪光
	var flash = ColorRect.new()
	flash.color = Color(0, 1, 0, 0.3)
	flash.size = Vector2(20, 20)
	flash.global_position = global_position - Vector2(10, 10)
	get_parent().add_child(flash)

	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

func start_attracting(player: Node2D):
	"""开始被吸引"""
	is_attracting = true
	target = player
