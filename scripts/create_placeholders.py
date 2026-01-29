#!/usr/bin/env python3
"""
Castle of Shadows 占位符资源生成脚本
创建开发初期所需的基础占位符图像
"""

import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw

# 颜色定义
COLORS = {
    "player_green": (0, 255, 0, 255),        # 玩家 - 绿色
    "enemy_red": (255, 0, 0, 255),          # 敌人 - 红色
    "floor_gray": (128, 128, 128, 255),     # 地板 - 灰色
    "wall_dark_gray": (64, 64, 64, 255),    # 墙壁 - 深灰
    "spike_red": (255, 0, 0, 255),         # 尖刺 - 红色
    "platform_brown": (139, 69, 19, 255),   # 平台 - 棕色
    "water_blue": (0, 120, 255, 180),      # 水 - 蓝色半透明
    "lava_orange": (255, 100, 0, 200),     # 岩浆 - 橙色
    "checkpoint_yellow": (255, 255, 0, 255), # 检查点 - 黄色
    "item_purple": (180, 0, 255, 255),     # 物品 - 紫色
}

def create_directory_structure():
    """创建资源目录结构"""
    directories = [
        "assets/art/characters/player",
        "assets/art/enemies/skeleton",
        "assets/art/enemies/ghost",
        "assets/art/enemies/bat",
        "assets/art/enemies/gargoyle",
        "assets/art/tilesets/basic",
        "assets/art/ui/hud",
        "assets/art/ui/menu",
        "assets/art/effects/combat",
        "assets/art/props",
    ]

    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        print(f"[OK] 创建目录: {directory}")

def create_player_placeholder():
    """创建玩家角色占位符"""
    print("创建玩家角色占位符...")

    # 站立姿势 (32×48)
    img = Image.new('RGBA', (32, 48), COLORS["player_green"])
    draw = ImageDraw.Draw(img)

    # 添加简单轮廓
    draw.rectangle([4, 4, 28, 44], outline=(255, 255, 255, 255), width=2)

    # 头部区域
    draw.ellipse([12, 8, 20, 16], fill=(200, 200, 200, 255))

    # 武器（剑）
    draw.line([24, 24, 30, 24], fill=(200, 200, 200, 255), width=2)
    draw.line([30, 20, 30, 28], fill=(200, 200, 200, 255), width=2)

    img.save("assets/art/characters/player/idle_01.png")

    # 创建多个方向的占位符
    for direction in ["left", "right"]:
        img_direction = img.copy()
        img_direction.save(f"assets/art/characters/player/idle_{direction}_01.png")

    print("[OK] 玩家占位符创建完成")

def create_enemy_placeholders():
    """创建各种敌人占位符"""
    print("创建敌人占位符...")

    # 骷髅士兵 (24×32)
    skeleton_img = Image.new('RGBA', (24, 32), COLORS["enemy_red"])
    skeleton_draw = ImageDraw.Draw(skeleton_img)
    skeleton_draw.ellipse([4, 4, 20, 12], fill=(220, 220, 220, 255))  # 头骨
    skeleton_draw.rectangle([8, 12, 16, 28], fill=(220, 220, 220, 255))  # 身体
    skeleton_img.save("assets/art/enemies/skeleton/idle_01.png")
    print("[OK] 骷髅士兵占位符")

    # 怨灵 (32×32，半透明)
    ghost_img = Image.new('RGBA', (32, 32), (0, 0, 255, 150))
    ghost_draw = ImageDraw.Draw(ghost_img)
    ghost_draw.ellipse([8, 8, 24, 24], outline=(255, 255, 255, 200), width=2)
    ghost_draw.ellipse([12, 12, 20, 20], fill=(200, 200, 255, 100))
    ghost_img.save("assets/art/enemies/ghost/idle_01.png")
    print("[OK] 怨灵占位符")

    # 血蝠 (16×16)
    bat_img = Image.new('RGBA', (16, 16), COLORS["enemy_red"])
    bat_draw = ImageDraw.Draw(bat_img)
    bat_draw.ellipse([4, 4, 12, 12], fill=(200, 0, 0, 255))
    bat_draw.line([4, 8, 0, 4], fill=(150, 0, 0, 255), width=2)  # 左翼
    bat_draw.line([12, 8, 16, 4], fill=(150, 0, 0, 255), width=2) # 右翼
    bat_img.save("assets/art/enemies/bat/idle_01.png")
    print("[OK] 血蝠占位符")

    # 石像鬼 (32×48)
    gargoyle_img = Image.new('RGBA', (32, 48), COLORS["wall_dark_gray"])
    gargoyle_draw = ImageDraw.Draw(gargoyle_img)
    gargoyle_draw.rectangle([8, 8, 24, 40], fill=(100, 100, 100, 255))
    gargoyle_draw.ellipse([12, 12, 20, 20], fill=(255, 0, 0, 255))  # 眼睛
    gargoyle_img.save("assets/art/enemies/gargoyle/idle_01.png")
    print("[OK] 石像鬼占位符")

def create_tile_placeholders():
    """创建瓦片占位符"""
    print("创建瓦片占位符...")

    tiles = [
        ("floor", COLORS["floor_gray"], "基本地板"),
        ("wall", COLORS["wall_dark_gray"], "墙壁"),
        ("spike", COLORS["spike_red"], "尖刺陷阱"),
        ("platform", COLORS["platform_brown"], "平台"),
        ("water", COLORS["water_blue"], "水"),
        ("lava", COLORS["lava_orange"], "岩浆"),
    ]

    for name, color, description in tiles:
        img = Image.new('RGBA', (16, 16), color)
        draw = ImageDraw.Draw(img)

        # 添加纹理效果
        if name == "floor":
            for i in range(4):
                x = i * 4
                draw.line([x, 0, x, 16], fill=(color[0]-20, color[1]-20, color[2]-20, 255), width=1)
        elif name == "wall":
            draw.rectangle([2, 2, 14, 14], outline=(color[0]-30, color[1]-30, color[2]-30, 255), width=1)
        elif name == "spike":
            draw.polygon([(8, 2), (2, 14), (14, 14)], fill=(200, 0, 0, 255))
        elif name == "platform":
            draw.rectangle([0, 12, 16, 16], fill=(color[0]-40, color[1]-40, color[2]-40, 255))

        img.save(f"assets/art/tilesets/basic/{name}.png")
        print(f"[OK] {description}瓦片")

    # 创建检查点瓦片
    checkpoint_img = Image.new('RGBA', (16, 16), COLORS["checkpoint_yellow"])
    checkpoint_draw = ImageDraw.Draw(checkpoint_img)
    checkpoint_draw.ellipse([4, 4, 12, 12], fill=(255, 200, 0, 255))
    checkpoint_img.save("assets/art/tilesets/basic/checkpoint.png")
    print("[OK] 检查点瓦片")

def create_ui_placeholders():
    """创建UI占位符"""
    print("创建UI占位符...")

    # 生命值心形
    heart_img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    heart_draw = ImageDraw.Draw(heart_img)
    heart_draw.ellipse([2, 4, 8, 10], fill=(255, 50, 50, 255))
    heart_draw.ellipse([8, 4, 14, 10], fill=(255, 50, 50, 255))
    heart_draw.polygon([(2, 6), (14, 6), (8, 14)], fill=(255, 50, 50, 255))
    heart_img.save("assets/art/ui/hud/heart.png")
    print("[OK] 生命值图标")

    # 能量条片段
    energy_img = Image.new('RGBA', (16, 8), (50, 150, 255, 255))
    energy_draw = ImageDraw.Draw(energy_img)
    energy_draw.rectangle([0, 0, 16, 8], outline=(30, 100, 200, 255), width=1)
    energy_img.save("assets/art/ui/hud/energy_segment.png")
    print("[OK] 能量条片段")

    # 按钮
    button_img = Image.new('RGBA', (64, 32), (80, 80, 80, 255))
    button_draw = ImageDraw.Draw(button_img)
    button_draw.rectangle([2, 2, 62, 30], outline=(120, 120, 120, 255), width=2)
    button_draw.rectangle([0, 0, 64, 32], outline=(40, 40, 40, 255), width=2)
    button_img.save("assets/art/ui/menu/button.png")
    print("[OK] 按钮UI")

def create_effect_placeholders():
    """创建特效占位符"""
    print("创建特效占位符...")

    # 攻击特效
    attack_img = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
    attack_draw = ImageDraw.Draw(attack_img)
    attack_draw.arc([2, 2, 22, 22], 45, 135, fill=(255, 255, 100, 200), width=4)
    attack_img.save("assets/art/effects/combat/attack_arc.png")
    print("[OK] 攻击特效")

    # 伤害数字背景
    damage_img = Image.new('RGBA', (24, 16), (0, 0, 0, 150))
    damage_draw = ImageDraw.Draw(damage_img)
    damage_draw.rectangle([0, 0, 24, 16], outline=(255, 255, 255, 200), width=1)
    damage_img.save("assets/art/effects/combat/damage_bg.png")
    print("[OK] 伤害数字背景")

    # 物品发光特效
    glow_img = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)
    for i in range(3):
        radius = 12 - i * 4
        alpha = 100 - i * 30
        glow_draw.ellipse([12-radius, 12-radius, 12+radius, 12+radius],
                         outline=(255, 255, 100, alpha), width=2)
    glow_img.save("assets/art/effects/combat/glow.png")
    print("[OK] 物品发光特效")

def create_prop_placeholders():
    """创建道具占位符"""
    print("创建道具占位符...")

    # 金币
    coin_img = Image.new('RGBA', (12, 12), (255, 215, 0, 255))
    coin_draw = ImageDraw.Draw(coin_img)
    coin_draw.ellipse([2, 2, 10, 10], fill=(255, 200, 0, 255))
    coin_draw.ellipse([4, 4, 8, 8], fill=(255, 180, 0, 255))
    coin_img.save("assets/art/props/coin.png")
    print("[OK] 金币道具")

    # 生命药水
    potion_img = Image.new('RGBA', (12, 16), (255, 50, 50, 255))
    potion_draw = ImageDraw.Draw(potion_img)
    potion_draw.ellipse([2, 2, 10, 6], fill=(200, 30, 30, 255))  # 瓶口
    potion_draw.rectangle([3, 6, 9, 14], fill=(220, 40, 40, 255))  # 瓶身
    potion_img.save("assets/art/props/health_potion.png")
    print("[OK] 生命药水")

    # 能量药水
    energy_potion_img = Image.new('RGBA', (12, 16), (50, 150, 255, 255))
    energy_potion_draw = ImageDraw.Draw(energy_potion_img)
    energy_potion_draw.ellipse([2, 2, 10, 6], fill=(30, 120, 220, 255))
    energy_potion_draw.rectangle([3, 6, 9, 14], fill=(40, 130, 230, 255))
    energy_potion_img.save("assets/art/props/energy_potion.png")
    print("[OK] 能量药水")

def create_placeholder_manifest():
    """创建占位符清单文件"""
    manifest_content = """# Castle of Shadows 占位符资源清单
# 生成时间: 2026-01-29
# 这些是开发初期使用的占位符资源，将在后续阶段替换为实际美术资源

## 目录结构
assets/art/
├── characters/player/          # 玩家角色
│   ├── idle_01.png            # 站立姿势
│   ├── idle_left_01.png       # 向左站立
│   └── idle_right_01.png      # 向右站立
├── enemies/                    # 敌人
│   ├── skeleton/idle_01.png   # 骷髅士兵
│   ├── ghost/idle_01.png      # 怨灵
│   ├── bat/idle_01.png        # 血蝠
│   └── gargoyle/idle_01.png   # 石像鬼
├── tilesets/basic/            # 基础瓦片集
│   ├── floor.png              # 地板
│   ├── wall.png               # 墙壁
│   ├── spike.png              # 尖刺
│   ├── platform.png           # 平台
│   ├── water.png              # 水
│   ├── lava.png               # 岩浆
│   └── checkpoint.png         # 检查点
├── ui/                        # 用户界面
│   ├── hud/heart.png          # 生命值图标
│   ├── hud/energy_segment.png # 能量条片段
│   └── menu/button.png        # 按钮
├── effects/combat/            # 战斗特效
│   ├── attack_arc.png         # 攻击弧光
│   ├── damage_bg.png          # 伤害数字背景
│   └── glow.png               # 发光特效
└── props/                     # 道具
    ├── coin.png               # 金币
    ├── health_potion.png      # 生命药水
    └── energy_potion.png      # 能量药水

## 颜色说明
- 玩家: 绿色 (#00FF00)
- 敌人: 红色 (#FF0000)
- 地板: 灰色 (#808080)
- 墙壁: 深灰 (#404040)
- 陷阱: 亮红 (#FF0000)
- 可交互: 紫色 (#B400FF)
- 检查点: 黄色 (#FFFF00)

## 使用说明
这些占位符资源用于开发初期的功能验证和原型测试。
在后续开发阶段将逐步替换为高质量的美术资源。

## 更新计划
- 第一阶段 (1-2周): 使用占位符验证核心机制
- 第二阶段 (3-5周): 替换部分关键资源
- 第三阶段 (6-9周): 替换所有占位符资源
"""

    with open("assets/art/PLACEHOLDER_MANIFEST.md", "w", encoding="utf-8") as f:
        f.write(manifest_content)
    print("[OK] 创建占位符清单文档")

def main():
    """主函数"""
    print("=" * 60)
    print("Castle of Shadows - 占位符资源生成工具")
    print("=" * 60)

    try:
        # 检查PIL是否安装
        from PIL import Image, ImageDraw
    except ImportError:
        print("错误: 需要安装PIL (Pillow) 库")
        print("请运行: pip install pillow")
        sys.exit(1)

    # 创建目录结构
    create_directory_structure()
    print("-" * 40)

    # 创建各种占位符资源
    create_player_placeholder()
    print("-" * 20)

    create_enemy_placeholders()
    print("-" * 20)

    create_tile_placeholders()
    print("-" * 20)

    create_ui_placeholders()
    print("-" * 20)

    create_effect_placeholders()
    print("-" * 20)

    create_prop_placeholders()
    print("-" * 20)

    # 创建清单文档
    create_placeholder_manifest()
    print("-" * 40)

    print("\n[DONE] 占位符资源生成完成!")
    print(f"总计创建资源文件: 约20个")
    print(f"资源目录: assets/art/")
    print("\n下一步:")
    print("1. 将资源添加到Git: git add assets/art/")
    print("2. 提交更改: git commit -m '添加占位符资源'")
    print("3. 在Godot中导入资源并测试")
    print("=" * 60)

if __name__ == "__main__":
    main()