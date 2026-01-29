# Castle of Shadows 开发指南与路线图

## 概述

本文档是《Castle of Shadows》游戏的完整开发指南，涵盖从原型制作到最终发布的整个开发流程。本指南采用**迭代增量开发**方法论，确保项目始终朝着可发布的产品稳步前进。

## 开发策略

### 核心理念
- **先可玩，后美化**：功能优先，视觉效果逐步完善
- **小步快跑**：每天都有可见进展，每周都有可验证成果
- **持续集成**：每次提交都保持项目可运行状态
- **用户中心**：定期测试，根据反馈迭代改进

### 开发四阶段
```
1. 基础原型 (1-2周) - 验证核心机制
2. 核心玩法 (2-3周) - 建立完整游戏循环
3. 内容制作 (3-4周) - 替换资源，丰富内容
4. 优化发布 (1-2周) - 性能优化，bug修复
```

## 第一阶段：基础原型 (Weeks 1-2)

### 目标
创建可运行的游戏框架，验证所有核心机制的技术可行性。

### 核心任务

#### 1. 占位符资源创建
```bash
# 创建占位符资源的Python脚本示例
# save as: scripts/create_placeholders.py

import os
from PIL import Image, ImageDraw

def create_player_placeholder():
    """创建玩家角色占位符"""
    img = Image.new('RGBA', (32, 48), (0, 255, 0, 255))  # 绿色方块
    draw = ImageDraw.Draw(img)
    draw.rectangle([4, 4, 28, 44], outline=(255, 255, 255), width=2)
    os.makedirs("assets/art/characters/player", exist_ok=True)
    img.save("assets/art/characters/player/idle_01.png")
    print("✓ 创建玩家占位符")

def create_enemy_placeholder():
    """创建敌人占位符"""
    img = Image.new('RGBA', (24, 32), (255, 0, 0, 255))  # 红色圆形
    draw = ImageDraw.Draw(img)
    draw.ellipse([2, 2, 22, 30], outline=(255, 255, 255), width=2)
    os.makedirs("assets/art/enemies/skeleton", exist_ok=True)
    img.save("assets/art/enemies/skeleton/idle_01.png")
    print("✓ 创建敌人占位符")

def create_tile_placeholders():
    """创建瓦片占位符"""
    tiles = {
        "floor": (128, 128, 128),      # 灰色 - 地板
        "wall": (64, 64, 64),         # 深灰 - 墙壁
        "spike": (255, 0, 0),         # 红色 - 尖刺
        "platform": (139, 69, 19),    # 棕色 - 平台
    }

    os.makedirs("assets/art/tilesets/basic", exist_ok=True)

    for name, color in tiles.items():
        img = Image.new('RGB', (16, 16), color)
        img.save(f"assets/art/tilesets/basic/{name}.png")
        print(f"✓ 创建瓦片占位符: {name}")

    # 创建自动瓦片配置
    create_autotile_config()

if __name__ == "__main__":
    create_player_placeholder()
    create_enemy_placeholder()
    create_tile_placeholders()
```

#### 2. 核心系统验证
需要测试和验证的系统：

| 系统 | 验证标准 | 优先级 |
|------|----------|--------|
| 玩家移动 | 平滑移动，无卡顿 | P0 |
| 跳跃系统 | 二段跳、落地检测 | P0 |
| 基础攻击 | 攻击动画、命中检测 | P0 |
| 碰撞系统 | 玩家与环境的碰撞 | P0 |
| 相机跟随 | 平滑跟随，边界限制 | P1 |
| 生命系统 | 伤害计算、死亡处理 | P1 |

#### 3. 测试关卡设计
创建 `levels/test_prototype.tscn`，包含：
- 基础平台结构
- 测试用的敌人生成点
- 玩家重生点
- 基础UI元素（生命条、能量条）

### 交付物要求
- ✅ 可执行的 `.exe` 文件（即使画面简陋）
- ✅ 完整控制说明文档
- ✅ 已知问题列表
- ✅ 性能基准数据（帧率、加载时间）

## 第二阶段：核心玩法 (Weeks 3-5)

### 目标
丰富游戏系统，建立完整的玩法循环，验证游戏乐趣。

### 核心任务

#### 1. 战斗系统扩展
```gdscript
# 扩展 Player.gd 实现连击系统
func setup_combo_system():
    combo_timer = 0
    combo_count = 0
    max_combo = 3

func process_attack_combo():
    if Input.is_action_just_pressed("attack"):
        if combo_timer > 0 and combo_count < max_combo:
            combo_count += 1
            perform_combo_attack(combo_count)
            combo_timer = COMBO_WINDOW
        else:
            combo_count = 1
            perform_basic_attack()
            combo_timer = COMBO_WINDOW

# 实现副武器系统
enum SubWeapon { HOLY_WATER, KNIFE, AXE, CROSS }

func use_subweapon(weapon_type: SubWeapon):
    match weapon_type:
        SubWeapon.HOLY_WATER:
            create_holy_water_projectile()
        SubWeapon.KNIFE:
            create_knife_projectile()
        SubWeapon.AXE:
            create_axe_projectile()
        SubWeapon.CROSS:
            activate_cross_attack()
```

#### 2. 进度系统实现
需要实现的数据结构：
```gdscript
# PlayerData.gd 扩展
class SkillTree:
    var combat_skills = {
        "combo_master": {"unlocked": false, "requires": ["basic_combo"]},
        "critical_strike": {"unlocked": false, "requires": ["combo_master"]},
        "life_steal": {"unlocked": false, "requires": ["shadow_form"]}
    }

    var agility_skills = {
        "double_jump": {"unlocked": true, "requires": []},
        "air_dash": {"unlocked": false, "requires": ["double_jump"]},
        "wall_jump": {"unlocked": false, "requires": ["air_dash"]}
    }

    var shadow_skills = {
        "shadow_form": {"unlocked": false, "requires": []},
        "shadow_clone": {"unlocked": false, "requires": ["shadow_form"]},
        "shadow_step": {"unlocked": false, "requires": ["shadow_clone"]}
    }
```

#### 3. 关卡设计 - 城堡外围区域
```
城堡外围区域规划：
┌─────────────────────────────────────┐
│ 入口广场 (100×200像素)              │
│   - 基础教程区域                     │
│   - 3个骷髅敌人                      │
│   - 1个检查点                        │
├─────────────────────────────────────┤
│ 吊桥区域 (150×200像素)               │
│   - 平台跳跃挑战                      │
│   - 2个石像鬼敌人                     │
│   - 机关谜题（启动吊桥）               │
├─────────────────────────────────────┤
│ 城堡大门 (80×200像素)                 │
│   - 第一个迷你Boss：守门尸鬼           │
│   - Boss战机制教学                    │
│   - 区域解锁奖励                       │
└─────────────────────────────────────┘
```

#### 4. Boss战原型 - 守门尸鬼
```gdscript
# scripts/bosses/Gatekeeper.gd
extends EnemyBase

enum BossPhase { PHASE_1, PHASE_2, PHASE_3 }

var current_phase = BossPhase.PHASE_1
var phase_health_thresholds = [0.7, 0.3]  # 70%, 30%

func process_boss_phase():
    var health_percent = float(health) / max_health

    if current_phase == BossPhase.PHASE_1 and health_percent <= phase_health_thresholds[0]:
        transition_to_phase_2()
    elif current_phase == BossPhase.PHASE_2 and health_percent <= phase_health_thresholds[1]:
        transition_to_phase_3()

func transition_to_phase_2():
    current_phase = BossPhase.PHASE_2
    # 激活新技能
    activate_skill("summon_minions")
    activate_skill("ground_slam")

    # 播放阶段转换动画
    animation_player.play("phase_transition_2")
    emit_signal("phase_changed", 2)

func get_attack_pattern():
    match current_phase:
        BossPhase.PHASE_1:
            return ["basic_swing", "charge_attack"]
        BossPhase.PHASE_2:
            return ["basic_swing", "charge_attack", "summon_minions", "ground_slam"]
        BossPhase.PHASE_3:
            return ["frenzy_attack", "area_slam", "summon_minions"]
```

### 交付物要求
- ✅ 包含完整第一区域的游戏版本
- ✅ 所有核心系统可运行并集成
- ✅ 平衡性测试报告
- ✅ 用户测试反馈汇总

## 第三阶段：内容制作 (Weeks 6-9)

### 目标
用高质量资源替换占位符，丰富游戏内容，完善用户体验。

### 核心任务

#### 1. 美术资源制作规范

##### 角色动画规格
```
艾登·夜行者 (32×48像素)
┌─────────────────────────────────────┐
│ 动画类型       │ 帧数 │ 说明         │
├─────────────────────────────────────┤
│ idle           │  4   │ 站立待机     │
│ run            │  8   │ 奔跑         │
│ jump_up        │  3   │ 起跳上升     │
│ jump_down      │  3   │ 下落         │
│ attack_sword   │  6   │ 剑攻击       │
│ attack_special │  8   │ 特殊攻击     │
│ hurt           │  4   │ 受伤         │
│ die            │  8   │ 死亡         │
│ shadow_form    │  4   │ 暗影形态     │
└─────────────────────────────────────┘

颜色规范：
- 皮甲： #4a4a4a 到 #787878
- 披风： #8b0000 到 #b22222
- 金属： #c0c0c0 到 #e6e6e6
- 特效： 根据技能类型
```

##### 敌人资源规划
```yaml
# assets/art/enemies/enemy_manifest.yaml
enemies:
  skeleton:
    sprite_size: [24, 32]
    animations:
      idle: 4 frames
      walk: 8 frames
      attack: 6 frames
      hurt: 3 frames
      die: 8 frames
    palette: ["#e6e6e6", "#b8b8b8", "#969696"]

  ghost:
    sprite_size: [32, 32]
    transparency: 0.6
    animations:
      float: 8 frames
      attack: 4 frames
      vanish: 10 frames
    palette: ["#2d4a78", "#3c5a96", "#4a78b4"]

  bat_swarm:
    sprite_size: [16, 16]
    count: 3
    animations:
      fly: 8 frames
      dive: 4 frames
    palette: ["#960000", "#c80000"]
```

#### 2. 音频内容制作流程

##### 音乐制作时间线
```
Week 6: 主菜单音乐 + 城堡外围BGM
Week 7: 主大厅BGM + 地下墓穴BGM
Week 8: 宴会厅BGM + 钟楼BGM
Week 9: 最终区域BGM + Boss战音乐
```

##### 音效制作清单
```bash
# 使用Bfxr生成基础音效
# 玩家音效
bfxr --type pickup --player_hit.wav
bfxr --type shoot --player_attack.wav
bfxr --type jump --player_jump.wav

# 敌人音效
bfxr --type hurt --enemy_hurt.wav
bfxr --type explosion --enemy_death.wav

# UI音效
bfxr --type select --ui_select.wav
bfxr --type powerup --ui_confirm.wav
```

#### 3. 关卡内容填充检查表

**每个区域必须包含：**
- [ ] 独特的视觉主题和配色
- [ ] 至少2种新的敌人类型
- [ ] 1个环境机制/谜题
- [ ] 3个以上的秘密房间
- [ ] 区域特定的收集品
- [ ] 环境叙事元素（日记、涂鸦等）
- [ ] 保存点/检查点
- [ ] 连接到其他区域的路径

### 交付物要求
- ✅ 所有美术资源完成度90%以上
- ✅ 音频内容完成度100%
- ✅ 全区域可探索，内容完整
- ✅ 完整的叙事体验（过场、对话）

## 第四阶段：优化发布 (Weeks 10-11)

### 目标
性能优化，bug修复，准备发布版本。

### 核心任务

#### 1. 性能优化清单
```gdscript
# scripts/performance/Optimizer.gd
class_name PerformanceOptimizer

static func optimize_game():
    # 1. 图集打包
    pack_texture_atlases()

    # 2. 内存管理
    setup_memory_pools()
    enable_garbage_collection()

    # 3. 加载优化
    implement_streaming_loader()
    preload_critical_assets()

    # 4. 渲染优化
    optimize_shaders()
    reduce_draw_calls()

    # 5. 脚本优化
    optimize_gdscript_calls()
    cache_frequent_operations()

static func pack_texture_atlases():
    # 按类型打包精灵
    var categories = ["characters", "enemies", "tilesets", "ui"]
    for category in categories:
        var packer = TexturePacker.new()
        packer.pack_directory("assets/art/" + category)
        packer.save("assets/atlases/" + category + "_atlas.png")
```

#### 2. 质量保证流程

**测试矩阵：**
```yaml
platforms:
  - windows_10
  - windows_11
  - linux_ubuntu
  - web_browser

test_types:
  functionality:
    - player_controls
    - combat_system
    - progression
    - save_load
  performance:
    - frame_rate: ">30fps minimum"
    - load_time: "<3 seconds"
    - memory_usage: "<512MB peak"
  compatibility:
    - resolution: ["1920x1080", "1366x768", "1280x720"]
    - input: ["keyboard", "gamepad_xbox", "gamepad_ps"]
```

**Bug分类和优先级：**
```
P0 - 崩溃/阻塞性bug (必须修复)
P1 - 严重影响游戏体验 (高优先级)
P2 - 功能问题但不阻塞进度 (中优先级)
P3 - 轻微问题/视觉瑕疵 (低优先级)
P4 - 建议/改进 (非bug)
```

#### 3. 发布准备清单

**版本文件：**
```
castle_of_shadows_v1.0.0/
├── Game/
│   ├── CastleOfShadows.exe
│   ├── CastleOfShadows.pck
│   └── README.txt
├── Documentation/
│   ├── Manual.pdf
│   ├── Controls.png
│   └── Credits.txt
└── Extras/
    ├── Screenshots/
    ├── Soundtrack/
    └── Wallpapers/
```

**发布检查表：**
- [ ] 最终构建无编译错误
- [ ] 所有已知P0/P1 bug已修复
- [ ] 性能达到目标指标
- [ ] 本地化内容完整
- [ ] EULA和隐私政策
- [ ] 版本号和构建日期正确
- [ ] 数字签名（如适用）
- [ ] 反盗版措施（如适用）

### 交付物要求
- ✅ 通过所有QA测试的最终版本
- ✅ 完整的安装包和文档
- ✅ 宣传材料包（截图、视频、文案）
- ✅ 发布后支持计划

## 技术实现策略

### 版本控制工作流
```bash
# 推荐的工作流程
# 1. 从master创建功能分支
git checkout -b feature/player-combat

# 2. 开发功能，小步提交
git add scripts/PlayerCombat.gd
git commit -m "feat: 实现基础连击系统"

# 3. 保持同步
git fetch origin
git rebase origin/master

# 4. 完成功能，创建PR
git push origin feature/player-combat
# 在GitHub创建Pull Request

# 5. 代码审查后合并
git checkout master
git merge --no-ff feature/player-combat
git push origin master
```

### 分支策略
```
master          - 生产就绪代码
├── develop     - 集成测试分支
│   ├── feature/*     - 新功能开发
│   ├── bugfix/*      - bug修复
│   └── hotfix/*      - 紧急修复
└── release/*   - 发布准备分支
```

### 自动化测试
```gdscript
# test/unit/TestPlayerCombat.gd
extends GutTest

func test_basic_attack():
    var player = Player.new()
    player.setup()

    # 模拟攻击输入
    Input.action_press("attack")
    player._physics_process(0.1)
    Input.action_release("attack")

    # 验证攻击动画播放
    assert_true(player.animation_player.is_playing("attack"))

    # 验证攻击冷却
    assert_gt(player.attack_cooldown, 0)

func test_combo_system():
    var player = Player.new()
    player.setup_combo_system()

    # 快速连续攻击
    for i in range(3):
        simulate_attack_input()
        await wait_frames(5)  # 等待几帧

    # 验证连击计数
    assert_eq(player.combo_count, 3)
    assert_true(player.is_in_combo_state())
```

## 开发工具栈

### 必需工具
| 工具 | 用途 | 推荐版本 |
|------|------|----------|
| Godot Engine | 游戏开发引擎 | 4.3+ |
| Git | 版本控制 | 2.40+ |
| Python 3 | 自动化脚本 | 3.9+ |

### 美术工具
| 工具 | 用途 | 许可证 |
|------|------|--------|
| Aseprite | 像素艺术制作 | 付费/试用 |
| LibreSprite | 像素艺术制作 | 开源 |
| GIMP | 图像处理 | 开源 |
| Material Maker | 材质生成 | 开源 |

### 音频工具
| 工具 | 用途 | 许可证 |
|------|------|--------|
| Bosca Ceoil | 芯片音乐制作 | 免费 |
| BeepBox | 在线音乐编辑器 | 免费 |
| Bfxr | 音效生成器 | 免费 |
| Audacity | 音频编辑 | 开源 |

### 测试工具
| 工具 | 用途 |
|------|------|
| Godot Profiler | 性能分析 |
| GUT | 单元测试框架 |
| Playtest.co | 用户测试平台 |

## 成功指标与检查点

### 每周检查点
```
Week 1: 基础移动和攻击可运行
Week 2: 第一区域（城堡外围）框架完成
Week 3: 所有核心系统集成
Week 4: 实际美术资源替换占位符
Week 5: 完整游戏循环（开始到第一个Boss）
Week 6: 50%美术资源完成
Week 7: 所有区域可探索
Week 8: 音频内容完成
Week 9: 性能优化完成
Week 10: QA测试通过
Week 11: 发布版本准备就绪
```

### 质量指标
| 指标 | 目标值 | 测量方法 |
|------|--------|----------|
| 帧率 | 稳定60FPS（最低30FPS） | Godot Profiler |
| 加载时间 | 场景切换<3秒 | 手动计时 |
| Bug密度 | 每1000行代码<1个严重bug | Bug追踪系统 |
| 用户满意度 | Playtest评分>4/5 | 用户调查问卷 |
| 完成度 | 所有设计功能实现90%+ | 功能检查表 |

## 协作与沟通

### 开发团队角色
```
项目负责人
├── 技术负责人 (负责代码架构)
├── 美术负责人 (负责视觉资源)
├── 音频负责人 (负责声音内容)
└── QA负责人 (负责测试验证)
```

### 沟通规范
1. **每日站立会议**（15分钟）
   - 昨天完成了什么
   - 今天计划做什么
   - 遇到了什么阻碍

2. **每周评审会议**（60分钟）
   - 演示本周成果
   - 讨论设计决策
   - 调整下周计划

3. **代码审查流程**
   - 所有代码必须经过至少一人审查
   - 关注点：功能正确性、性能、可维护性
   - 使用GitHub Pull Request流程

### 文档维护
- 设计文档：`docs/` 目录
- API文档：代码中的GD文档注释
- 用户手册：`Manual.pdf`
- 开发日志：`CHANGELOG.md`

## 风险管理

### 已识别风险
| 风险 | 可能性 | 影响 | 缓解策略 |
|------|--------|------|----------|
| 美术资源延迟 | 中 | 高 | 使用占位符继续开发，外包部分工作 |
| 性能不达标 | 中 | 高 | 早期性能测试，预留优化时间 |
| 范围蔓延 | 高 | 中 | 严格的功能冻结，版本控制 |
| 团队人员变动 | 低 | 高 | 代码文档化，知识共享 |

### 应急计划
1. **时间超支**：优先实现核心功能，削减次要特性
2. **预算不足**：使用更多开源工具和资源
3. **技术障碍**：寻求社区帮助，调整设计方案
4. **质量不达标**：延长测试周期，分阶段发布

## 立即行动指南

### 第一天任务清单
1. **环境设置**
   ```bash
   # 克隆仓库（如从其他设备开始）
   git clone git@github.com:peterwangze/castle-of-shadows.git

   # 安装Godot 4.3+
   # 下载地址: https://godotengine.org/download

   # 安装Python依赖
   pip install pillow  # 用于占位符生成脚本
   ```

2. **项目验证**
   ```bash
   # 打开Godot，导入项目
   # 选择 project.godot 文件

   # 运行测试场景
   # 按F5或点击播放按钮
   ```

3. **创建占位符资源**
   ```bash
   # 运行占位符生成脚本
   python scripts/create_placeholders.py

   # 验证资源创建
   ls -la assets/art/characters/player/
   ls -la assets/art/enemies/skeleton/
   ```

4. **首次提交**
   ```bash
   # 添加新资源
   git add assets/art/
   git commit -m "feat: 添加占位符资源"

   # 推送到远程
   git push origin master
   ```

### 开发节奏建议
- **每日目标**：完成1-2个小功能或修复
- **每周目标**：完成一个里程碑功能
- **每月目标**：完成一个开发阶段

### 获取帮助
- **Godot文档**：https://docs.godotengine.org/
- **GitHub Issues**：报告bug和请求功能
- **Discord社区**：寻求技术帮助
- **项目Wiki**：查看详细开发说明

---

**开发原则提醒**：
1. 保持项目始终可运行
2. 优先实现核心玩法
3. 频繁测试，及早发现bug
4. 文档化所有重要决策
5. 庆祝每一个小胜利

祝开发顺利！ 🎮✨