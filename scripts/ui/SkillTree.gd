# SkillTree.gd
# 技能树界面控制器

extends CanvasLayer

## 技能树数据
var skill_points := 0

## 节点引用
@onready var combat_tree := $Panel/HBoxContainer/CombatTree
@onready var shadow_tree := $Panel/HBoxContainer/ShadowTree
@onready var utility_tree := $Panel/HBoxContainer/UtilityTree
@onready var points_label := $Panel/PointsLabel
@onready var close_button := $Panel/CloseButton

func _ready():
	visible = false
	close_button.pressed.connect(_on_close)

func show_skill_tree():
	visible = true
	update_display()

func hide_skill_tree():
	visible = false

func update_display():
	"""更新显示"""
	if Game.player_data:
		skill_points = Game.player_data.skill_points
		points_label.text = "技能点: %d" % skill_points

func _on_close():
	hide_skill_tree()

func unlock_skill(skill_name: String, cost: int) -> bool:
	"""解锁技能"""
	if skill_points >= cost:
		skill_points -= cost
		if Game.player_data:
			Game.player_data.skill_points = skill_points
			Game.player_data.unlocked_skills.append(skill_name)
		EventBus.play_sound.emit("ui/confirm", 0.0)
		update_display()
		return true
	return false
