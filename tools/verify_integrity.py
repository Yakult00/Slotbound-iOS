"""CI check: verify repo game files against the game's own integrity manifest.
Catches the v1.1.4-style corruption (CRLF conversion, missing/altered files)
before an IPA is built. Manifest format: SBIM001 / <count> / <sha256>\t<size>\t<path>.
"""
import hashlib
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
MANIFEST = os.path.join(ROOT, "src", "release_integrity_manifest.bin")

with open(MANIFEST, "rb") as f:
    raw = f.read()
text = raw.decode("utf-8")
lines = text.split("\n")
assert lines[0] == "SBIM001", f"bad manifest header: {lines[0]!r}"
declared = int(lines[1])
entries = [l for l in lines[2:] if l.strip()]
if len(entries) != declared:
    print(f"FAIL: manifest declares {declared} entries, found {len(entries)}")
    sys.exit(1)

bad = []
for entry in entries:
    digest, size, path = entry.split("\t")
    full = os.path.join(ROOT, path)
    if not os.path.isfile(full):
        bad.append(f"missing: {path}")
        continue
    data = open(full, "rb").read()
    if len(data) != int(size):
        bad.append(f"size mismatch: {path} (want {size}, got {len(data)})")
        continue
    if hashlib.sha256(data).hexdigest() != digest:
        bad.append(f"hash mismatch: {path}")
        continue

if bad:
    print(f"FAIL: {len(bad)} of {declared} files failed integrity check:")
    for b in bad[:30]:
        print("  " + b)
    sys.exit(1)
print(f"OK: all {declared} manifest files verified (sha256 + size)")

# 垫片层 pin：main.lua / real_main.luac / trainer_backend.lua / @bootstrap
# 不在游戏 manifest 里，靠 tools/shim.sha256 钉死。改动垫片后重新生成该文件。
SHIM = os.path.join(ROOT, "tools", "shim.sha256")
shim_bad = []
shim_count = 0
if os.path.isfile(SHIM):
    for line in open(SHIM, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        digest, path = line.split(None, 1)
        path = path.strip()
        shim_count += 1
        full = os.path.join(ROOT, path)
        if not os.path.isfile(full):
            shim_bad.append(f"missing: {path}")
            continue
        if hashlib.sha256(open(full, "rb").read()).hexdigest() != digest:
            shim_bad.append(f"hash mismatch: {path} (regenerate tools/shim.sha256)")
    if shim_bad:
        print(f"FAIL: {len(shim_bad)} of {shim_count} shim files failed pin check:")
        for b in shim_bad:
            print("  " + b)
        sys.exit(1)
    print(f"OK: all {shim_count} shim files verified against tools/shim.sha256")
else:
    print("WARN: tools/shim.sha256 not found, shim layer not checked")
