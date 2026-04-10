# SkillTree.gd
# 技能树界面控制器

extends CanvasLayer

## 技能定义
const SKILLS := {
	# 战斗技能树
	"combo_boost": {
		"name": "连击强化",
		"description": "连击窗口时间 +0.2秒",
		"cost": 1,
		"max_level": 3,
		"tree": "combat",
		"requires": null,
		"effect": "combo_window",
		"value_per_level": [0.2, 0.4, 0.6]
	},
	"vampiric_attack": {
		"name": "吸血攻击",
		"description": "击杀敌人回复生命值",
		"cost": 1,
		"max_level": 3,
		"tree": "combat",
		"requires": null,
		"effect": "heal_on_kill",
		"value_per_level": [5, 10, 15]
	},
	"crit_mastery": {
		"name": "暴击精通",
		"description": "暴击率 +5%",
		"cost": 2,
		"max_level": 3,
		"tree": "combat",
		"requires": "combo_boost",
		"effect": "crit_chance",
		"value_per_level": [5, 10, 15]
	},

	# 暗影技能树
	"shadow_extend": {
		"name": "暗影延长",
		"description": "暗影形态持续时间 +1秒",
		"cost": 1,
		"max_level": 3,
		"tree": "shadow",
		"requires": null,
		"effect": "shadow_duration",
		"value_per_level": [1.0, 2.0, 3.0]
	},
	"energy_regen": {
		"name": "能量恢复",
		"description": "能量恢复速度 +20%",
		"cost": 1,
		"max_level": 3,
		"tree": "shadow",
		"requires": null,
		"effect": "energy_regen",
		"value_per_level": [0.2, 0.4, 0.6]
	},
	"dash_enhance": {
		"name": "冲刺强化",
		"description": "冲刺距离 +20%",
		"cost": 2,
		"max_level": 3,
		"tree": "shadow",
		"requires": "shadow_extend",
		"effect": "dash_distance",
		"value_per_level": [0.2, 0.4, 0.6]
	},

	# 辅助技能树
	"jump_boost": {
		"name": "跳跃强化",
		"description": "跳跃高度 +10%",
		"cost": 1,
		"max_level": 3,
		"tree": "utility",
		"requires": null,
		"effect": "jump_height",
		"value_per_level": [0.1, 0.2, 0.3]
	},
	"health_boost": {
		"name": "生命强化",
		"description": "最大生命值 +20",
		"cost": 1,
		"max_level": 3,
		"tree": "utility",
		"requires": null,
		"effect": "max_health",
		"value_per_level": [20, 40, 60]
	},
	"perception": {
		"name": "感知强化",
		"description": "发现隐藏门",
		"cost": 2,
		"max_level": 3,
		"tree": "utility",
		"requires": "jump_boost",
		"effect": "perception",
		"value_per_level": [1, 2, 3]
	}
}

## 技能等级记录
var skill_levels := {}

## 节点引用
@onready var combat_tree := $Panel/HBoxContainer/CombatTree
@onready var shadow_tree := $Panel/HBoxContainer/ShadowTree
@onready var utility_tree := $Panel/HBoxContainer/UtilityTree
@onready var points_label := $Panel/PointsLabel
@onready var close_button := $Panel/CloseButton

var skill_buttons := {}

func _ready():
	visible = false
	close_button.pressed.connect(_on_close)
	create_skill_buttons()

func create_skill_buttons():
	"""创建技能按钮"""
	for skill_id in SKILLS:
		var skill = SKILLS[skill_id]
		var container: VBoxContainer

		match skill.tree:
			"combat": container = combat_tree
			"shadow": container = shadow_tree
			"utility": container = utility_tree

		if container:
			var button = Button.new()
			button.text = "%s (Lv.%d/%d)" % [skill.name, 0, skill.max_level]
			button.custom_minimum_size = Vector2(150, 40)
			button.tooltip_text = "%s\n消耗: %d 技能点" % [skill.description, skill.cost]
			button.pressed.connect(_on_skill_button_pressed.bind(skill_id))

			container.add_child(button)
			skill_buttons[skill_id] = button

			# 初始化等级
			skill_levels[skill_id] = 0

func _on_skill_button_pressed(skill_id: String):
	"""技能按钮点击"""
	var skill = SKILLS[skill_id]
	var current_level = skill_levels.get(skill_id, 0)

	# 检查是否已满级
	if current_level >= skill.max_level:
		show_message("技能已满级！")
		return

	# 检查前置技能
	if skill.requires:
		var req_level = skill_levels.get(skill.requires, 0)
		if req_level == 0:
			show_message("需要先解锁: %s" % SKILLS[skill.requires].name)
			return

	# 尝试解锁
	var cost = skill.cost
	if unlock_skill(skill_id, cost):
		skill_levels[skill_id] = current_level + 1
		apply_skill_effect(skill_id, skill_levels[skill_id])
		update_skill_button(skill_id)
		show_message("解锁: %s Lv.%d" % [skill.name, skill_levels[skill_id]])

func update_skill_button(skill_id: String):
	"""更新技能按钮显示"""
	var skill = SKILLS[skill_id]
	var button = skill_buttons.get(skill_id)
	if button:
		var level = skill_levels.get(skill_id, 0)
		button.text = "%s (Lv.%d/%d)" % [skill.name, level, skill.max_level]

		if level >= skill.max_level:
			button.modulate = Color(0.5, 1.0, 0.5)  # 绿色表示完成
		elif level > 0:
			button.modulate = Color(1.0, 1.0, 0.5)  # 黄色表示进行中

func apply_skill_effect(skill_id: String, level: int):
	"""应用技能效果"""
	var skill = SKILLS[skill_id]
	var value = skill.value_per_level[level - 1]

	if not Game.player:
		return

	match skill.effect:
		"combo_window":
			Game.player.combo_window_bonus = value
		"heal_on_kill":
			Game.player.heal_on_kill = value
		"crit_chance":
			Game.player.crit_chance = value
		"shadow_duration":
			Game.player.shadow_form_duration_bonus = value
		"energy_regen":
			Game.player.energy_regen_bonus = value
		"dash_distance":
			Game.player.dash_distance_bonus = value
		"jump_height":
			Game.player.jump_velocity = -400 * (1 + value)
		"max_health":
			Game.player.max_health += value
			Game.player.health = min(Game.player.health + value, Game.player.max_health)
		"perception":
			Game.player.perception_level = level

	print("技能效果应用: %s = %s (等级 %d)" % [skill.effect, str(value), level])

func show_skill_tree():
	visible = true
	update_display()

func hide_skill_tree():
	visible = false

func update_display():
	"""更新显示"""
	if Game.player_data:
		var skill_points = Game.player_data.skill_points
		points_label.text = "技能点: %d" % skill_points

	# 同步已解锁技能
	if Game.player_data and Game.player_data.unlocked_skills:
		for skill_id in Game.player_data.unlocked_skills:
			if skill_levels.has(skill_id):
				skill_levels[skill_id] += 1
				update_skill_button(skill_id)

func _on_close():
	hide_skill_tree()

func unlock_skill(skill_name: String, cost: int) -> bool:
	"""解锁技能"""
	if Game.player_data and Game.player_data.skill_points >= cost:
		Game.player_data.skill_points -= cost
		Game.player_data.unlocked_skills.append(skill_name)
		EventBus.play_sound.emit("ui/confirm", 0.0)
		update_display()
		return true

	show_message("技能点不足！")
	return false

func show_message(text: String):
	"""显示提示消息"""
	# 创建临时消息标签
	var label = Label.new()
	label.text = text
	label.position = Vector2(250, 320)
	label.modulate = Color.YELLOW
	$Panel.add_child(label)

	# 2秒后移除
	await get_tree().create_timer(2.0).timeout
	label.queue_free()
