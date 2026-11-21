// SlotboundDropRate.dylib
// A LiveContainer tweak that injects a Lua drop-rate hook into Slotbound.
//
// How it works:
//  - The game is a LÖVE (LuaJIT) game. Symbol drop rates come from the
//    6 class weights returned by src.game.cores getProjectedSymbolWeights /
//    baseSymbolWeights (A=archer D=duelist H=horse M=mage S=spear W=warrior).
//  - This dylib hooks lua_pcall (via fishhook) to capture the lua_State*,
//    then runs a Lua snippet that wraps those weight functions with
//    user multipliers read from "drop_rates.lua" in the save directory
//    (same folder as save_fallback.dat). The file is created with
//    defaults (all 1.0) on first run; edit it, restart the game.
//  - The hook is installed once, on the first lua_pcall after load, and
//    then the hook is left in place but becomes a no-op (single flag check).
//  - The Lua snippet handles both cases: cores not yet loaded (wraps
//    require) and cores already loaded (hooks package.loaded directly).
//
// Build: Xcode, iOS arm64. See .github/workflows/dylib.yml.

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <dlfcn.h>
#include "fishhook.h"

// Minimal Lua C API declarations (opaque state, no full headers needed).
typedef struct lua_State lua_State;
typedef int (*lua_pcall_fn)(lua_State *L, int nargs, int nresults, int errfunc);
typedef int (*luaL_loadstring_fn)(lua_State *L, const char *s);
typedef int (*luaL_dostring_fn)(lua_State *L, const char *str);

static lua_pcall_fn orig_lua_pcall = NULL;
static luaL_loadstring_fn real_luaL_loadstring = NULL;
static luaL_dostring_fn real_luaL_dostring = NULL;
static bool injected = false;
static bool injecting = false;

// The Lua snippet that installs the drop-rate hook. Kept as a single
// string so it can be injected via luaL_dostring.
static const char kInjectLua[] =
"local DROP_KEYS = { 'A', 'D', 'H', 'M', 'S', 'W' }\n"
"local DROP_DEFAULT = '-- 暴率调节（SlotBound 掉率插件）\\n'\n"
"  .. '-- 把想多出的那类数字调大：1 = 正常，2 = 两倍，5 = 五倍，0 = 不出\\n'\n"
"  .. '-- 改完保存，重启游戏生效。文件位置：和 save_fallback.dat 同一个文件夹。\\n'\n"
"  .. '-- A=弓手 D=决斗者 H=骑兵 M=法师 S=枪兵 W=战士\\n'\n"
"  .. 'return {\\n  A = 1,\\n  D = 1,\\n  H = 1,\\n  M = 1,\\n  S = 1,\\n  W = 1,\\n}\\n'\n"
"local drop_cfg = nil\n"
"local drop_cfg_loaded = false\n"
"local function load_drop_config()\n"
"  if drop_cfg_loaded then return drop_cfg end\n"
"  drop_cfg_loaded = true\n"
"  drop_cfg = { A = 1, D = 1, H = 1, M = 1, S = 1, W = 1 }\n"
"  local ok, content = pcall(love.filesystem.read, 'drop_rates.lua')\n"
"  if ok and content then\n"
"    local fn = loadstring(content)\n"
"    if fn then\n"
"      local ok2, tbl = pcall(fn)\n"
"      if ok2 and type(tbl) == 'table' then\n"
"        for _, k in ipairs(DROP_KEYS) do\n"
"          local v = tonumber(tbl[k])\n"
"          if v and v >= 0 then drop_cfg[k] = v end\n"
"        end\n"
"      end\n"
"    end\n"
"  else\n"
"    pcall(love.filesystem.write, 'drop_rates.lua', DROP_DEFAULT)\n"
"  end\n"
"  return drop_cfg\n"
"end\n"
"local function apply_drop_mult(weights)\n"
"  if type(weights) ~= 'table' then return weights end\n"
"  local cfg = load_drop_config()\n"
"  local out = {}\n"
"  local total = 0\n"
"  for k, v in pairs(weights) do\n"
"    local m = cfg[k] or 1\n"
"    local nv = (tonumber(v) or 0) * m\n"
"    out[k] = nv\n"
"    total = total + nv\n"
"  end\n"
"  if total <= 0 then return weights end\n"
"  for k in pairs(out) do out[k] = out[k] / total end\n"
"  return out\n"
"end\n"
"local function hook_cores(mod)\n"
"  if type(mod) ~= 'table' or mod.__drop_hooked then return mod end\n"
"  mod.__drop_hooked = true\n"
"  pcall(load_drop_config)\n"
"  if type(mod.getProjectedSymbolWeights) == 'function' then\n"
"    local orig = mod.getProjectedSymbolWeights\n"
"    mod.getProjectedSymbolWeights = function(...) return apply_drop_mult(orig(...)) end\n"
"  end\n"
"  if type(mod.baseSymbolWeights) == 'function' then\n"
"    local orig = mod.baseSymbolWeights\n"
"    mod.baseSymbolWeights = function(...) return apply_drop_mult(orig(...)) end\n"
"  end\n"
"  return mod\n"
"end\n"
"-- Case 1: cores already loaded, hook it now.\n"
"if package and package.loaded and package.loaded['src.game.cores'] then\n"
"  hook_cores(package.loaded['src.game.cores'])\n"
"end\n"
"-- Case 2: cores not yet loaded, wrap require so we catch it when it loads.\n"
"local _require = require\n"
"function require(name)\n"
"  local mod = _require(name)\n"
"  if name == 'src.game.cores' then hook_cores(mod) end\n"
"  return mod\n"
"end\n";

static void run_injection(lua_State *L) {
    if (!L) return;
    // Resolve the loader once.
    if (!real_luaL_dostring) {
        real_luaL_dostring = (luaL_dostring_fn)dlsym(RTLD_DEFAULT, "luaL_dostring");
    }
    if (!real_luaL_loadstring) {
        real_luaL_loadstring = (luaL_loadstring_fn)dlsym(RTLD_DEFAULT, "luaL_loadstring");
    }
    if (real_luaL_dostring) {
        real_luaL_dostring(L, kInjectLua);
    } else if (real_luaL_loadstring && orig_lua_pcall) {
        if (real_luaL_loadstring(L, kInjectLua) == 0) {
            orig_lua_pcall(L, 0, 0, 0);
        }
    }
}

static int hooked_lua_pcall(lua_State *L, int nargs, int nresults, int errfunc) {
    if (!injected && !injecting && L != NULL) {
        injecting = true;
        run_injection(L);
        injected = true;
        injecting = false;
    }
    return orig_lua_pcall(L, nargs, nresults, errfunc);
}

__attribute__((constructor))
static void slotbound_droprate_init(void) {
    struct rebinding rb;
    rb.name = "lua_pcall";
    rb.replacement = (void *)hooked_lua_pcall;
    rb.replaced = (void **)&orig_lua_pcall;
    rebind_symbols(&rb, 1);
}
