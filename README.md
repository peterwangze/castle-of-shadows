# Castle of Shadows - 像素风横版动作过关游戏

![游戏标志](assets/art/logo.png)

## 项目概述
一个类似《恶魔城》系列的2D像素风格横版动作过关游戏，强调探索、战斗和角色成长，采用黑暗哥特式幻想风格。

## 游戏特点
- **像素艺术风格**：经典的16-bit像素美术
- **类恶魔城玩法**：探索巨大城堡，解锁新能力，击败Boss
- **深度战斗系统**：主武器、副武器、特殊技能组合
- **角色成长**：通过击败敌人获取经验，升级技能
- **沉浸式叙事**：黑暗幻想世界观和丰富故事线

## 开发环境
- **游戏引擎**：Godot 4.3+
- **编程语言**：GDScript
- **美术工具**：Aseprite / LibreSprite（像素艺术）
- **音乐工具**：Bosca Ceoil / BeepBox（8-bit音乐）
- **平台**：Windows（可扩展到Web、Linux、macOS）

## 项目结构
```
├── project.godot          # Godot项目配置文件
├── scenes/               # 游戏场景文件
├── scripts/              # GDScript脚本文件
├── assets/               # 游戏资源
│   ├── art/              # 像素艺术资源
│   ├── music/            # 背景音乐
│   ├── sounds/           # 音效文件
│   └── fonts/            # 像素字体
├── levels/               # 关卡设计文件
├── ui/                   # 用户界面资源
└── README.md             # 项目说明
```

## 快速开始
1. **安装Godot引擎**：
   - 从 [godotengine.org](https://godotengine.org/) 下载Godot 4.3+
   - 解压到任意目录，无需安装

2. **打开项目**：
   - 启动Godot引擎
   - 点击"导入"，选择本项目文件夹
   - 点击"打开"加载项目

3. **运行游戏**：
   - 在编辑器中按F5或点击播放按钮
   - 游戏将从主场景开始运行

## 控制说明
- **左右方向键/A/D**：移动
- **上方向键/W/空格**：跳跃
- **J/鼠标左键**：攻击
- **K/鼠标右键**：副武器
- **Shift**：冲刺
- **ESC**：暂停/菜单

## 开发计划
### 已完成
- [x] 项目结构创建
- [x] 基础配置文件
- [x] 输入控制设置

### 进行中
- [ ] 游戏文案设计
- [ ] 像素艺术资源创作
- [ ] 核心游戏逻辑实现
- [ ] 关卡设计
- [ ] 音效和音乐创作

## 游戏设计文档
详见 `docs/` 目录（待创建）：
- 世界观和故事设定
- 角色设计文档
- 关卡设计图
- 敌人AI行为规范
- 战斗系统说明

## 贡献指南
1. Fork本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

## 许可证
本项目采用MIT许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系方式
- 项目维护者：AI Assistant
- 创建日期：2026年1月29日