# 开发配置指南

## 1. 敏感信息管理

### 问题
避免在代码仓库中硬编码 API Key 等敏感信息。

### 解决方案
使用本地配置文件系统管理敏感信息，每个开发者有独立的配置。

### 首次设置

1. 复制本地 secrets 模板：

```bash
cp Configurations/Secrets.local.xcconfig.template Configurations/Secrets.local.xcconfig
```

2. 编辑 `Configurations/Secrets.local.xcconfig`，将 `YOUR_DEVELOPMENT_API_KEY_HERE` 替换为实际的开发 Key。

3. 在 Xcode 中为 Target 的 Build Configuration 指定配置文件：
   - 选择项目 → 目标 → Info → Configurations
   - 将 Debug 的配置文件设置为 `Configurations/Development.xcconfig`
   - 将 Release 的配置文件设置为 `Configurations/Production.xcconfig`

工作原理：
- `Configurations/Secrets.xcconfig`：可提交的共享占位符或默认值
- `Configurations/Secrets.local.xcconfig`：每位开发者的本地私有值（被 `.gitignore` 忽略）
- `Development.xcconfig` / `Production.xcconfig`：分别包含上述文件，并在构建时注入 `AMAP_API_KEY` 到 `Info.plist`

### Git 安全
- `Configurations/Secrets.local.xcconfig` 已列入 `.gitignore`，不会提交到仓库
- 不要将生产 Key 写入受版本控制的文件中

### 验证与故障排查

- 验证 `Info.plist` 中 `AMAP_API_KEY` 是否为 `$(AMAP_API_KEY)`，以确保构建时会被注入。
- 验证本地 secrets 文件是否存在：`Configurations/Secrets.local.xcconfig`（每位开发者本地创建）。
- 常见错误：`could not find included file 'Secrets.local.xcconfig'` — 请确认已复制本地文件，或从 `Development.xcconfig` 中移除对本地文件的 `#include`。
- 运行时快速验证：在调试或启动处打印：
```swift
print(Bundle.main.object(forInfoDictionaryKey: "AMAP_API_KEY") ?? "(empty)")
```
- 生产环境建议通过 CI 或密钥管理服务注入生产 Key，切勿将生产 Key 写入受版本控制的文件。

## 2. 本地开发设置

### 前置要求
- Xcode 14.0+
- iOS 17.0+ SDK
- 命令行工具：`xcode-select --install`

### VS Code 开发
参见 [VSCODE_IOS_SETUP.md](VSCODE_IOS_SETUP.md) 了解如何在 VS Code 中编辑代码，在 Xcode 中运行/调试。

### 构建与运行
```bash
# 列出可用 scheme
xcodebuild -list

# 在模拟器上构建运行
xcodebuild -scheme Wardrobe -destination 'platform=iOS Simulator,name=iPhone 15' build run
```

## 3. 团队协作工作流

1. **新成员加入**
   - 克隆仓库
   - 复制配置模板：

      ```bash
      cp Configurations/Secrets.local.xcconfig.template Configurations/Secrets.local.xcconfig
      ```

   - 编辑 `Configurations/Secrets.local.xcconfig`，填入自己的 API Key
   - 开始开发

2. **日常开发**
   - 修改代码并提交
   - 本地配置文件被 `.gitignore` 忽略，不会提交
   - 不会互相影响

3. **生产部署**
   - 确保有正确的生产环境 API Key 配置
   - 删除本地配置后，系统会使用 `Info.plist` 的默认值