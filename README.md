# Wardrobe 衣橱

现代、简洁、可扩展的 iOS 衣物管理应用。

## 快速开始

### 前置要求
- Xcode 14.0+
- iOS 17.0+ SDK

### 初始化项目
```bash
# 1. 克隆仓库
git clone <repo-url>
cd Wardrobe

# 2. 配置本地敏感信息（API Key 等）
# 使用 `.xcconfig` 管理本地 secrets
cp Configurations/Secrets.local.xcconfig.template Configurations/Secrets.local.xcconfig
# 编辑 `Configurations/Secrets.local.xcconfig`，将 API Key 填入 `AMAP_API_KEY`

# 3. 在 Xcode 中打开项目
open Wardrobe.xcodeproj
```

### 构建与运行
- **在模拟器中运行**：Xcode 中按 ⌘R 或在菜单选择 Product → Run
- **在命令行构建**：`xcodebuild -scheme Wardrobe build`

## 开发指南

### 项目结构
```
Wardrobe/
├── ContentView.swift           # 主视图
├── WardrobeApp.swift          # 应用入口
├── MainView.swift             # 主界面
├── OutfitView.swift           # 搭配视图
├── Item.swift                 # 数据模型
├── WeatherService.swift       # 天气服务
├── Configurations/           # .xcconfig 配置目录
├── Configurations/Secrets.xcconfig
├── Configurations/Development.xcconfig
├── Configurations/Production.xcconfig
├── Configurations/Secrets.local.xcconfig.template
├── Info.plist                 # 应用配置
└── Assets.xcassets            # 资源文件
```

### 开发设置
详见 [SETUP.md](SETUP.md)，包括：
- 敏感信息（API Key）管理
- 本地开发配置
- 团队协作工作流

### 在 VS Code 中开发
详见 [VSCODE_IOS_SETUP.md](VSCODE_IOS_SETUP.md)

## 功能概述

### MVP 功能
- **用户档案与设置**：基本用户偏好设置（性别、尺码、常用风格）
- **拍照与图片导入**：从相机或相册添加衣物图片
- **衣物条目管理**：为每件衣物创建条目（照片、名称、类别、颜色、品牌、尺码等）
- **分类与筛选**：按类别、颜色、标签、季节等维度筛选
- **收藏与展示**：网格和列表两种展示模式
- **天气集成**：天气数据获取与展示

### 增强功能
- **搭配方案生成**：自动生成可穿搭组合
- **日程与穿搭历史**：日历查看和历史记录
- **导入/导出与备份**：iCloud 同步和数据备份
- **搜索与智能标签**：基于图像识别自动建议标签
- **分享与社交**：分享搭配到社交平台

## 技术栈

- **平台**：iOS 17+
- **语言**：Swift
- **UI 框架**：SwiftUI
- **数据存储**：SwiftData（本地）+ CloudKit（云同步）
- **图片处理**：Photos 框架 + PhotosPicker
- **智能功能**：Core ML + Vision（颜色检测、类别建议）

## 架构设计

### 分层设计
- **Model**：SwiftData 数据模型
- **Services**：图片服务、天气服务、同步服务
- **UI**：各页面和组件
- **AI/Rules**：搭配引擎

### 开发里程碑
1. **MVP**：图片导入、单品管理、基础筛选、简单搭配规则
2. **增强**：云同步、智能标签、日历历史
3. **完善**：社交分享、AI 搭配、高级功能

## UI/UX 设计指导

- **视觉风格**：极简扁平化设计，使用留白和清晰卡片
- **主色方案**：柔和的中性色配合一到两个强调色
- **导航结构**：底部 TabBar，包含衣橱、搭配、日历、设置四个模块
- **交互**：卡片详情页、长按快速操作、多选批量操作

## MVP 验收标准

- ✅ 能从相机/相册添加衣物图片并保存为条目
- ✅ 在衣橱页面以网格查看衣物，支持按类别/标签筛选
- ✅ 查看单件衣物详情，支持编辑与删除
- ✅ 搭配页面生成可浏览的搭配方案
- ✅ 设置页面保存用户偏好，应用于搭配建议

## 许可证

MIT License
