#!/usr/bin/env bash
# 从 CHANGELOG.md 提取某个版本的发布说明，给 release notes 用。
#
# 用法:
#   tools/changelog_notes.sh <version> [changelog]
#   tools/changelog_notes.sh --fallback <version> [changelog]
#
#   <version>    只写数字，如 1.3.0（函数内部拼成 "## v1.3.0"）
#   [changelog]  默认 CHANGELOG.md
#   --fallback   找不到对应章节时输出默认文案并以 0 退出；
#                不加时找不到章节以 1 退出，方便调用方自行兜底
#
# 匹配规则（两个 workflow 共用，别再各写一份）：
#   - 标题行以 "## v<version>" 开头，且紧跟的字符不是数字或点
#     → "## v1.3.0（2026-11-21）—— 基于 PC v1.0.2" 命中
#     → "## v1.3.01" 不命中（避免 v1.3.0 误吃 v1.3.01）
#   - 到下一个 "## v<数字>" 标题为止（### 小标题保留）
#   - 首尾空行裁掉
set -euo pipefail

FALLBACK=0
if [[ "${1:-}" == "--fallback" ]]; then
    FALLBACK=1
    shift
fi

if [[ $# -lt 1 || -z "${1:-}" ]]; then
    echo "用法: $0 [--fallback] <version> [changelog]" >&2
    exit 2
fi

VERSION="$1"
FILE="${2:-CHANGELOG.md}"

fallback_text() {
    printf 'SlotBound iOS 移植版 v%s\n\n用 LiveContainer 安装即可游玩。详情见 CHANGELOG.md。\n' "$VERSION"
}

if [[ ! -f "$FILE" ]]; then
    echo "找不到 $FILE" >&2
    if [[ $FALLBACK -eq 1 ]]; then
        fallback_text
        exit 0
    fi
    exit 1
fi

NOTES="$(awk -v ver="## v${VERSION}" '
    index($0, ver) == 1 {
        c = substr($0, length(ver) + 1, 1)
        if (c == "" || c !~ /[0-9.]/) { flag = 1; next }
    }
    /^## v[0-9]/ && flag { exit }
    flag { lines[++n] = $0 }
    END {
        # 砍掉尾部空行
        while (n > 0 && lines[n] ~ /^[[:space:]]*$/) n--
        # 砍掉头部空行
        first = 1
        while (first <= n && lines[first] ~ /^[[:space:]]*$/) first++
        for (i = first; i <= n; i++) print lines[i]
        exit (n >= first ? 0 : 1)
    }
' "$FILE")" || {
    if [[ $FALLBACK -eq 1 ]]; then
        fallback_text
        exit 0
    fi
    echo "CHANGELOG.md 里没有 v${VERSION} 的章节" >&2
    exit 1
}

printf '%s\n' "$NOTES"
