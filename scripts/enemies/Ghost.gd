# Ghost.gd
# 幽灵敌人 - 穿墙移动，瞬移攻击

extends "res://scripts/EnemyBase.gd"

## 幽灵特有属性
@export var phase_through_walls := true
@export var teleport_cooldown := 5.0
@export var teleport_distance := 100.0
@export var fade_speed := 2.0

var teleport_timer := 0.0
var is_fading := false
var is_visible_to_player := true

func _ready():
	super._ready()
	enemy_type = EnemyType.GHOST
	max_health = 20
	health = max_health
	move_speed = 30.0
	attack_damage = 15
	coin_reward = 8
	experience_reward = 20

	# 幽灵可以穿墙
	if phase_through_walls:
		set_collision_mask_value(1, false)  # 禁用与地形的碰撞

func _physics_process(delta):
	super._physics_process(delta)

	# 瞬移冷却
	if teleport_timer > 0:
		teleport_timer -= delta

	# 根据状态更新透明度
	update_visibility(delta)

func update_visibility(delta: float):
	"""更新可见性"""
	if is_fading:
		sprite.modulate.a = move_toward(sprite.modulate.a, 0.3, fade_speed * delta)
	else:
		sprite.modulate.a = move_toward(sprite.modulate.a, 1.0, fade_speed * delta)

func ai_chase(delta: float):
	"""追击状态"""
	super.ai_chase(delta)

	# 接近玩家时瞬移
	if Game.player and teleport_timer <= 0:
		var distance = global_position.distance_to(Game.player.global_position)
		if distance < 50:
			teleport_behind_player()

func teleport_behind_player():
	"""瞬移到玩家身后"""
	if not Game.player:
		return

	is_fading = true

	# 计算瞬移位置（玩家身后）
	var player_direction = Vector2.RIGHT if not Game.player.sprite.flip_h else Vector2.LEFT
	var teleport_pos = Game.player.global_position + player_direction * teleport_distance

	# 瞬移动画
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		global_position = teleport_pos
		is_fading = false
	)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

	teleport_timer = teleport_cooldown

func on_attack():
	"""攻击"""
	super.on_attack()

	# 攻击时闪烁
	sprite.modulate = Color(1, 0.5, 0.5, 1.0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1, sprite.modulate.a)

func take_damage(damage: int, attacker_position: Vector2) -> bool:
	"""受到伤害"""
	# 幽灵有几率闪避
	if randf() < 0.2:  # 20%闪避率
		play_sound("ghost_dodge")
		teleport_behind_player()
		return false

	return super.take_damage(damage, attacker_position)

func die():
	"""死亡"""
	super.die()

	# 死亡时淡出消失
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
