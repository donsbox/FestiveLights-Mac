# FestiveLights for Mac 🎄🎃 (GitHub 云端自动构建版)

专为 macOS 打造的原生菜单栏氛围彩灯应用（支持圣诞彩灯与万圣节南瓜灯切换），已内置 **GitHub Actions 云端自动构建工作流**，无需在本地 Mac 运行任何编译命令。

## 零本地终端：用 GitHub Actions 云端直接出 DMG

1. 登录 [GitHub](https://github.com/new) 新建一个仓库（例如 `FestiveLights-Mac`，公开或私有均可）。
2. 在新建仓库页面点击 **uploading an existing file**。
3. 在 Mac 访达打开解压后的本文件夹，按下 **`Command + Shift + .`** 显示隐藏的 `.github` 文件夹，将里面所有文件（包括 `.github`、`main.swift`、`generate_icon.swift`、`build_dmg.sh`）一起拖进网页并点击 **Commit changes**。
4. 等待约 **1 分钟**，GitHub 云端 macOS 机器会自动编译出同时兼容 Apple Silicon 和 Intel 的通用版 `FestiveLights.dmg`。
5. 回到仓库首页右侧的 **Releases**（或顶部 **Actions** 页面的 Artifacts），直接点击下载 **`FestiveLights.dmg`** 即可双击安装！

> 首次打开如遇 macOS 提示“无法验证开发者”，右键点击 `FestiveLights.app` 选择「打开」即可放行。
