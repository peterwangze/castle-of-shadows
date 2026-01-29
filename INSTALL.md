# Castle of Shadows - 安装与运行指南

## 系统要求
- **操作系统**：Windows 10/11, macOS 10.14+, Linux (Ubuntu 20.04+)
- **处理器**：双核 2.0 GHz 或更高
- **内存**：4 GB RAM
- **显卡**：支持 OpenGL 3.3
- **存储空间**：500 MB 可用空间

## 第一步：安装 Godot 引擎

### Windows
1. 访问 [Godot 官方网站](https://godotengine.org/)
2. 下载 **Godot 4.3+** 标准版（64位）
3. 解压 ZIP 文件到任意目录（如 `C:\Godot\`）
4. 运行 `godot.exe`（无需安装）

### macOS
1. 下载 Godot 4.3+ macOS 版本
2. 解压 ZIP 文件
3. 将 Godot 应用程序拖到 `应用程序` 文件夹
4. 首次运行时在 Finder 中右键点击 → "打开"

### Linux
```bash
# 下载并解压
wget https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
unzip Godot_v4.3-stable_linux.x86_64.zip
chmod +x Godot_v4.3-stable_linux.x86_64
./Godot_v4.3-stable_linux.x86_64
```

## 第二步：设置项目

### 方法A：导入现有项目
1. 启动 Godot 引擎
2. 点击右上角 "导入" 按钮
3. 选择本项目的 `project.godot` 文件
4. 点击 "打开" 加载项目

### 方法B：新建项目并复制文件
1. 启动 Godot → "新建项目"
2. 项目名称：`CastleOfShadows`
3. 项目路径：选择新文件夹
4. 渲染器：**Forward+**（推荐）
5. 创建项目后，将本项目的所有文件复制到项目文件夹中

## 第三步：安装开发工具（可选）

### 像素艺术工具
- **Aseprite**（付费，推荐）：专业像素艺术编辑器
- **LibreSprite**（免费，开源）：Aseprite 的开源分支
- **Piskel**（免费，在线）：简单像素艺术编辑器

### 音频工具
- **Bosca Ceoil**（免费）：芯片音乐创作工具
- **BeepBox**（免费，在线）：在线芯片音乐编辑器
- **LMMS**（免费）：完整数字音频工作站

### 版本控制
```bash
# 初始化 Git 仓库
git init
git add .
git commit -m "初始提交：Castle of Shadows 项目"
```

## 第四步：运行游戏

### 在 Godot 编辑器中运行
1. 确保 `scenes/Main.tscn` 是主场景
   - 如果没有，右键点击任意场景 → "设为主场景"
2. 点击编辑器顶部的播放按钮 ▶️ 或按 **F5**
3. 游戏将在新窗口中启动

### 常见问题解决

#### 问题：缺少主场景
```
错误：主场景未设置
```
**解决方案**：
1. 打开 `项目设置` → `应用程序` → `运行`
2. 在 `主场景` 字段选择 `res://scenes/Main.tscn`

#### 问题：脚本编译错误
```
GDScript 编译错误
```
**解决方案**：
1. 检查 Godot 版本是否为 4.3+
2. 打开脚本编辑器查看具体错误
3. 确保所有脚本文件编码为 UTF-8

#### 问题：资源丢失
```
错误：无法加载资源
```
**解决方案**：
1. 检查 `assets/` 目录下是否有对应文件
2. 使用占位符资源临时替代：
   ```bash
   # 创建占位符图像
   convert -size 32x48 xc:#4a4a4a placeholder_player.png
   ```

## 第五步：创建占位符资源

由于完整的艺术资源需要时间创作，可以使用以下占位符：

### 玩家角色
1. 创建 32×48 像素的矩形，颜色 `#4a4a4a`
2. 保存为 `assets/art/characters/player/idle_01.png`

### 敌人
1. 骷髅：24×32 像素，白色矩形
2. 幽灵：32×32 像素，半透明蓝色圆形
3. 蝙蝠：16×16 像素，红色菱形

### 瓦片集
1. 创建 16×16 像素的基础瓦片：
   - 石砖：灰色 `#787878`
   - 木板：棕色 `#8B4513`
   - 泥土：深棕色 `#654321`
   - 尖刺：红色 `#FF0000`

### 使用脚本快速生成占位符
```python
# generate_placeholders.py
from PIL import Image, ImageDraw
import os

# 创建目录
os.makedirs("assets/art/characters/player", exist_ok=True)

# 生成玩家占位符
img = Image.new('RGBA', (32, 48), (74, 74, 74, 255))
img.save("assets/art/characters/player/idle_01.png")
```

## 第六步：项目结构验证

运行以下命令检查项目完整性：

```bash
# 检查关键文件
ls -la project.godot
ls -la scripts/Player.gd
ls -la scripts/Game.gd
ls -la scenes/

# 验证 Godot 项目
godot --headless --check-only
```

预期输出：
```
项目验证通过：Castle of Shadows
```

## 第七步：构建与导出

### 开发构建
1. 打开 `项目设置` → `导出`
2. 点击 "添加..." → 选择目标平台
3. 配置导出设置：
   - Windows: `CastleOfShadows.exe`
   - Web: `index.html` + `.pck` 文件
4. 点击 "导出项目"

### 发布构建
1. 确保所有资源已优化
2. 移除调试代码和占位符资源
3. 测试所有功能
4. 创建最终构建

## 快速测试

要快速测试游戏逻辑，可以使用以下测试场景：

1. 创建新场景 `TestLevel.tscn`
2. 添加以下节点：
   - `TileMap`（基础地面）
   - `Player`（实例化 Player.tscn）
   - `Camera2D`（跟随玩家）
3. 运行测试场景

## 后续开发

### 添加实际资源
1. **像素艺术**：使用 Aseprite 创建精灵和动画
2. **音乐音效**：使用 Bosca Ceoil 创作 8-bit 音乐
3. **关卡设计**：使用 Godot 的 TileMap 编辑器

### 扩展功能
1. **保存系统**：完善 Game.gd 中的保存/加载
2. **敌人AI**：扩展 EnemyBase.gd 的行为树
3. **UI/UX**：创建完整的用户界面

### 性能优化
1. **图集打包**：将小图像合并为大图集
2. **场景流式加载**：大型关卡分块加载
3. **内存管理**：及时释放未使用资源

## 获取帮助

### 文档资源
- [Godot 官方文档](https://docs.godotengine.org/)
- [GDScript 参考](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
- [像素艺术教程](https://www.aseprite.org/docs/)

### 社区支持
- [Godot 官方论坛](https://forum.godotengine.org/)
- [Reddit r/godot](https://www.reddit.com/r/godot/)
- [Discord Godot 社区](https://discord.gg/4JBkykG)

### 项目维护
- 定期备份项目
- 使用版本控制（Git）
- 编写测试用例
- 记录开发日志

---

**现在可以开始开发你的像素风恶魔城游戏了！**

遇到问题时，请参考设计文档：
- `docs/world_story.md` - 世界观和剧情
- `docs/character_design.md` - 角色设计
- `docs/level_design.md` - 关卡设计
- `docs/art_specification.md` - 美术规范
- `docs/music_design.md` - 音乐设计