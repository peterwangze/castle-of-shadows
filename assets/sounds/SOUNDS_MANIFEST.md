# 音效资源清单
# 本文档列出游戏所需的所有音效和音乐

## 玩家音效 (assets/sounds/player/)

| 文件名 | 描述 | 时长 | 优先级 |
|--------|------|------|--------|
| jump.wav | 跳跃 | 0.2s | P0 |
| attack.wav | 攻击挥舞 | 0.3s | P0 |
| hurt.wav | 受伤 | 0.3s | P0 |
| land.wav | 落地 | 0.2s | P1 |
| dash.wav | 冲刺 | 0.3s | P1 |
| heal.wav | 治疗 | 0.5s | P1 |
| level_up.wav | 升级 | 1.0s | P1 |
| die.wav | 死亡 | 0.8s | P0 |

## 敌人音效 (assets/sounds/enemies/)

| 文件名 | 描述 | 时长 | 优先级 |
|--------|------|------|--------|
| hit.wav | 敌人受击 | 0.2s | P0 |
| die.wav | 敌人死亡 | 0.4s | P0 |
| alert.wav | 警觉 | 0.3s | P1 |
| skeleton_attack.wav | 骷髅攻击 | 0.3s | P2 |
| ghost_appear.wav | 幽灵出现 | 0.5s | P2 |
| bat_screech.wav | 蝙蝠尖叫 | 0.3s | P2 |

## UI音效 (assets/sounds/ui/)

| 文件名 | 描述 | 时长 | 优先级 |
|--------|------|------|--------|
| coin.wav | 收集金币 | 0.2s | P0 |
| pause.wav | 暂停 | 0.3s | P0 |
| select.wav | 选择 | 0.15s | P0 |
| confirm.wav | 确认 | 0.2s | P0 |
| cancel.wav | 取消 | 0.2s | P1 |
| save.wav | 保存 | 0.4s | P1 |
| load.wav | 加载 | 0.4s | P1 |

## 环境音效 (assets/sounds/environment/)

| 文件名 | 描述 | 时长 | 优先级 |
|--------|------|------|--------|
| checkpoint.wav | 检查点激活 | 0.5s | P1 |
| door_open.wav | 门打开 | 0.4s | P2 |
| secret.wav | 发现秘密 | 0.6s | P2 |

## 背景音乐 (assets/music/)

| 文件名 | 描述 | 时长 | 优先级 |
|--------|------|------|--------|
| bgm_menu.ogg | 主菜单音乐 | 2:00 | P0 |
| bgm_castle_exterior.ogg | 城堡外围 | 3:00 | P0 |
| bgm_main_hall.ogg | 主大厅 | 3:00 | P1 |
| bgm_catacombs.ogg | 地下墓穴 | 3:00 | P1 |
| bgm_banquet_hall.ogg | 宴会厅 | 3:00 | P2 |
| bgm_clock_tower.ogg | 钟楼 | 3:00 | P2 |
| bgm_throne_room.ogg | 王座室 | 3:00 | P2 |
| bgm_boss.ogg | Boss战 | 4:00 | P0 |
| bgm_victory.ogg | 胜利 | 1:30 | P1 |
| bgm_game_over.ogg | 失败 | 0:30 | P1 |

## 音效制作规格

### 格式要求
- 音效：WAV 格式，16-bit，44100Hz
- 音乐：OGG 格式，VBR 质量5

### 音量标准
- 玩家音效：-6dB
- 敌人音效：-8dB
- UI音效：-4dB
- 环境音效：-12dB
- 背景音乐：-10dB

### 风格指南
- 整体风格：像素风8-bit/16-bit 复古风
- 参考游戏：恶魔城、魂斗罗、忍者龙剑传
- 禁止使用版权素材

## 当前进度

- [ ] P0 音效（15个）
- [ ] P1 音效（10个）
- [ ] P2 音效（8个）
- [ ] 背景音乐（3首P0）
