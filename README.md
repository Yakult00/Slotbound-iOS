# SlotBound iOS (LÖVE 11.5)

iOS port of the latest PC SlotBound game package, built with the official
LÖVE 11.5 iOS Xcode project. Unsigned IPA, re-sign with your own Apple ID
(AltStore / Sideloadly) before installing.

## Download

- IPA: https://github.com/Yakult00/Slotbound-iOS-v3/releases/download/ios-latest/Slotbound.ipa
- Game data: https://github.com/Yakult00/Slotbound-iOS-v3/releases/tag/game-data

## Build

Run **Build unsigned iOS IPA** from GitHub Actions. The workflow runs on a
macOS runner, downloads the latest game package from the `game-data` release,
builds an iPhoneOS ARM64 app, embeds `game.love`, verifies the Mach-O
platform and architecture, and uploads an unsigned IPA artifact (and, by
default, publishes it to the `ios-latest` release).

Bundle identifier: `com.yakult00.slotbound`.

## Notes

- The game data is the Nov 2026 PC package (SBDATA008, 2063 files). The
  Windows-only luck/pity natives (`SbLuck*` / `SbPity*`, exported by
  Slotbound.exe) are stubbed with neutral pure-Lua replacements in `main.lua`,
  so the game runs on iOS with base slot odds and no pity forcing.
- Korean filenames are stored with the ZIP UTF-8 flag so LÖVE can find them.
- This repo intentionally does not contain the Windows launcher, Steam DLLs,
  trainer, loader, or ANGLE runtime.
