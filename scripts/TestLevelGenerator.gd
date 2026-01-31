# TestLevelGenerator.gd
# 测试关卡生成器 - 在运行时生成测试元素

extends Node

## 资源引用
var platform_texture: Texture2D
var enemy_scene: PackedScene

## 生成参数
@export var generate_on_ready := true
@export var platform_count := 5
@export var enemy_count := 3
@export var coin_count := 10

func _ready():
	"""初始化"""
	print("测试关卡生成器初始化")

	# 加载资源
	load_resources()

	# 生成测试内容
	if generate_on_ready:
		generate_test_level()

func load_resources():
	"""加载所需资源"""
	# 加载平台纹理
	platform_texture = load("res://assets/art/tilesets/basic/floor.png")
	if not platform_texture:
		push_warning("无法加载平台纹理")

	# 测试敌人：我们直接创建节点，不需要加载场景
	# enemy_scene留空，我们会在create_enemy中直接创建

func generate_test_level():
	"""生成测试关卡"""
	print("开始生成测试关卡...")

	# 生成平台
	generate_platforms()

	# 生成敌人
	generate_enemies()

	# 生成金币（可选）
	# generate_coins()

	print("测试关卡生成完成")

func generate_platforms():
	"""生成测试平台"""
	print("生成 " + str(platform_count) + " 个测试平台")

	# 基础平台位置（避免与现有平台重叠）
	var base_y = 250
	var spacing = 150

	for i in range(platform_count):
		var platform_x = 200 + i * spacing
		var platform_y = base_y + sin(i * 0.5) * 50  # 波浪形平台

		create_platform(platform_x, platform_y, 100, 20)

		print("平台 " + str(i+1) + " 生成在位置: (" + str(platform_x) + ", " + str(platform_y) + ")")

func create_platform(x: float, y: float, width: float, height: float):
	"""创建单个平台"""
	# 创建物理体
	var static_body = StaticBody2D.new()
	static_body.name = "GeneratedPlatform_" + str(randi())
	static_body.position = Vector2(x, y)

	# 创建碰撞形状
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(width, height)
	collision_shape.shape = rect_shape

	static_body.add_child(collision_shape)

	# 创建视觉精灵
	var sprite = Sprite2D.new()
	if platform_texture:
		sprite.texture = platform_texture
		sprite.centered = false
		sprite.scale = Vector2(width / 16, height / 16)  # 假设纹理是16x16
	else:
		# 没有纹理时使用颜色矩形
		sprite.modulate = Color(0.6, 0.4, 0.2, 1.0)

	static_body.add_child(sprite)

	# 添加到场景
	get_parent().add_child(static_body)

	return static_body

func generate_enemies():
	"""生成测试敌人"""
	print("生成 " + str(enemy_count) + " 个测试敌人")

	for i in range(enemy_count):
		var enemy_x = 300 + i * 200
		var enemy_y = 150

		create_enemy(enemy_x, enemy_y)

		print("敌人 " + str(i+1) + " 生成在位置: (" + str(enemy_x) + ", " + str(enemy_y) + ")")

func create_enemy(x: float, y: float):
	"""创建单个敌人"""
	# 创建敌人节点
	var enemy = CharacterBody2D.new()
	enemy.name = "GeneratedEnemy_" + str(randi())
	enemy.position = Vector2(x, y)

	# 添加精灵
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"  # 确保与TestEnemy.gd中的$Sprite2D引用匹配
	var enemy_texture = load("res://assets/art/enemies/skeleton/idle_01.png")
	if enemy_texture:
		sprite.texture = enemy_texture
		sprite.centered = false
	else:
		sprite.modulate = Color(1, 0, 0, 1)  # 红色占位符

	enemy.add_child(sprite)

	# 添加碰撞形状
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"  # 确保与TestEnemy.gd中的$CollisionShape2D引用匹配
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 16
	collision_shape.shape = circle_shape

	enemy.add_child(collision_shape)

	# 添加脚本
	enemy.script = load("res://scripts/TestEnemy.gd")
	if enemy.script:
		print("敌人脚本已附加")
	else:
		print("警告：无法加载敌人脚本")

	# 添加到场景
	get_parent().add_child(enemy)

	return enemy

func generate_coins():
	"""生成金币（占位符）"""
	print("生成 " + str(coin_count) + " 个金币")

	# 这里可以扩展为实际的金币生成
	# 目前只是占位符
	for i in range(coin_count):
		var coin_x = 100 + i * 50
		var coin_y = 100

		print("金币 " + str(i+1) + " 位置: (" + str(coin_x) + ", " + str(coin_y) + ")")

func clear_generated_content():
	"""清除所有生成的内容"""
	print("清除生成的内容")

	for child in get_parent().get_children():
		if child.name.begins_with("Generated"):
			child.queue_free()

	print("生成的内容已清除")

# 调试功能
func _input(event: InputEvent):
	"""输入处理用于调试"""
	if event.is_action_pressed("debug_regenerate"):
		print("重新生成测试关卡")
		clear_generated_content()
		generate_test_level()

	if event.is_action_pressed("debug_clear"):
		print("清除测试关卡")
		clear_generated_content()