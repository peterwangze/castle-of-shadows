# PlayerData.gd
# 玩家数据管理

class_name PlayerData
extends Resource

## 基础属性
@export var player_name := "艾登·夜行者"
@export var level := 1
@export var experience := 0
@export var experience_to_next_level := 100
@export var health := 100
@export var max_health := 100
@export var shadow_energy := 100
@export var max_shadow_energy := 100
@export var coins := 0
@export var lives := 3

## 能力值
@export var strength := 10      # 影响物理攻击
@export var dexterity := 10     # 影响暴击和命中
@export var vitality := 10      # 影响生命值
@export var intelligence := 10  # 影响暗影能量和魔法
@export var luck := 10          # 影响暴击率和掉落率

## 技能点
@export var skill_points := 0
@export var skills := {
	"double_jump": false,
	"air_dash": false,
	"wall_jump": false,
	"shadow_form": false,
	"backstab": false,
	"critical_strike": false,
	"life_steal": false,
	"energy_shield": false
}

## 装备系统
@export var equipped_weapon := "sword"
@export var equipped_subweapon := "none"
@export var equipped_armor := "leather"
@export var equipped_accessory := "none"

@export var inventory := {
	"weapons": ["sword"],
	"subweapons": [],
	"consumables": {"health_potion": 3, "energy_potion": 1},
	"key_items": [],
	"materials": {}
}

## 游戏进度
@export var play_time := 0.0
@export var enemies_defeated := 0
@export var bosses_defeated := 0
@export var coins_collected := 0
@export var secrets_found := 0
@export var deaths := 0
@export var checkpoints_reached := 0

@export var completed_levels := []
@export var discovered_areas := {}

## 统计信息
@export var total_damage_dealt := 0
@export var total_damage_taken := 0
@export var total_jumps := 0
@export var total_dashes := 0
@export var total_attacks := 0
@export var total_critical_hits := 0
@export var total_backstabs := 0

## 设置
@export var difficulty := "normal"  # easy, normal, hard, nightmare
@export var controller_sensitivity := 1.0
@export var sound_volume := 1.0
@export var music_volume := 1.0

func _init():
	"""初始化玩家数据"""
	print("玩家数据初始化: " + player_name)

func gain_experience(amount: int):
	"""获得经验值"""
	experience += amount
	coins_collected += int(amount / 10)  # 经验值也增加金币计数

	# 检查升级
	while experience >= experience_to_next_level:
		level_up()

	print("获得经验值: " + str(amount) + "，当前经验: " + str(experience))

func level_up():
	"""升级"""
	level += 1
	experience -= experience_to_next_level

	# 计算下一级所需经验
	experience_to_next_level = calculate_next_level_exp()

	# 增加技能点
	skill_points += 3

	# 基础属性提升
	max_health += 10 + vitality
	max_shadow_energy += 5 + intelligence

	# 恢复生命和能量
	health = max_health
	shadow_energy = max_shadow_energy

	# 每5级额外奖励
	if level % 5 == 0:
		skill_points += 2
		coins += 100

	print("升级! 当前等级: " + str(level))
	print("获得3技能点，总技能点: " + str(skill_points))

func calculate_next_level_exp() -> int:
	"""计算下一级所需经验值"""
	# 指数增长公式
	return int(100 * pow(1.15, level - 1))

func take_damage(amount: int) -> bool:
	"""受到伤害"""
	var actual_damage = calculate_damage_taken(amount)
	health -= actual_damage

	total_damage_taken += actual_damage

	# 更新统计数据
	deaths += 1 if health <= 0 else 0

	return health <= 0

func calculate_damage_taken(incoming_damage: int) -> int:
	"""计算实际受到伤害"""
	# 防御公式：护甲减免 + 幸运闪避
	var armor_defense = get_armor_defense()
	var dodge_chance = luck * 0.001  # 每点幸运增加0.1%闪避

	# 闪避判定
	if randf() < dodge_chance:
		print("闪避攻击!")
		return 0

	# 伤害减免
	var damage_reduction = armor_defense * 0.05  # 每点防御减少5%伤害
	var reduced_damage = incoming_damage * (1.0 - damage_reduction)

	return int(max(1, reduced_damage))  # 至少造成1点伤害

func heal(amount: int):
	"""治疗"""
	health = min(health + amount, max_health)

func use_shadow_energy(amount: int) -> bool:
	"""使用暗影能量"""
	if shadow_energy >= amount:
		shadow_energy -= amount
		return true
	return false

func restore_shadow_energy(amount: int):
	"""恢复暗影能量"""
	shadow_energy = min(shadow_energy + amount, max_shadow_energy)

func add_coins(amount: int):
	"""添加金币"""
	coins += amount
	coins_collected += amount

func spend_coins(amount: int) -> bool:
	"""花费金币"""
	if coins >= amount:
		coins -= amount
		return true
	return false

func learn_skill(skill_name: String) -> bool:
	"""学习技能"""
	if not skill_name in skills:
		push_error("技能不存在: " + skill_name)
		return false

	if skills[skill_name]:
		print("技能已学习: " + skill_name)
		return false

	if skill_points <= 0:
		print("技能点不足")
		return false

	# 检查前置技能
	if not check_skill_prerequisites(skill_name):
		print("未满足前置技能要求")
		return false

	skills[skill_name] = true
	skill_points -= 1

	print("学会技能: " + skill_name)
	return true

func check_skill_prerequisites(skill_name: String) -> bool:
	"""检查技能前置条件"""
	match skill_name:
		"air_dash":
			return skills["double_jump"]
		"wall_jump":
			return skills["double_jump"]
		"backstab":
			return skills["shadow_form"]
		"critical_strike":
			return dexterity >= 15
		"life_steal":
			return skills["shadow_form"] and intelligence >= 20
		"energy_shield":
			return intelligence >= 25
		_:
			return true  # 基础技能无前置

func equip_item(item_type: String, item_id: String):
	"""装备物品"""
	match item_type:
		"weapon":
			if item_id in inventory["weapons"]:
				equipped_weapon = item_id
				print("装备武器: " + item_id)

		"subweapon":
			if item_id in inventory["subweapons"]:
				equipped_subweapon = item_id
				print("装备副武器: " + item_id)

		"armor":
			equipped_armor = item_id
			print("装备护甲: " + item_id)

		"accessory":
			equipped_accessory = item_id
			print("装备饰品: " + item_id)

func add_to_inventory(item_type: String, item_id: String, quantity: int = 1):
	"""添加到背包"""
	match item_type:
		"weapon":
			if not item_id in inventory["weapons"]:
				inventory["weapons"].append(item_id)
				print("获得新武器: " + item_id)

		"subweapon":
			if not item_id in inventory["subweapons"]:
				inventory["subweapons"].append(item_id)
				print("获得新副武器: " + item_id)

		"consumable":
			if not item_id in inventory["consumables"]:
				inventory["consumables"][item_id] = 0
			inventory["consumables"][item_id] += quantity
			print("获得消耗品: " + item_id + " x" + str(quantity))

		"key_item":
			if not item_id in inventory["key_items"]:
				inventory["key_items"].append(item_id)
				print("获得关键物品: " + item_id)

		"material":
			if not item_id in inventory["materials"]:
				inventory["materials"][item_id] = 0
			inventory["materials"][item_id] += quantity
			print("获得材料: " + item_id + " x" + str(quantity))

func use_consumable(item_id: String) -> bool:
	"""使用消耗品"""
	if not item_id in inventory["consumables"]:
		return false

	if inventory["consumables"][item_id] <= 0:
		return false

	# 使用效果
	match item_id:
		"health_potion":
			heal(50)
			print("使用生命药水，恢复50生命")

		"energy_potion":
			restore_shadow_energy(50)
			print("使用能量药水，恢复50暗影能量")

		"strength_potion":
			strength += 5
			print("使用力量药水，力量+5（暂时）")
			# 应该添加计时器效果，这里简化

	inventory["consumables"][item_id] -= 1

	if inventory["consumables"][item_id] <= 0:
		inventory["consumables"].erase(item_id)

	return true

func get_armor_defense() -> int:
	"""获取护甲防御值"""
	match equipped_armor:
		"leather": return 10
		"chainmail": return 25
		"plate": return 40
		"shadow": return 30  # 暗影护甲，附加暗影抗性
		"vampire": return 35 # 吸血鬼护甲，附加生命偷取
		_: return 5  # 默认布甲

func get_weapon_damage() -> int:
	"""获取武器基础伤害"""
	var base_damage := 0

	match equipped_weapon:
		"sword": base_damage = 15
		"longsword": base_damage = 20
		"greatsword": base_damage = 30
		"axe": base_damage = 25
		"mace": base_damage = 28
		"rapier": base_damage = 18
		"whip": base_damage = 22
		"holy_sword": base_damage = 35
		_: base_damage = 10  # 默认短剑

	# 力量加成
	base_damage += strength * 0.5

	return int(base_damage)

func get_critical_chance() -> float:
	"""获取暴击率"""
	var base_chance := 0.05  # 5%基础暴击

	# 敏捷加成
	base_chance += dexterity * 0.002  # 每点敏捷增加0.2%

	# 幸运加成
	base_chance += luck * 0.001  # 每点幸运增加0.1%

	# 技能加成
	if skills["critical_strike"]:
		base_chance += 0.15

	return min(base_chance, 0.5)  # 最大50%

func get_critical_multiplier() -> float:
	"""获取暴击倍率"""
	var multiplier := 1.5  # 基础1.5倍

	# 力量加成
	multiplier += strength * 0.01  # 每点力量增加0.01倍

	# 技能加成
	if skills["critical_strike"]:
		multiplier += 0.5

	return multiplier

func reset():
	"""重置玩家数据"""
	level = 1
	experience = 0
	experience_to_next_level = 100
	health = max_health
	shadow_energy = max_shadow_energy
	coins = 0
	lives = 3

	skill_points = 0

	# 重置技能
	for skill in skills:
		skills[skill] = false

	# 重置背包
	inventory = {
		"weapons": ["sword"],
		"subweapons": [],
		"consumables": {"health_potion": 3},
		"key_items": [],
		"materials": {}
	}

	# 重置进度
	play_time = 0.0
	enemies_defeated = 0
	bosses_defeated = 0
	coins_collected = 0
	secrets_found = 0
	deaths = 0
	checkpoints_reached = 0

	completed_levels = []
	discovered_areas = {}

	# 重置统计
	total_damage_dealt = 0
	total_damage_taken = 0
	total_jumps = 0
	total_dashes = 0
	total_attacks = 0
	total_critical_hits = 0
	total_backstabs = 0

	print("玩家数据已重置")

func serialize() -> Dictionary:
	"""序列化玩家数据"""
	return {
		"player_name": player_name,
		"level": level,
		"experience": experience,
		"experience_to_next_level": experience_to_next_level,
		"health": health,
		"max_health": max_health,
		"shadow_energy": shadow_energy,
		"max_shadow_energy": max_shadow_energy,
		"coins": coins,
		"lives": lives,
		"strength": strength,
		"dexterity": dexterity,
		"vitality": vitality,
		"intelligence": intelligence,
		"luck": luck,
		"skill_points": skill_points,
		"skills": skills.duplicate(true),
		"equipped_weapon": equipped_weapon,
		"equipped_subweapon": equipped_subweapon,
		"equipped_armor": equipped_armor,
		"equipped_accessory": equipped_accessory,
		"inventory": inventory.duplicate(true),
		"play_time": play_time,
		"enemies_defeated": enemies_defeated,
		"bosses_defeated": bosses_defeated,
		"coins_collected": coins_collected,
		"secrets_found": secrets_found,
		"deaths": deaths,
		"checkpoints_reached": checkpoints_reached,
		"completed_levels": completed_levels.duplicate(),
		"discovered_areas": discovered_areas.duplicate(true),
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken,
		"total_jumps": total_jumps,
		"total_dashes": total_dashes,
		"total_attacks": total_attacks,
		"total_critical_hits": total_critical_hits,
		"total_backstabs": total_backstabs,
		"difficulty": difficulty,
		"controller_sensitivity": controller_sensitivity,
		"sound_volume": sound_volume,
		"music_volume": music_volume
	}

func deserialize(data: Dictionary):
	"""反序列化玩家数据"""
	player_name = data.get("player_name", "艾登·夜行者")
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	experience_to_next_level = data.get("experience_to_next_level", 100)
	health = data.get("health", 100)
	max_health = data.get("max_health", 100)
	shadow_energy = data.get("shadow_energy", 100)
	max_shadow_energy = data.get("max_shadow_energy", 100)
	coins = data.get("coins", 0)
	lives = data.get("lives", 3)
	strength = data.get("strength", 10)
	dexterity = data.get("dexterity", 10)
	vitality = data.get("vitality", 10)
	intelligence = data.get("intelligence", 10)
	luck = data.get("luck", 10)
	skill_points = data.get("skill_points", 0)
	skills = data.get("skills", {}).duplicate(true)
	equipped_weapon = data.get("equipped_weapon", "sword")
	equipped_subweapon = data.get("equipped_subweapon", "none")
	equipped_armor = data.get("equipped_armor", "leather")
	equipped_accessory = data.get("equipped_accessory", "none")
	inventory = data.get("inventory", {}).duplicate(true)
	play_time = data.get("play_time", 0.0)
	enemies_defeated = data.get("enemies_defeated", 0)
	bosses_defeated = data.get("bosses_defeated", 0)
	coins_collected = data.get("coins_collected", 0)
	secrets_found = data.get("secrets_found", 0)
	deaths = data.get("deaths", 0)
	checkpoints_reached = data.get("checkpoints_reached", 0)
	completed_levels = data.get("completed_levels", []).duplicate()
	discovered_areas = data.get("discovered_areas", {}).duplicate(true)
	total_damage_dealt = data.get("total_damage_dealt", 0)
	total_damage_taken = data.get("total_damage_taken", 0)
	total_jumps = data.get("total_jumps", 0)
	total_dashes = data.get("total_dashes", 0)
	total_attacks = data.get("total_attacks", 0)
	total_critical_hits = data.get("total_critical_hits", 0)
	total_backstabs = data.get("total_backstabs", 0)
	difficulty = data.get("difficulty", "normal")
	controller_sensitivity = data.get("controller_sensitivity", 1.0)
	sound_volume = data.get("sound_volume", 1.0)
	music_volume = data.get("music_volume", 1.0)

func get_stat_summary() -> String:
	"""获取统计摘要"""
	return """玩家统计摘要:
等级: {level}
游戏时间: {play_time:.1f}小时
击败敌人: {enemies_defeated}
击败Boss: {bosses_defeated}
收集金币: {coins_collected}
发现秘密: {secrets_found}
死亡次数: {deaths}
总伤害输出: {total_damage_dealt}
总承受伤害: {total_damage_taken}
攻击次数: {total_attacks}
暴击次数: {total_critical_hits}
背刺次数: {total_backstabs}
""".format({
	"level": level,
	"play_time": play_time / 3600.0,
	"enemies_defeated": enemies_defeated,
	"bosses_defeated": bosses_defeated,
	"coins_collected": coins_collected,
	"secrets_found": secrets_found,
	"deaths": deaths,
	"total_damage_dealt": total_damage_dealt,
	"total_damage_taken": total_damage_taken,
	"total_attacks": total_attacks,
	"total_critical_hits": total_critical_hits,
	"total_backstabs": total_backstabs
})