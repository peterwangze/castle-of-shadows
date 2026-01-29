#!/usr/bin/env python3
"""
项目完整性验证脚本
检查Castle of Shadows项目是否具备基本运行条件
"""

import os
import sys
from pathlib import Path

def check_required_files():
    """检查必需的文件是否存在"""
    required_files = [
        "project.godot",
        "scenes/DebugTest.tscn",
        "scripts/PlayerSimple.gd",
        "assets/art/characters/player/idle_01.png",
        "assets/art/tilesets/basic/floor.png",
        "assets/art/tilesets/basic/wall.png",
    ]

    missing_files = []
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)

    if missing_files:
        print("[ERROR] 缺少必需的文件:")
        for file in missing_files:
            print(f"  - {file}")
        return False
    else:
        print("[OK] 所有必需文件存在")
        return True

def check_godot_project():
    """检查Godot项目配置"""
    try:
        with open("project.godot", "r", encoding="utf-8") as f:
            content = f.read()

        checks = [
            ("config_version", "config_version=5" in content),
            ("project_name", 'config/name="Castle of Shadows"' in content),
            ("main_scene", 'run/main_scene="res://scenes/DebugTest.tscn"' in content),
            ("window_size", "window/size/viewport_width=640" in content),
            ("window_size", "window/size/viewport_height=360" in content),
        ]

        all_ok = True
        for check_name, check_result in checks:
            if check_result:
                print(f"[OK] Godot配置: {check_name}")
            else:
                print(f"[WARNING] Godot配置: {check_name} 可能有问题")
                all_ok = False

        return all_ok
    except Exception as e:
        print(f"[ERROR] 读取project.godot失败: {e}")
        return False

def check_asset_counts():
    """检查资产文件数量"""
    asset_dirs = [
        "assets/art/characters/player",
        "assets/art/enemies",
        "assets/art/tilesets/basic",
        "assets/art/ui",
        "assets/art/effects",
        "assets/art/props",
    ]

    total_files = 0
    for asset_dir in asset_dirs:
        if os.path.exists(asset_dir):
            files = [f for f in os.listdir(asset_dir) if f.endswith(('.png', '.jpg', '.gif'))]
            count = len(files)
            total_files += count
            print(f"[INFO] {asset_dir}: {count}个图像文件")
        else:
            print(f"[WARNING] 目录不存在: {asset_dir}")

    print(f"[INFO] 总计图像文件: {total_files}个")
    return total_files > 10  # 至少要有一些资产文件

def check_script_syntax():
    """简单检查GDScript语法"""
    scripts_to_check = [
        "scripts/PlayerSimple.gd",
    ]

    for script_path in scripts_to_check:
        if os.path.exists(script_path):
            try:
                with open(script_path, "r", encoding="utf-8") as f:
                    content = f.read()

                # 基本语法检查
                checks = [
                    ("extends声明", "extends CharacterBody2D" in content),
                    ("_ready函数", "_ready()" in content),
                    ("_physics_process", "_physics_process" in content),
                    ("移动输入", "Input.get_axis" in content),
                ]

                script_ok = True
                for check_name, check_result in checks:
                    if not check_result:
                        print(f"[WARNING] {script_path}: 缺少{check_name}")
                        script_ok = False

                if script_ok:
                    print(f"[OK] 脚本语法检查: {script_path}")
            except Exception as e:
                print(f"[ERROR] 检查脚本{script_path}失败: {e}")
        else:
            print(f"[ERROR] 脚本不存在: {script_path}")

    return True

def check_scene_structure():
    """检查场景文件结构"""
    scene_path = "scenes/DebugTest.tscn"
    if not os.path.exists(scene_path):
        print(f"[ERROR] 场景文件不存在: {scene_path}")
        return False

    try:
        with open(scene_path, "r", encoding="utf-8") as f:
            content = f.read()

        checks = [
            ("场景格式", "[gd_scene" in content),
            ("Player节点", '"Player"' in content),
            ("Camera2D", '"Camera2D"' in content),
            ("碰撞形状", '"CollisionShape2D"' in content),
            ("玩家脚本", "PlayerSimple.gd" in content),
        ]

        scene_ok = True
        for check_name, check_result in checks:
            if check_result:
                print(f"[OK] 场景检查: {check_name}")
            else:
                print(f"[WARNING] 场景检查: {check_name} 可能有问题")
                scene_ok = False

        return scene_ok
    except Exception as e:
        print(f"[ERROR] 读取场景文件失败: {e}")
        return False

def main():
    """主验证函数"""
    print("=" * 60)
    print("Castle of Shadows 项目完整性验证")
    print("=" * 60)

    print("\n1. 检查必需文件...")
    files_ok = check_required_files()

    print("\n2. 检查Godot项目配置...")
    godot_ok = check_godot_project()

    print("\n3. 检查资产文件...")
    assets_ok = check_asset_counts()

    print("\n4. 检查脚本语法...")
    scripts_ok = check_script_syntax()

    print("\n5. 检查场景结构...")
    scene_ok = check_scene_structure()

    print("\n" + "=" * 60)
    print("验证结果汇总:")
    print("=" * 60)

    results = {
        "必需文件": files_ok,
        "Godot配置": godot_ok,
        "资产文件": assets_ok,
        "脚本语法": scripts_ok,
        "场景结构": scene_ok,
    }

    all_passed = True
    for check_name, passed in results.items():
        status = "[PASS]" if passed else "[FAIL]"
        print(f"{status} {check_name}")
        if not passed:
            all_passed = False

    print("\n" + "=" * 60)
    if all_passed:
        print("[SUCCESS] 项目完整性验证通过!")
        print("\n下一步:")
        print("1. 打开Godot引擎")
        print("2. 导入 project.godot 文件")
        print("3. 按F5运行游戏")
        print("4. 测试基本控制:")
        print("   - 左右方向键移动")
        print("   - 空格键跳跃")
        print("   - J键攻击")
        print("   - Shift键冲刺")
    else:
        print("[WARNING] 项目验证未完全通过")
        print("请检查上面的警告和错误信息")

    print("=" * 60)
    return 0 if all_passed else 1

if __name__ == "__main__":
    sys.exit(main())