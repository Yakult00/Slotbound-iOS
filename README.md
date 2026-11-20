# SlotBound iOS 移植版

在 iPhone 上玩 SlotBound。基于最新 PC 版游戏包，用 LÖVE 11.5 编译的未签名 IPA，用 LiveContainer 安装即可游玩。

## 下载

- **最新版 v1.0**：[Slotbound-v1.0.ipa](https://github.com/Yakult00/Slotbound-iOS/releases/download/v1.0/Slotbound-v1.0.ipa)

## 安装方法

1. 下载上面的 IPA 文件。
2. 用 LiveContainer 打开 IPA 安装即可游玩。

## 说明

- 游戏数据来自 2026 年 11 月的 PC 最新版（2063 个文件）。
- Windows 专属的运气/保底系统（`SbLuck*` / `SbPity*`）在 iOS 上没有原生支持，已用纯 Lua 替代，游戏按基础概率运行，完全可玩。
- 韩文文件名已正确处理，不会出现缺文件的问题。
- 仓库里不含 Windows 启动器、Steam DLL、修改器等 PC 专属文件。

## 自己编译

仓库根目录有 `game.love`（游戏包）。GitHub Actions 工作流（`.github/workflows/ios.yml`）会用它编译出未签名 IPA。点 Actions → Build unsigned iOS IPA → Run workflow 即可。

包名：`com.yakult00.slotbound`
