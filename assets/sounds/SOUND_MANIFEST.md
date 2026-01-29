# 音效占位符清单

## 目录结构
```
assets/sounds/
├── player/           # 玩家音效
│   ├── jump.wav     # 跳跃音效
│   ├── attack.wav   # 攻击音效
│   ├── hurt.wav     # 受伤音效
│   └── dash.wav     # 冲刺音效
├── enemies/         # 敌人音效
│   ├── hit.wav      # 击中敌人
│   ├── death.wav    # 敌人死亡
│   └── alert.wav    # 敌人发现玩家
├── ui/              # 界面音效
│   ├── select.wav   # 选择音效
│   ├── confirm.wav  # 确认音效
│   └── cancel.wav   # 取消音效
└── environment/     # 环境音效
    ├── checkpoint.wav # 检查点激活
    └── collect.wav    # 收集物品
```

## 创建占位符音效的方法

### 1. 使用Bfxr（推荐）
Bfxr是一个免费的芯片音效生成器，可以快速创建8-bit风格音效。

下载地址：https://www.bfxr.net/

基本命令：
```bash
# 生成跳跃音效
bfxr --type jump --o assets/sounds/player/jump.wav

# 生成攻击音效
bfxr --type shoot --o assets/sounds/player/attack.wav

# 生成受伤音效
bfxr --type hurt --o assets/sounds/player/hurt.wav
```

### 2. 使用Audacity录制
1. 打开Audacity
2. 生成 → 音调（440Hz，0.1秒）
3. 效果 → 改变音调/回音/混响
4. 文件 → 导出为WAV

### 3. 使用在线工具
- https://jfxr.frozenfractal.com/ - 在线音效生成器
- https://sfxr.me/ - 另一个在线工具

## 音效规格要求
- 格式：WAV或OGG
- 采样率：44100 Hz
- 位深度：16-bit
- 文件大小：尽可能小（<100KB每个）

## 开发阶段使用
在开发初期，可以使用简单的占位符音效：
1. 用Bfxr生成基础音效
2. 确保每个动作都有对应的音效反馈
3. 音效应简短（0.1-0.5秒）
4. 避免音量过大或刺耳的音效

## 实际音效制作计划
- 第一阶段：基础占位符音效（Bfxr生成）
- 第二阶段：改进音效质量
- 第三阶段：专业音效设计