# SlotBound iOS 移植版

把 PC 游戏 SlotBound 搬到 iPhone 上玩。SlotBound 是一款老虎机肉鸽游戏（拉老虎机打怪、攒遗物、闯关），原本只有 PC 版，没有官方手游。这个项目把最新 PC 版（v1.0.2）的游戏包解出来，用 LÖVE 11.5 编译成未签名 IPA，在 iPhone 上用 LiveContainer 安装就能直接玩，存档、道具、关卡都和 PC 版一样，免费。

游戏版权归原作者 Optima Arch 所有，本项目是个人移植分享，仅供学习交流。


## 截图

![游戏实机](docs/screenshot-game.jpg)

*游戏实机：老虎机 + 战斗画面，iPhone 横屏直接玩*

![辅助面板](docs/screenshot-trainer.jpg)

*辅助面板：SLOTBOUND 修改器（资源 / 老虎机 / 单位 / 商店），纯 Lua 后端，无需 JIT*

## 安装方法

1. 下载上面的 IPA 文件。
2. 用 LiveContainer 打开 IPA 安装即可游玩。

## 触屏操作

游戏原本是 PC 鼠标操作，触屏做了适配：

- **点按**：左键（选择、查看道具）。
- **右上角按钮 L / R**：切换右键模式。平时显示 L（左键，深色），点一下变成 R（右键，橙色），这时点道具就是右键（使用道具），再点一下切回左键。
- **左上角 ESC 按钮**：返回，相当于键盘 Esc。
- **双指点按**：也可以右键（第一根手指的位置）。

> 目前的触屏操作只是临时方案。游戏原本是鼠标操作，右键、悬停这些动作在触屏上没有很好的对应办法，现有的 L/R 切换和双指点按用起来都不够顺手。如果你有更好的操作方案（手势、布局、交互都可以），欢迎在 Issues 里交流，觉得可行的会做到下一个版本里。

## 游戏辅助（可选）

每个 release 里除了 IPA 还有两个辅助面板 dylib，游戏里改金币 / 旋转次数 / 水晶、调老虎机大奖、改单位属性。面板不改游戏文件，不注入不生效，删掉 dylib 就是原版游戏。

**LiveContainer（非越狱）用 NoJIT 版**：

1. 从 release 下载 `SlotboundTrainer-NoJIT.dylib`（不要用 `SlotboundTrainer.dylib`，它含 Dobby 内存 hook，在 LiveContainer 下会闪退）。
2. 在 LiveContainer 里找到 SlotBound，把 dylib 放进它的 Tweaks 目录。
3. 对 App 重新签名（Sign），再启动游戏。
4. 游戏里出现悬浮骰子按钮，点开就是面板（资源 / 老虎机 / 单位三页）。

面板左上角显示的版本号（vX.Y.Z）由编译时注入，和 release 版本一致。`trainer_backend.lua` 是面板的后端逻辑（纯 Lua），已随 game.love 打进 IPA，不用另外装。

## 版本对照

| 移植版 | 基于 PC 版 | 说明 |
|---|---|---|
| v1.0 – v1.1.5 | v1.0.0 | 首批移植版 |
| v1.2.0 – v1.3.0 | v1.0.2 | 游戏内容升级到官方 v1.0.2 |

每次发布的改动见 [CHANGELOG.md](CHANGELOG.md)。

## 项目结构

仓库根目录就是完整的游戏项目（解开的游戏包），不是一个黑盒 zip：

```
Slotbound-iOS/
├── main.lua              # 垫片：iOS 适配（见下）
├── real_main.luac        # 游戏原本的 main.lua（LuaJIT 字节码）
├── conf.lua              # 游戏配置
├── icon.png              # 应用图标
├── release.flag
├── @bootstrap
├── src/                  # 游戏全部代码和资源
│   ├── audio/            # 音效、音乐
│   ├── data/             # 游戏数据
│   ├── game/             # 游戏逻辑
│   ├── language/         # 语言文件
│   ├── sprites/          # 图片资源
│   ├── ui/               # 界面
│   └── ...               # 其余 2076 个文件
├── trainer_backend.lua   # 游戏辅助：后端逻辑（纯 Lua，随游戏一起打包）
├── assistant/            # 游戏辅助：原生面板
│   ├── dylib/            # 面板源码 + 内嵌后端
│   └── ...
├── tools/
│   ├── verify_integrity.py  # CI 用的游戏完整性校验（对照游戏自带清单 + 垫片 pin）
│   ├── shim.sha256          # 垫片层 pin（main.lua / real_main.luac / trainer_backend.lua / @bootstrap）
│   ├── sync_backend.py      # 同步训练器后端三份拷贝（lua → dylib 内嵌版 → C 头文件）
│   └── changelog_notes.py   # 从 CHANGELOG.md 提取 release 说明（不用 awk，macOS 上中文会炸）
├── README.md
├── CHANGELOG.md
└── .github/workflows/    # 编译流水线
    ├── ios.yml           # 打 IPA
    └── assist.yml        # 打辅助面板 dylib
```

本地构建产物（`build/`、`.ipa`、`game.love`）不提交进仓库，只走 release assets。

## 移植说明

- 游戏数据来自 2026 年 11 月的 PC 最新版（2076 个文件），原先锁在加密容器 `Slotbound.dat`（SBDATA008）里，已逆向解出。
- `main.lua` 是垫片，做了三件事：用纯 Lua 的 `ffi` 替代 Windows 原生的运气/保底系统（`SbLuck*` / `SbPity*`，游戏按基础概率运行，完全可玩）；用 `pcall` 包住 `jit.on/off`（iOS 没有 JIT，直接调会黑屏）；加上触屏适配（右键切换按钮、返回按钮、双指点按）。
- 韩文文件名已正确处理（UTF-8 标志），不会出现缺文件的问题。
- 仓库里不含 Windows 启动器、Steam DLL、修改器等 PC 专属文件。
- 66 个 `.lua` 文件是 LuaJIT 字节码（不是源码），在 GitHub 上打开会显示二进制；图片、音乐、配置文件可以直接浏览。

只想手动编一次不发布：点 Actions → Build unsigned iOS IPA → Run workflow，编好在 Artifacts 里下载 `Slotbound-unsigned`（只有 IPA，不建 release）。

包名：`com.yakult00.slotbound`
