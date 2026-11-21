#!/usr/bin/env python3
"""同步训练器后端三份拷贝，消除手动同步漂移。

唯一事实来源：trainer_backend.lua（随 game.love 打包进游戏）。
同步目标：
  1. assistant/dylib/sb_trainer_v2.lua —— 与来源逐字节相同。
  2. assistant/dylib/trainer_lua.h —— C 头文件，内嵌来源的字节数组
     （Lua 内容 + 2 个 \\x00 终止符），kTrainerLuaLen 为 Lua 长度（不含终止符）。

用法：
    python3 tools/sync_backend.py            # 同步（改写目标文件）
    python3 tools/sync_backend.py --check    # 只校验，不改写；不一致退出 1

CI 里跑 --check，不一致直接 fail；本地改了后端逻辑后跑一次（不带参数）
同步，再提交。
"""
import hashlib
import os
import sys

HEADER_COMMENT = "// Auto-generated from sb_trainer_v2.lua \u2014 do not edit by hand."


def repo_root():
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.dirname(here)


def generate_header(lua_bytes):
    """按现有 trainer_lua.h 的精确格式生成 C 头文件内容。"""
    body = lua_bytes + b"\x00\x00"
    lines = [HEADER_COMMENT, "static const unsigned char kTrainerLua[] = {"]
    for i in range(0, len(body) - 1, 24):
        chunk = body[i:min(i + 24, len(body) - 1)]
        lines.append("  " + ",".join(str(b) for b in chunk) + ",")
    lines.append(f"  {body[-1]}}};")
    lines.append(f"static const size_t kTrainerLuaLen = {len(lua_bytes)};")
    return ("\n".join(lines) + "\n").encode("utf-8")


def main():
    check = "--check" in sys.argv[1:]
    root = repo_root()
    src = os.path.join(root, "trainer_backend.lua")
    dst_lua = os.path.join(root, "assistant", "dylib", "sb_trainer_v2.lua")
    dst_h = os.path.join(root, "assistant", "dylib", "trainer_lua.h")

    with open(src, "rb") as f:
        lua_bytes = f.read()
    expected_h = generate_header(lua_bytes)

    problems = []
    changed = []

    def sync_file(path, expected, label):
        if not os.path.isfile(path):
            problems.append(f"missing: {label}")
            if not check:
                with open(path, "wb") as f:
                    f.write(expected)
                changed.append(label)
                print(f"created {label}")
            return
        with open(path, "rb") as f:
            actual = f.read()
        if actual != expected:
            problems.append(f"out of sync: {label}")
            if not check:
                with open(path, "wb") as f:
                    f.write(expected)
                changed.append(label)
                print(f"updated {label}")
        else:
            print(f"ok {label}")

    sync_file(dst_lua, lua_bytes, "assistant/dylib/sb_trainer_v2.lua")
    sync_file(dst_h, expected_h, "assistant/dylib/trainer_lua.h")

    if check and problems:
        print("FAIL: trainer backend out of sync:")
        for p in problems:
            print("  " + p)
        print("run: python3 tools/sync_backend.py")
        sys.exit(1)
    if changed:
        print(f"synced {len(changed)} file(s)")
    print(f"OK: backend in sync ({len(lua_bytes)} bytes, "
          f"sha256 {hashlib.sha256(lua_bytes).hexdigest()[:12]})")


if __name__ == "__main__":
    main()
