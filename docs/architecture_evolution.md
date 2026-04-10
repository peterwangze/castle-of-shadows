# Castle of Shadows - 架构演进与开发路线图

> 文档版本：v1.1  
> 更新日期：2026-04-10  
> 项目阶段：第二阶段核心玩法完善期

---

## 一、项目现状分析

### 1.1 整体完成度

| 系统模块 | 完成度 | 状态评估 | 阻塞等级 |
|---------|--------|----------|---------|
| 玩家控制系统 | 90% | 核心功能完整，副武器已实现 | ✅ 完成 |
| 战斗系统 | 85% | 攻击检测正常，连击系统完整 | 🟡 P1 |
| 敌人AI系统 | 85% | EnemyBase框架完整，5种敌人实现 | ✅ 完成 |
| 游戏流程管理 | 85% | 关卡切换完整，6关卡可用 | ✅ 完成 |
| 存档系统 | 90% | 多槽支持已实现 | ✅ 完成 |
| 数据持久化 | 95% | PlayerData设计良好，SaveManager已添加 | ✅ 完成 |
| 调试系统 | 90% | 功能完整，包含无敌/一击必杀/无限能量 | ✅ 完成 |
| 音频系统 | 80% | AudioManager完整，音频资源占位 | 🟡 P1 |
| UI系统 | 70% | HUD、主菜单、暂停、胜利、失败画面 | 🟡 P1 |
| 关卡系统 | 95% | 6关卡完整配置，敌人和收集品已放置 | ✅ 完成 |
| Boss系统 | 95% | DraculaBoss实现，3阶段5攻击模式 | ✅ 完成 |
| 投射物系统 | 90% | ProjectileManager已实现，4种副武器 | ✅ 完成 |
| 资源制作 | 30% | 大量占位符 | 🟢 P2 |
| 成就系统 | 0% | 未开始 | 🟢 P3 |

### 1.2 已完成的阻塞问题

~~🔴 P0级 - 必须立即修复：~~

1. ✅ **方法不存在错误** - 已修复
   - 解决方案：Player.gd 添加 gain_experience 方法
   - EnemyBase.gd 改为调用 Game.player_data.gain_experience()

2. ✅ **副武器场景文件缺失** - 已修复
   - 已创建：HolyWater.tscn, Knife.tscn, Axe.tscn, Cross.tscn
   - 脚本：对应 .gd 文件已创建

3. ✅ **EventBus 非全局单例** - 已修复
   - 创建独立 scripts/EventBus.gd
   - 配置为 Autoload 单例
   - 包含 40+ 类型化信号

4. ✅ **Main.tscn 场景引用** - 已修复
   - TestLevel.tscn 存在
   - 调试系统正常工作

---

## 二、架构演进方案

### 2.1 目标架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
│  Main.tscn → MainMenu → Game Loop → Victory/GameOver        │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                     Core Systems Layer                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Game.gd  │ │EventBus  │ │AudioMngr │ │SaveMngr  │       │
│  │ (状态机) │ │(信号总线)│ │(音频管理)│ │(存档管理)│       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                    Game Systems Layer                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Player   │ │ Enemy    │ │ Level    │ │ Combat   │       │
│  │ System   │ │ System   │ │ System   │ │ System   │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                     Entity Layer                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Player   │ │ Enemies  │ │ Projectiles│ │ Items   │       │
│  │ Entity   │ │ Entities │ │           │ │         │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                     Resource Layer                           │
│  Assets (art/sounds/music) │ Data (PlayerData/Config)       │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 模块重构计划

#### 2.2.1 EventBus 独立化

**现状问题：**
- EventBus 是 Game.gd 的内部类（第745-760行）
- 不是真正的全局单例
- 不支持信号断开和多参数传递

**重构方案：**

创建独立文件 `scripts/EventBus.gd`：

```gdscript
# scripts/EventBus.gd
extends Node

## ========== 游戏事件 ==========
signal player_died
signal player_respawned
signal enemy_died(enemy: Node2D, position: Vector2)
signal checkpoint_reached(checkpoint_id: String, data: Dictionary)
signal level_completed(level_name: String)
signal level_loaded(level_name: String)

## ========== UI事件 ==========
signal show_pause_menu
signal hide_pause_menu
signal show_game_over
signal show_victory
signal show_save_indicator
signal show_tutorial(tutorial_id: String)
signal update_hud(data: Dictionary)

## ========== 音频事件 ==========
signal play_sound(sound_name: String, volume_db: float)
signal play_music(music_name: String, fade_duration: float)
signal stop_music(fade_duration: float)
signal set_volume(bus_name: String, volume: float)

## ========== 战斗事件 ==========
signal damage_dealt(target: Node2D, damage: int, type: String)
signal damage_received(source: Node2D, damage: int)
signal weapon_equipped(weapon_type: int)
signal subweapon_used(subweapon_type: int)

## ========== 收集事件 ==========
signal coin_collected(amount: int)
signal item_collected(item_type: String, amount: int)
signal secret_found(secret_id: String)

## ========== 调试事件 ==========
signal debug_mode_changed(mode: String, enabled: bool)
signal debug_log(message: String)
```

**配置为 Autoload：**

修改 `project.godot`：

```ini
[autoload]
EventBus="res://scripts/EventBus.gd"
Game="res://scripts/Game.gd"
PlayerData="res://scripts/PlayerData.gd"
```

**迁移现有代码：**

需要修改的文件：
- `Game.gd`：移除内部 EventBus 类，改用 `EventBus.signal_name`
- `Player.gd`：信号连接改用 `EventBus.connect()`
- `EnemyBase.gd`：信号发射改用 `EventBus.emit()`

#### 2.2.2 AudioManager 独立模块

**现状问题：**
- Game.gd 中 `play_sound()` 只是 `print()` 占位符
- 无实际音频播放功能
- 无音频资源缓存

**重构方案：**

创建 `scripts/AudioManager.gd`：

```gdscript
# scripts/AudioManager.gd
extends Node

## 音频资源缓存
var sound_cache := {}
var music_cache := {}

## 音量设置
var master_volume := 1.0:
    set(value):
        master_volume = value
        AudioServer.set_bus_volume_db(0, linear_to_db(value))

var music_volume := 0.8:
    set(value):
        music_volume = value
        AudioServer.set_bus_volume_db(1, linear_to_db(value))

var sfx_volume := 1.0:
    set(value):
        sfx_volume = value
        AudioServer.set_bus_volume_db(2, linear_to_db(value))

## 当前播放的音乐
var current_music: AudioStreamPlayer
var music_fade_duration := 1.0

## 音效池
var sfx_pool := []
const SFX_POOL_SIZE := 10

func _ready():
    # 初始化音频池
    for i in SFX_POOL_SIZE:
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        sfx_pool.append(player)
    
    # 连接事件
    EventBus.play_sound.connect(_on_play_sound)
    EventBus.play_music.connect(_on_play_music)
    EventBus.stop_music.connect(_on_stop_music)
    EventBus.set_volume.connect(_on_set_volume)
    
    # 预加载常用音效
    preload_sounds()

func preload_sounds():
    var common_sounds := [
        "player/jump",
        "player/attack",
        "player/hurt",
        "player/land",
        "enemies/hit",
        "enemies/die",
        "ui/coin",
        "ui/pause",
        "ui/select"
    ]
    
    for sound_name in common_sounds:
        var path = "res://assets/sounds/%s.wav" % sound_name
        if ResourceLoader.exists(path):
            sound_cache[sound_name] = load(path)

func _on_play_sound(sound_name: String, volume_db: float = 0.0):
    var stream = sound_cache.get(sound_name)
    
    if not stream:
        var path = "res://assets/sounds/%s.wav" % sound_name
        if ResourceLoader.exists(path):
            stream = load(path)
            sound_cache[sound_name] = stream
        else:
            push_warning("音效文件不存在: " + sound_name)
            return
    
    # 从池中获取空闲播放器
    var player = get_available_sfx_player()
    if player:
        player.stream = stream
        player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
        player.play()

func get_available_sfx_player() -> AudioStreamPlayer:
    for player in sfx_pool:
        if not player.playing:
            return player
    # 池满，创建新播放器
    var new_player = AudioStreamPlayer.new()
    new_player.bus = "SFX"
    add_child(new_player)
    sfx_pool.append(new_player)
    return new_player

func _on_play_music(music_name: String, fade_duration: float = 1.0):
    var path = "res://assets/music/%s.ogg" % music_name
    if not ResourceLoader.exists(path):
        push_warning("音乐文件不存在: " + music_name)
        return
    
    var new_stream = music_cache.get(music_name)
    if not new_stream:
        new_stream = load(path)
        music_cache[music_name] = new_stream
    
    # 相同音乐跳过
    if current_music and current_music.stream == new_stream:
        return
    
    fade_to_music(new_stream, fade_duration)

func fade_to_music(new_stream: AudioStream, duration: float):
    # 淡出当前音乐
    if current_music and current_music.playing:
        var tween = create_tween()
        tween.tween_property(current_music, "volume_db", -40.0, duration)
        tween.tween_callback(current_music.stop)
    
    # 创建新音乐播放器
    var new_player = AudioStreamPlayer.new()
    new_player.stream = new_stream
    new_player.bus = "Music"
    new_player.volume_db = -40.0
    add_child(new_player)
    
    # 淡入
    new_player.play()
    var tween = create_tween()
    tween.tween_property(new_player, "volume_db", 
        linear_to_db(music_volume * master_volume), duration)
    
    current_music = new_player

func _on_stop_music(fade_duration: float):
    if current_music and current_music.playing:
        var tween = create_tween()
        tween.tween_property(current_music, "volume_db", -40.0, fade_duration)
        tween.tween_callback(current_music.stop)

func _on_set_volume(bus_name: String, volume: float):
    match bus_name:
        "Master":
            master_volume = volume
        "Music":
            music_volume = volume
        "SFX":
            sfx_volume = volume
```

#### 2.2.3 SaveManager 独立模块

**现状问题：**
- 存档逻辑散落在 Game.gd 中
- 不支持多存档槽
- 缺少版本校验

**重构方案：**

创建 `scripts/SaveManager.gd`：

```gdscript
# scripts/SaveManager.gd
extends Node

## 存档配置
const SAVE_SLOT_COUNT := 3
const AUTO_SAVE_SLOT := -1
const SAVE_VERSION := "1.0.0"

## 当前存档槽
var current_slot := 0

## 存档数据结构
class SaveData:
    var version: String
    var timestamp: int
    var player_data: Dictionary
    var current_level: String
    var current_checkpoint: String
    var game_time: float
    var enemies_defeated: int
    var coins_collected: int
    var secrets_found: Array
    var checkpoints: Dictionary
    
    func serialize() -> Dictionary:
        return {
            "version": version,
            "timestamp": timestamp,
            "player_data": player_data,
            "current_level": current_level,
            "current_checkpoint": current_checkpoint,
            "game_time": game_time,
            "enemies_defeated": enemies_defeated,
            "coins_collected": coins_collected,
            "secrets_found": secrets_found,
            "checkpoints": checkpoints
        }
    
    static func deserialize(data: Dictionary) -> SaveData:
        var save = SaveData.new()
        save.version = data.get("version", "1.0.0")
        save.timestamp = data.get("timestamp", 0)
        save.player_data = data.get("player_data", {})
        save.current_level = data.get("current_level", "")
        save.current_checkpoint = data.get("current_checkpoint", "")
        save.game_time = data.get("game_time", 0.0)
        save.enemies_defeated = data.get("enemies_defeated", 0)
        save.coins_collected = data.get("coins_collected", 0)
        save.secrets_found = data.get("secrets_found", [])
        save.checkpoints = data.get("checkpoints", {})
        return save

func save_game(slot: int = current_slot) -> bool:
    var save_data = SaveData.new()
    save_data.version = SAVE_VERSION
    save_data.timestamp = Time.get_unix_time_from_system()
    save_data.player_data = Game.player_data.serialize()
    save_data.current_level = Game.current_level
    save_data.current_checkpoint = Game.current_checkpoint
    save_data.game_time = Game.game_time
    save_data.enemies_defeated = Game.player_data.enemies_defeated
    save_data.coins_collected = Game.player_data.coins_collected
    save_data.secrets_found = Game.player_data.secrets_found
    save_data.checkpoints = serialize_checkpoints()
    
    var path = get_save_path(slot)
    var file = FileAccess.open(path, FileAccess.WRITE)
    
    if file:
        file.store_var(save_data.serialize())
        file.close()
        EventBus.show_save_indicator.emit()
        print("游戏已保存到槽位 %d" % slot)
        return true
    
    push_error("保存失败：无法写入文件")
    return false

func load_game(slot: int) -> bool:
    var path = get_save_path(slot)
    
    if not FileAccess.file_exists(path):
        push_warning("存档不存在：槽位 %d" % slot)
        return false
    
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        push_error("读取失败：无法打开文件")
        return false
    
    var raw_data = file.get_var()
    file.close()
    
    var save_data = SaveData.deserialize(raw_data)
    
    # 版本校验
    if not validate_version(save_data.version):
        push_error("存档版本不兼容：%s vs %s" % [save_data.version, SAVE_VERSION])
        return false
    
    # 恢复游戏状态
    Game.player_data.deserialize(save_data.player_data)
    Game.current_level = save_data.current_level
    Game.current_checkpoint = save_data.current_checkpoint
    Game.game_time = save_data.game_time
    
    current_slot = slot
    
    print("游戏已从槽位 %d 加载" % slot)
    return true

func delete_save(slot: int) -> bool:
    var path = get_save_path(slot)
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
        return true
    return false

func get_save_path(slot: int) -> String:
    if slot == AUTO_SAVE_SLOT:
        return "user://autosave.dat"
    return "user://save_slot_%d.dat" % slot

func get_all_save_slots() -> Array[Dictionary]:
    var slots: Array[Dictionary] = []
    
    for i in range(SAVE_SLOT_COUNT):
        var path = get_save_path(i)
        var slot_info = {"slot": i}
        
        if FileAccess.file_exists(path):
            var file = FileAccess.open(path, FileAccess.READ)
            if file:
                var raw_data = file.get_var()
                var save_data = SaveData.deserialize(raw_data)
                slot_info["empty"] = false
                slot_info["level"] = save_data.current_level
                slot_info["time"] = format_play_time(save_data.game_time)
                slot_info["date"] = Time.get_datetime_string_from_unix_time(save_data.timestamp)
                slot_info["progress"] = calculate_progress(save_data)
            else:
                slot_info["empty"] = true
        else:
            slot_info["empty"] = true
        
        slots.append(slot_info)
    
    return slots

func validate_version(save_version: String) -> bool:
    # 简单版本校验：主版本号匹配
    var current_major = SAVE_VERSION.split(".")[0]
    var save_major = save_version.split(".")[0]
    return current_major == save_major

func format_play_time(seconds: float) -> String:
    var hours = int(seconds / 3600)
    var minutes = int((seconds - hours * 3600) / 60)
    var secs = int(seconds) % 60
    return "%02d:%02d:%02d" % [hours, minutes, secs]

func calculate_progress(save_data: SaveData) -> float:
    # 基于关卡完成度计算进度
    var level_order = [
        "castle_exterior",
        "main_hall", 
        "catacombs",
        "banquet_hall",
        "clock_tower",
        "throne_room"
    ]
    var current_index = level_order.find(save_data.current_level)
    if current_index == -1:
        return 0.0
    return float(current_index + 1) / level_order.size() * 100.0

func serialize_checkpoints() -> Dictionary:
    var serialized := {}
    for key in Game.checkpoints.keys():
        serialized[key] = Game.checkpoints[key].serialize()
    return serialized

func auto_save():
    save_game(AUTO_SAVE_SLOT)
    print("自动保存完成")
```

---

## 三、四阶段开发路线图

### 阶段一：原型完善期（Week 1-2）

#### Week 1：修复与补全

**Day 1-2：代码缺陷修复**

| 任务 | 文件 | 具体操作 |
|------|------|----------|
| 添加缺失方法 | Player.gd | 在类中添加 `gain_experience(experience: int)` 方法 |
| 修复方法调用 | EnemyBase.gd:302 | 改为 `Game.player_data.gain_experience(experience_reward)` |
| 重构EventBus | 新建EventBus.gd | 提取为独立单例，配置Autoload |
| 更新信号连接 | Game.gd, Player.gd | 所有信号改用新的EventBus |

**Player.gd 新增方法：**

```gdscript
## 经验值相关
func gain_experience(amount: int):
    if Game.player_data:
        Game.player_data.experience += amount
        EventBus.update_hud.emit({"experience": Game.player_data.experience})
        
        # 检查升级
        check_level_up()
        print("获得经验: +%d, 当前: %d" % [amount, Game.player_data.experience])

func check_level_up():
    var current_exp = Game.player_data.experience
    var current_level = Game.player_data.level
    var exp_needed = get_exp_for_level(current_level + 1)
    
    if current_exp >= exp_needed:
        level_up()

func level_up():
    Game.player_data.level += 1
    Game.player_data.skill_points += 1
    
    # 升级奖励
    max_health += 10
    health = max_health
    attack_damage += 2
    
    # 升级特效
    play_sound("level_up")
    # TODO: 显示升级动画
    
    print("升级！当前等级: %d" % Game.player_data.level)

func get_exp_for_level(level: int) -> int:
    # 指数增长公式
    return int(100 * pow(1.5, level - 1))
```

**Day 3-4：创建缺失场景**

需要创建的场景文件：

```
scenes/
├── projectiles/
│   ├── BaseProjectile.tscn      # 投掷物基类
│   ├── HolyWater.tscn           # 圣水
│   ├── Knife.tscn               # 匕首
│   ├── Axe.tscn                 # 斧头
│   └── Cross.tscn               # 十字架
├── items/
│   ├── Coin.tscn                # 金币
│   ├── HealthPotion.tscn        # 生命药水
│   └── EnergyPotion.tscn        # 能量药水
├── enemies/
│   ├── Skeleton.tscn            # 骷髅敌人
│   ├── Ghost.tscn               # 幽灵敌人
│   ├── Bat.tscn                 # 蝙蝠敌人
│   └── Gargoyle.tscn            # 石像鬼敌人
└── ui/
    ├── DamageNumber.tscn        # 伤害数字
    ├── PauseMenu.tscn           # 暂停菜单
    └── MainMenu.tscn            # 主菜单
```

**BaseProjectile.tscn 基类：**

```gdscript
# scripts/BaseProjectile.gd
extends Area2D

@export var damage := 10
@export var speed := 300.0
@export var lifetime := 3.0

var direction := Vector2.RIGHT
var velocity := Vector2.ZERO

@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D

func _ready():
    # 设置生命周期
    await get_tree().create_timer(lifetime).timeout
    queue_free()

func _physics_process(delta):
    position += velocity * delta

func initialize(dir: Vector2, spd: float = speed):
    direction = dir.normalized()
    velocity = direction * spd
    
    # 根据方向翻转
    if direction.x < 0:
        sprite.flip_h = true

func _on_body_entered(body):
    if body.is_in_group("enemy"):
        if body.has_method("take_damage"):
            body.take_damage(damage, global_position)
        on_hit()
    elif body.is_in_group("terrain"):
        on_hit_terrain()

func on_hit():
    # 命中特效
    queue_free()

func on_hit_terrain():
    # 撞墙处理
    queue_free()
```

**Day 5-7：修复场景引用**

- 修复 Main.tscn 的 TestLevel.tscn 引用
- 创建基础 TileSet 资源
- 修复 TestLevel.tscn 的所有资源引用
- 验证 DebugTest.tscn 可正常运行

#### Week 2：系统集成

**Day 1-3：UI系统实现**

创建 UI 场景文件：

| 场景 | 功能 | 包含节点 |
|------|------|----------|
| MainMenu.tscn | 主菜单 | 标题、新游戏、继续、设置、退出按钮 |
| PauseMenu.tscn | 暂停菜单 | 继续、设置、返回主菜单按钮 |
| GameOver.tscn | 游戏结束 | 死亡信息、重试、返回主菜单 |
| Victory.tscn | 胜利画面 | 统计数据、返回主菜单 |
| HUD.tscn | 游戏HUD | 生命条、能量条、金币、技能图标 |

**Day 4-5：AudioManager 集成**

- 创建 AudioManager.gd
- 收集/创建基础音效（至少15个）
- 创建背景音乐（至少2首）
- 配置音频总线

**基础音效清单：**

```
assets/sounds/
├── player/
│   ├── jump.wav
│   ├── attack.wav
│   ├── hurt.wav
│   ├── die.wav
│   ├── land.wav
│   └── dash.wav
├── enemies/
│   ├── hit.wav
│   ├── die.wav
│   └── alert.wav
├── ui/
│   ├── coin.wav
│   ├── pause.wav
│   ├── select.wav
│   └── confirm.wav
└── environment/
    ├── checkpoint.wav
    └── door.wav
```

**Day 6-7：第一关卡制作**

创建 `levels/CastleExterior.tscn`：

- 关卡结构（地面、平台、墙壁）
- 敌人放置点（至少5个）
- 可收集物品（至少10个金币）
- 检查点（至少1个）

### 阶段二：核心玩法完善（Week 3-5）

#### Week 3：战斗系统深化

**武器系统完善：**

| 武器类型 | 动画需求 | 特效需求 | 手感差异 |
|---------|---------|---------|---------|
| 剑 | 3帧攻击动画 | 挥砍轨迹 | 快速、中等伤害 |
| 斧 | 4帧攻击动画 | 重击火花 | 慢速、高伤害 |
| 锤 | 5帧攻击动画 | 震荡波 | 最慢、击退效果 |

**连击系统设计：**

```gdscript
# 在 Player.gd 中添加

var combo_count := 0
var combo_timer := 0.0
const COMBO_WINDOW := 0.5  # 连击窗口时间

func process_attack():
    if is_attacking and attack_cooldown <= 0:
        perform_attack()
        
        # 连击计数
        if attack_cooldown <= COMBO_WINDOW:
            combo_count += 1
            if combo_count > 3:
                combo_count = 1
        else:
            combo_count = 1
        
        # 连击加成
        var combo_damage_multiplier = 1.0 + (combo_count - 1) * 0.2
        
        combo_timer = COMBO_WINDOW

func update_timers(delta: float):
    # ... 现有代码 ...
    
    if combo_timer > 0:
        combo_timer -= delta
        if combo_timer <= 0:
            combo_count = 0
```

**敌人AI优化：**

EnemyBase.gd 状态机扩展：

```gdscript
enum State {
    IDLE,       # 待机
    PATROL,     # 巡逻
    CHASE,      # 追击
    ATTACK,     # 攻击
    HURT,       # 受伤
    DEATH       # 死亡
}

var current_state := State.IDLE
var state_timer := 0.0

func update_ai(delta: float):
    match current_state:
        State.IDLE:
            ai_idle(delta)
        State.PATROL:
            ai_patrol(delta)
        State.CHASE:
            ai_chase(delta)
        State.ATTACK:
            ai_attack(delta)

func ai_idle(delta: float):
    # 检测玩家
    if can_see_player():
        change_state(State.CHASE)

func ai_chase(delta: float):
    # 追击玩家
    var direction = (Game.player.global_position - global_position).normalized()
    velocity = direction * chase_speed
    
    # 攻击距离检测
    if distance_to_player() <= attack_range:
        change_state(State.ATTACK)
    
    # 丢失目标
    if not can_see_player():
        state_timer += delta
        if state_timer > chase_timeout:
            change_state(State.PATROL)
```

#### Week 4：关卡设计

**关卡规划：**

| 关卡 | 主题 | 主要敌人 | 收集品 | Boss |
|------|------|---------|--------|------|
| CastleExterior | 城堡外围 | 骷髅、蝙蝠 | 20金币 | - |
| MainHall | 主大厅 | 骷髅、幽灵 | 25金币 | 小Boss: 骷髅骑士 |
| Catacombs | 地下墓穴 | 幽灵、石像鬼 | 30金币 | - |
| BanquetHall | 宴会厅 | 石像鬼、骷髅 | 25金币 | 中Boss: 血月女巫 |
| ClockTower | 钟楼 | 蝙蝠、石像鬼 | 20金币 | - |
| ThroneRoom | 王座室 | 全部类型 | 15金币 | 最终Boss: 德古拉 |

**关卡连接系统：**

```gdscript
# scripts/LevelTransition.gd
extends Area2D

@export var target_level: String = ""
@export var spawn_point: String = ""

func _on_body_entered(body):
    if body.is_in_group("player"):
        transition_to_level()

func transition_to_level():
    # 过渡动画
    var fade = ColorRect.new()
    fade.color = Color.BLACK
    fade.modulate.a = 0
    get_tree().root.add_child(fade)
    
    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, 0.5)
    tween.tween_callback(func():
        Game.change_level(target_level)
        # TODO: 传送到指定spawn_point
    )
    tween.tween_property(fade, "modulate:a", 0.0, 0.5)
    tween.tween_callback(fade.queue_free)
```

#### Week 5：角色成长系统

**经验值系统：**

| 来源 | 经验值 |
|------|--------|
| 普通敌人 | 10-30 |
| 精英敌人 | 50-100 |
| 小Boss | 200-300 |
| 大Boss | 500-1000 |
| 发现秘密 | 50-100 |

**技能树设计：**

```
战斗技能树
├── 连击强化 (3级)
│   ├── L1: 连击窗口 +0.2s
│   ├── L2: 连击伤害 +15%
│   └── L3: 第3击暴击
├── 吸血攻击 (3级)
│   ├── L1: 击杀回复 5HP
│   ├── L2: 击杀回复 10HP
│   └── L3: 每次攻击回复 2HP
└── 暴击精通 (3级)
    ├── L1: 暴击率 +5%
    ├── L2: 暴击率 +10%
    └── L3: 暴击伤害 +50%

暗影技能树
├── 暗影延长 (3级)
│   ├── L1: 持续时间 +1s
│   ├── L2: 持续时间 +2s
│   └── L3: 暗影中回血
├── 能量恢复 (3级)
│   ├── L1: 恢复速度 +20%
│   ├── L2: 恢复速度 +40%
│   └── L3: 击杀恢复能量
└── 冲刺强化 (3级)
    ├── L1: 冲刺距离 +20%
    ├── L2: 冲刺CD -0.1s
    └── L3: 冲刺无敌延长

辅助技能树
├── 跳跃强化 (3级)
│   ├── L1: 跳跃高度 +10%
│   ├── L2: 空中控制 +20%
│   └── L3: 三段跳
├── 生命强化 (3级)
│   ├── L1: 最大生命 +20
│   ├── L2: 最大生命 +40
│   └── L3: 自动回复
└── 感知强化 (3级)
    ├── L1: 发现隐藏门
    ├── L2: 显示敌人生命
    └── L3: 显示全地图
```

### 阶段三：内容制作（Week 6-8）

#### Week 6：美术资源制作

**角色动画规格：**

| 角色 | 动画 | 帧数 | 帧率 |
|------|------|------|------|
| 玩家 | idle | 4 | 8fps |
| 玩家 | run | 6 | 12fps |
| 玩家 | jump | 2 | 8fps |
| 玩家 | attack | 3 | 12fps |
| 玩家 | hurt | 2 | 8fps |
| 玩家 | die | 6 | 8fps |
| 骷髅 | idle | 4 | 6fps |
| 骷髅 | walk | 4 | 8fps |
| 骷髅 | attack | 3 | 10fps |
| 幽灵 | idle | 4 | 6fps |
| 蝙蝠 | fly | 4 | 10fps |
| 石像鬼 | idle | 4 | 6fps |
| 石像鬼 | attack | 4 | 8fps |

**TileSet 规格：**

```
基础瓦片尺寸: 16x16
自动瓦片: 支持 47-tile 模式

瓦片类型:
├── 地面 (floor) - 可行走
├── 墙壁 (wall) - 阻挡
├── 平台 (platform) - 可站立的单向平台
├── 尖刺 (spike) - 伤害
├── 岩浆 (lava) - 持续伤害
├── 水 (water) - 减速
└── 检查点 (checkpoint) - 存档点
```

#### Week 7：音频内容制作

**音效清单（50+）：**

```
玩家音效 (15个)
├── jump.wav, jump_land.wav
├── attack_sword.wav, attack_axe.wav, attack_hammer.wav
├── hurt_01.wav, hurt_02.wav
├── die.wav
├── dash.wav
├── heal.wav
├── level_up.wav
└── shadow_form_on.wav, shadow_form_off.wav

敌人音效 (20个)
├── skeleton_alert.wav, skeleton_attack.wav
├── ghost_appear.wav, ghost_attack.wav
├── bat_screech.wav
├── gargoyle_stone.wav, gargoyle_attack.wav
├── generic_hit_01.wav ~ generic_hit_05.wav
├── generic_die_01.wav ~ generic_die_03.wav
└── boss_roar.wav, boss_attack.wav

UI音效 (10个)
├── coin.wav
├── pause.wav, unpause.wav
├── select.wav, confirm.wav, cancel.wav
├── menu_open.wav, menu_close.wav
└── save.wav, load.wav

环境音效 (10个)
├── door_open.wav, door_close.wav
├── checkpoint_activate.wav
├── secret_found.wav
├── fire_ambient.wav
├── water_ambient.wav
└── wind_ambient.wav
```

**背景音乐清单：**

| 音乐 | 用途 | 时长 | 风格 |
|------|------|------|------|
| bgm_menu | 主菜单 | 2:00 | 神秘、大气 |
| bgm_castle_exterior | 城堡外围 | 3:00 | 紧张、冒险 |
| bgm_main_hall | 主大厅 | 3:00 | 庄严、诡异 |
| bgm_catacombs | 地下墓穴 | 3:00 | 阴森、恐怖 |
| bgm_banquet_hall | 宴会厅 | 3:00 | 华丽、诡异 |
| bgm_clock_tower | 钟楼 | 3:00 | 机械、紧张 |
| bgm_throne_room | 王座室 | 3:00 | 史诗、决斗 |
| bgm_boss | Boss战 | 4:00 | 激烈、紧张 |
| bgm_victory | 胜利 | 1:30 | 凯旋、欢快 |
| bgm_game_over | 失败 | 0:30 | 悲伤 |

#### Week 8：内容填充

**每关内容要求：**

| 内容类型 | 最少数量 | 说明 |
|---------|---------|------|
| 普通敌人 | 10-20 | 按关卡递增 |
| 精英敌人 | 2-3 | 变种敌人 |
| 金币 | 20-30 | 可收集品 |
| 秘密区域 | 2-3 | 隐藏房间 |
| 检查点 | 1-2 | 存档点 |
| 生命药水 | 3-5 | 回复道具 |

### 阶段四：优化与发布（Week 9-10）

#### Week 9：优化与测试

**性能优化清单：**

```
□ 对象池实现
  ├── 敌人对象池
  ├── 特效对象池
  └── 投射物对象池

□ 渲染优化
  ├── 视锥剔除
  ├── Y-sort 优化
  └── 粒子数量限制

□ 内存优化
  ├── 资源卸载策略
  ├── 场景预加载
  └── 缓存管理

□ 加载优化
  ├── 场景异步加载
  ├── 资源预加载
  └── 加载界面
```

**测试清单：**

```
□ 功能测试
  ├── 所有技能正常工作
  ├── 所有关卡可通关
  ├── 存档/读档正常
  └── UI 所有功能可用

□ 边缘情况测试
  ├── 空血状态
  ├── 能量耗尽状态
  ├── 极端位置操作
  └── 连续快速输入

□ 性能测试
  ├── 低端设备测试
  ├── 长时间运行稳定性
  └── 内存泄漏检测

□ 用户测试
  ├── 新手引导有效性
  ├── 难度曲线合理性
  └── 操作手感反馈
```

#### Week 10：发布准备

**发布材料清单：**

```
□ 游戏截图
  ├── 标题界面
  ├── 游戏玩法 (至少5张)
  ├── Boss战
  └── 结局画面

□ 宣传视频
  ├── 游戏预告 (30秒)
  └── 玩法展示 (2分钟)

□ 文档
  ├── 用户手册
  ├── 更新日志
  └── 已知问题列表

□ 打包
  ├── Windows 版本
  ├── Web 版本 (可选)
  └── 安装程序
```

---

## 四、任务跟踪与验收标准

### 4.1 每周验收标准

| 周次 | 验收标准 | 验证方法 |
|------|----------|----------|
| Week 1 | 所有 P0 bug 修复完成 | 运行 DebugTest 无报错 |
| Week 2 | 第一关卡可完整游玩 | 从开始到检查点无阻塞 |
| Week 3 | 战斗系统完整可用 | 连击、副武器正常工作 |
| Week 4 | 所有关卡框架完成 | 可切换所有关卡 |
| Week 5 | 角色成长系统可用 | 升级、技能正常 |
| Week 6 | 美术资源替换完成 | 无占位符素材 |
| Week 7 | 音频内容完整 | 所有音效、音乐可用 |
| Week 8 | 内容填充完成 | 游戏流程完整 |
| Week 9 | 性能达标 | 60fps 稳定运行 |
| Week 10 | 发布版本就绪 | 通过所有测试 |

### 4.2 质量检查点

**代码质量：**

- [ ] 无编译警告
- [ ] 无运行时错误
- [ ] 代码注释完整
- [ ] 遵循 GDScript 风格指南

**功能质量：**

- [ ] 所有核心功能可用
- [ ] 所有 UI 可交互
- [ ] 存档系统可靠
- [ ] 无游戏-breaking bug

**体验质量：**

- [ ] 操作响应及时
- [ ] 难度曲线合理
- [ ] 教程清晰
- [ ] 无明显卡顿

---

## 五、风险与应对

### 5.1 技术风险

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|----------|
| Godot 版本兼容问题 | 高 | 中 | 使用稳定版本，避免新特性 |
| 性能不达标 | 高 | 中 | 提前优化，预留优化时间 |
| 资源文件过大 | 中 | 低 | 压缩资源，流式加载 |

### 5.2 进度风险

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|----------|
| 美术资源延期 | 高 | 中 | 使用占位符，逐步替换 |
| 功能实现复杂度超预期 | 中 | 高 | 功能裁剪，分阶段实现 |
| 测试发现重大bug | 高 | 中 | 预留缓冲时间 |

---

## 六、附录

### 6.1 文件创建清单

**必须创建的文件：**

```
scripts/
├── EventBus.gd
├── AudioManager.gd
├── SaveManager.gd
├── BaseProjectile.gd
└── LevelTransition.gd

scenes/
├── projectiles/
│   ├── HolyWater.tscn
│   ├── Knife.tscn
│   ├── Axe.tscn
│   └── Cross.tscn
├── items/
│   ├── Coin.tscn
│   ├── HealthPotion.tscn
│   └── EnergyPotion.tscn
├── enemies/
│   ├── Skeleton.tscn
│   ├── Ghost.tscn
│   ├── Bat.tscn
│   └── Gargoyle.tscn
└── ui/
    ├── MainMenu.tscn
    ├── PauseMenu.tscn
    ├── GameOver.tscn
    ├── Victory.tscn
    └── HUD.tscn

levels/
├── CastleExterior.tscn
├── MainHall.tscn
├── Catacombs.tscn
├── BanquetHall.tscn
├── ClockTower.tscn
└── ThroneRoom.tscn
```

### 6.2 快捷键映射

| 快捷键 | 功能 | 使用场景 |
|--------|------|----------|
| F1 | 重新生成测试关卡 | 调试 |
| F2 | 清除生成内容 | 调试 |
| F5 | 重新开始游戏 | 调试 |
| F6 | 保存游戏 | 调试 |
| F7 | 加载游戏 | 调试 |
| F8 | 切换无敌模式 | 调试 |
| F9 | 切换一击必杀 | 调试 |
| ESC | 暂停游戏 | 游戏 |
| WASD/方向键 | 移动 | 游戏 |
| 空格 | 跳跃 | 游戏 |
| J | 攻击 | 游戏 |
| K | 副武器 | 游戏 |
| Shift | 冲刺 | 游戏 |

---

**文档结束**

> 本路线图将根据实际开发进度动态调整，建议每周进行一次进度评审和计划更新。
