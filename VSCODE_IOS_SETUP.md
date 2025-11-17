# 在 VS Code 中开发 iOS（Swift）项目 — 必备步骤

下面说明一个在 VS Code 中编辑代码、但在 Xcode 中运行和调试的最小可行工作流（适用于 `Wardrobe` 项目）。按顺序执行以下必备步骤。

1. 安装/验证 Xcode

- 确保已从 App Store 或 Apple 开发者网站安装 Xcode。
- 验证：

```bash
xcodebuild -version
open /Applications/Xcode.app
```

2. 安装 Xcode 命令行工具

- 在终端运行：

```bash
xcode-select --install
xcode-select -p
```

3. 在 VS Code 中打开项目

- 用 VS Code 打开项目根目录（包含 `Wardrobe.xcodeproj`）。在编辑 Swift 文件时，保持 Xcode 项目结构不变。

4. 推荐安装的 VS Code 扩展

- `Swift`：语言支持和语法高亮（社区版或官方）。
- `CodeLLDB`：调试支持（可用于在 macOS 上调试 Swift 可执行文件）。
- `SwiftLint`（可选）：静态代码风格检查。

5. 编辑与保存代码

- 在 VS Code 中正常编辑 `.swift` 文件。
- 使用 Xcode 打开 `Wardrobe.xcodeproj` 来运行或在模拟器/真机上调试（因为 Xcode 管理签名与模拟器）。

6. 在终端构建（可选）

- 使用 `xcodebuild` 进行命令行构建/打包：

```bash
# 在项目根运行（替换 scheme 与名称）
xcodebuild -scheme Wardrobe -destination 'platform=iOS Simulator,name=iPhone 15' build
```

7. 推荐 `.vscode` 配置（示例）

- 创建 `.vscode/tasks.json` 来定义常用构建任务：

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "xcodebuild: build simulator",
      "type": "shell",
      "command": "xcodebuild -scheme Wardrobe -destination 'platform=iOS Simulator,name=iPhone 15' build",
      "group": "build",
      "problemMatcher": []
    }
  ]
}
```

- 示例 `launch.json`（用于本地可执行或 LLDB 调试 — 注意：UI 模拟器/真机调试仍建议在 Xcode 中进行）：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "LLDB: Attach to process",
      "type": "lldb",
      "request": "attach",
      "pid": "${command:pickProcess}",
      "stopAtEntry": false
    }
  ]
}
```

8. Xcode 中的调试与签名（必备）

- 使用 Xcode 设置签名证书（Signing & Capabilities）和 Provisioning Profile。
- 使用 Xcode 运行（⌘R）并在需要时选择设备或模拟器。

9. 版本控制建议

- 将 `.vscode` 中的共享配置（如 `extensions.json`）提交到仓库，以便团队成员一致。
- 请在 `.gitignore` 中排除用户特定的 Xcode 文件（例如 `xcuserdata/`）。

10. 常见命令汇总

```bash
# 验证 xcode 命令行工具
xcode-select -p

# 列出可用 scheme
xcodebuild -list

# 在模拟器上构建
xcodebuild -scheme Wardrobe -destination 'platform=iOS Simulator,name=iPhone 15' build

# 归档与导出 (release)
xcodebuild -scheme Wardrobe -archivePath ./build/Wardrobe.xcarchive archive
xcodebuild -exportArchive -archivePath ./build/Wardrobe.xcarchive -exportOptionsPlist exportOptions.plist -exportPath ./build
```

常见问题
- VS Code 无法运行 iOS 模拟器：请在 Xcode 中运行应用，或用 `xcodebuild` 指定 destination。
- 代码补全不完整：Xcode 的补全更完善，VS Code 依赖外部扩展，功能会有限。

更多帮助：如果你想，我可以为项目生成 `.vscode/tasks.json`, `launch.json`, 和 `extensions.json` 示例并提交到仓库。
