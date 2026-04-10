# ProjectileManager.gd
# 投射物管理器 - 统一管理所有投射物

extends Node

## 投射物池
var projectile_pools := {}
const POOL_SIZE := 20

## 投射物场景缓存
var scene_cache := {}

func _ready():
	# 预加载投射物场景
	preload_projectile_scenes()
	# 初始化池
	init_pools()

func preload_projectile_scenes():
	"""预加载投射物场景"""
	var scenes := {
		"holy_water": "res://scenes/projectiles/HolyWater.tscn",
		"knife": "res://scenes/projectiles/Knife.tscn",
		"axe": "res://scenes/projectiles/Axe.tscn",
		"cross": "res://scenes/projectiles/Cross.tscn"
	}

	for key in scenes:
		if ResourceLoader.exists(scenes[key]):
			scene_cache[key] = load(scenes[key])

func init_pools():
	"""初始化投射物池"""
	for key in scene_cache:
		projectile_pools[key] = []
		for i in POOL_SIZE:
			var proj = scene_cache[key].instantiate()
			proj.set_physics_process(false)
			proj.hide()
			add_child(proj)
			projectile_pools[key].append(proj)

func spawn_projectile(type: String, position: Vector2, direction: Vector2, damage: int = 10) -> Node2D:
	"""生成投射物"""
	var pool = projectile_pools.get(type, [])

	for proj in pool:
		if not proj.visible:
			proj.global_position = position
			if proj.has_method("initialize"):
				proj.initialize(direction)
			if "damage" in proj:
				proj.damage = damage
			proj.show()
			proj.set_physics_process(true)
			return proj

	# 池满，创建新的
	if scene_cache.has(type):
		var new_proj = scene_cache[type].instantiate()
		new_proj.global_position = position
		if new_proj.has_method("initialize"):
			new_proj.initialize(direction)
		get_tree().current_scene.add_child(new_proj)
		return new_proj

	return null

func return_projectile(proj: Node2D, type: String):
	"""归还投射物到池"""
	proj.hide()
	proj.set_physics_process(false)
	proj.global_position = Vector2(-1000, -1000)

	if projectile_pools.has(type):
		projectile_pools[type].append(proj)

func clear_all_projectiles():
	"""清除所有投射物"""
	for pool in projectile_pools.values():
		for proj in pool:
			if is_instance_valid(proj):
				proj.hide()
				proj.set_physics_process(false)
