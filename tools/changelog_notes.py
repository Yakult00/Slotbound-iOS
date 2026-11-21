#!/usr/bin/env python3
"""从 CHANGELOG.md 提取某个版本的发布说明，给 release notes 用。

用法:
    tools/changelog_notes.py <version> [changelog]
    tools/changelog_notes.py --fallback <version> [changelog]
    tools/changelog_notes.py --self-test

    <version>    只写数字，如 1.3.1（内部拼成 "## v1.3.1"）
    [changelog]  默认 CHANGELOG.md
    --fallback   找不到对应章节时输出默认文案并以 0 退出；
                 不加时找不到章节以 1 退出，方便调用方自行兜底

匹配规则:
    - 标题行以 "## v<version>" 开头，且紧跟的字符不是数字或点
      → "## v1.3.1（2026-11-21）—— 基于 PC v1.0.2" 命中
      → "## v1.3.11" 不命中（避免 v1.3.1 误吃 v1.3.11）
    - 到下一个 "## v<数字>" 标题为止（### 小标题保留）
    - 首尾空行裁掉

为什么用 Python 而不是 awk:
    macos runner 上是 BSD awk（onetrue awk），在 C/POSIX locale 下处理
    CHANGELOG 里的中文会直接报
        awk: towc: multibyte conversion failure
    然后整个提取失败、静默退回兜底文案（v1.3.1 那次 tag 发布就是这么翻车的）。
    Python 显式按 UTF-8 读，跟 locale 无关。
"""

from __future__ import annotations

import sys
from pathlib import Path

HEADING = "## v"


def extract(text: str, version: str) -> str:
    """返回该版本的正文；找不到返回空字符串。"""
    prefix = f"{HEADING}{version}"
    out: list[str] = []
    collecting = False

    for line in text.splitlines():
        if not collecting:
            if line.startswith(prefix):
                rest = line[len(prefix):]
                # 后面紧跟数字或点的不是同一个版本（v1.3.1 不该匹配 v1.3.11）
                if rest == "" or not (rest[0].isdigit() or rest[0] == "."):
                    collecting = True
            continue

        # 下一个版本标题 -> 结束
        if line.startswith(HEADING) and line[len(HEADING):len(HEADING) + 1].isdigit():
            break
        out.append(line)

    while out and not out[0].strip():
        out.pop(0)
    while out and not out[-1].strip():
        out.pop()

    return "\n".join(out)


def fallback_text(version: str) -> str:
    return (
        f"SlotBound iOS 移植版 v{version}\n\n"
        "用 LiveContainer 安装即可游玩。详情见 CHANGELOG.md。"
    )


def self_test() -> int:
    sample = """## v1.3.1（2026-11-21）—— 基于 PC v1.0.2

- 第一条
- 第二条

## v1.3.0（2026-11-21）—— 基于 PC v1.0.2

- 旧版本内容

## v1.3.11（未来）

- 不该被 1.3.1 吃掉
"""
    cases = [
        ("命中当前版本", extract(sample, "1.3.1"), "- 第一条\n- 第二条"),
        ("不串到下一版本", extract(sample, "1.3.1").count("旧版本内容"), 0),
        ("前缀近亲不误吃", extract(sample, "1.3.1").count("不该被"), 0),
        ("取更早版本", extract(sample, "1.3.0"), "- 旧版本内容"),
        ("取三段近亲", extract(sample, "1.3.11"), "- 不该被 1.3.1 吃掉"),
        ("不存在版本", extract(sample, "9.9.9"), ""),
    ]
    failed = 0
    for name, got, want in cases:
        ok = got == want
        failed += 0 if ok else 1
        print(f"  {'PASS' if ok else 'FAIL'}  {name}")
        if not ok:
            print(f"        got={got!r}\n        want={want!r}")
    print(f"{'OK' if not failed else 'FAILED'}: {len(cases) - failed}/{len(cases)} self-test cases")
    return 0 if not failed else 1


def main(argv: list[str]) -> int:
    args = list(argv[1:])

    if args and args[0] == "--self-test":
        return self_test()

    fallback = False
    if args and args[0] == "--fallback":
        fallback = True
        args.pop(0)

    if not args or not args[0]:
        print("用法: changelog_notes.py [--fallback] <version> [changelog] | --self-test", file=sys.stderr)
        return 2

    version = args[0]
    path = Path(args[1] if len(args) > 1 else "CHANGELOG.md")

    if not path.is_file():
        print(f"找不到 {path}", file=sys.stderr)
        if fallback:
            print(fallback_text(version))
            return 0
        return 1

    # 显式 UTF-8，跟 runner 的 locale 无关
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        print(f"读不了 {path}: {exc}", file=sys.stderr)
        if fallback:
            print(fallback_text(version))
            return 0
        return 1

    notes = extract(text, version)
    if not notes.strip():
        print(f"{path} 里没有 v{version} 的章节", file=sys.stderr)
        if fallback:
            print(fallback_text(version))
            return 0
        return 1

    print(notes)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
