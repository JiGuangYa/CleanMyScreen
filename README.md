# CleanMyScreen

[EN](./README.en.md)

CleanMyScreen 是一个原生 macOS 屏幕清洁工具，用于在清洁 MacBook 屏幕时将所有已连接显示器切换为黑屏，避免误触桌面或其他应用，并允许通过 `Esc` 或屏幕上的 `Done` 按钮快速返回。

## 功能特性

- 原生 macOS `SwiftUI + AppKit` 应用
- 多显示器黑屏清洁模式
- 根据 macOS 首选语言列表自动切换界面语言
- 已支持英文、简体中文、繁体中文、日文、韩文、法文、德文、西班牙文、意大利文、巴西葡萄牙文
- 内置 `.app`、`.pkg`、`.dmg`、`.zip` 打包脚本

## 开发

```bash
swift build
swift run CleanMyScreenVerification
swift run CleanMyScreen
```

## 打包

```bash
./scripts/package_release.sh
```

生成的产物会输出到 `dist/` 目录。
