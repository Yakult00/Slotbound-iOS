-- sb_trainer_v2.lua — SlotBound iOS 修改器后端（注入版，GGGLHHH 功能集）
--
-- 由 dylib 在运行时注入（经 lua_pushnumber hook + luaL_loadbuffer），
-- 不改游戏文件。注入前是原版游戏，注入后才有辅助面板。
--
-- 文件协议（dylib 原生面板写文件，后端轮询）：
--   dylib → 游戏：save 目录 cheats_ui.lua（金币/旋转/水晶/大奖/命令，带递增 seq）
--   游戏 → dylib：save 目录 cheats_status.lua（实时金币/旋转/水晶/选中单位/技能）
--   游戏 → dylib：save 目录 cheats_catalog.txt（词条/刻印/物品/觉醒目录）
--
-- 功能（GGGLHHH/slotbound-trainer）：
--   资源：金币 / 旋转次数（spinsLeft）/ 水晶，显示、改值、加、锁定。
--   老虎机：大奖模式，9 格同一兵种（W/A/S/M/H/D/J/random）。
--   单位：星级、吸收 LV、基础属性（生命/攻击/攻速/射程）、
--         主动技能冷却（最短 0.1 秒）、被动技能触发条件
--         （charges 普攻几次触发 / chance 触发概率 / internalCooldown 内置冷却），
--         词条（32）、觉醒（12 候选）、刻印（33，等级 1-5，槽数可改）、物品（63）。
--   注意：棱彩概率没有做（GGGLHHH 也没做：波次、基地血量、棱彩概率）。
--
-- 与另一个 AI 的 sb_cheats.lua 的关键区别：
--   1) 自己包住 love.update，每帧调用 tick，不需要改 main.lua。
--   2) 等级/掉率相关全部删掉（不做棱彩概率）。
--   3) 新增旋转次数、主动技能冷却、被动技能触发条件、物品删除、觉醒目录。

local M = {}

local load_chunk = loadstring or load

local cfg = {
  seq = 0, coins_set = nil, coins_add = 0, lock_coins = false,
  spins_set = nil, spins_add = 0, lock_spins = false,
  jungsu_set = nil, lock_jungsu = false,
  originite_set = nil, originite_add = 0, lock_originite = false,
  core_add = 0, core_add_all = 0,
  jackpot = false, run_lua = nil,
  cmd = nil, arg = nil, arg2 = nil,
}
local applied_seq = -1
local last_content = nil
local poll_t = 0
local status_t = 0
local catalog_t = 0

----------------------------------------------------------------
-- 性能：GC 平滑 + 探针（不动帧率上限、不动 vsync）
----------------------------------------------------------------
local last_mtime = -1
local catalog_dirty = true
local catalog_written = false

local alive_t = 0
local alive_now = false

-- GC：只调「更早开始收、每次多收一点」，不加每帧 step，不动帧率上限。
-- pause 200→150：堆没翻倍就开始收，单次停顿更小。
-- stepmul 200→400：每次增量多干一点，减少一次性 full GC 的概率。
local gc_tuned = false
local function tune_gc()
  if gc_tuned then return end
  gc_tuned = true
  pcall(collectgarbage, "setpause", 150)
  pcall(collectgarbage, "setstepmul", 400)
end

-- 面板活着吗：dylib 打开面板时每 2 秒写一次 cheats_alive.txt
local function panel_alive(now)
  local ok, info = pcall(love.filesystem.getInfo, "cheats_alive.txt")
  if not ok or not info then return false end
  local m = info.modtime or 0
  if m == 0 then return true end
  return (now - m) <= 6
end

----------------------------------------------------------------
-- 配置读取（dylib → 游戏）
----------------------------------------------------------------
local function load_cfg()
  -- 先用 getInfo 比 mtime：没变就完全不读文件（省掉每秒 2 次读盘）
  local iok, info = pcall(love.filesystem.getInfo, "cheats_ui.lua")
  if not iok then return end
  local mt = (info and info.modtime) or 0
  if mt > 0 and mt == last_mtime then return end
  local ok, content = pcall(love.filesystem.read, "cheats_ui.lua")
  if not ok or not content then return end
  if mt > 0 then last_mtime = mt end
  if content == last_content then return end
  last_content = content
  local fn = load_chunk(content)
  if not fn then return end
  local ok2, tbl = pcall(fn)
  if not ok2 or type(tbl) ~= "table" then return end
  cfg = tbl
end

----------------------------------------------------------------
-- 资源
----------------------------------------------------------------
local function set_jungsu(v)
  rawset(_G, "jungsu", v)
  pcall(function()
    local ui = rawget(_G, "ui")
    if type(ui) == "table" and type(ui.jungsuBalanceTarget) == "number" then ui.jungsuBalanceTarget = v end
    if type(rawget(_G, "jungsuBalanceTarget")) == "number" then rawset(_G, "jungsuBalanceTarget", v) end
  end)
end

-- 升级宝石（originite）：主菜单模块持有，setOriginiteAmount 直接设值
local function get_originite()
  local ok, mm = pcall(require, "src.ui.mainmenu")
  if ok and type(mm) == "table" and type(mm.getOriginiteAmount) == "function" then
    local ok2, v = pcall(mm.getOriginiteAmount)
    if ok2 and type(v) == "number" then return v end
  end
  return nil
end

local function set_originite(v)
  local ok, mm = pcall(require, "src.ui.mainmenu")
  if not ok or type(mm) ~= "table" then return false end
  if type(mm.setOriginiteAmount) == "function" then
    local ok2 = pcall(mm.setOriginiteAmount, v)
    return ok2 == true
  end
  return false
end

----------------------------------------------------------------
-- 选中单位解析（GGGLHHH luaops.h kResolveUnit 移植）
----------------------------------------------------------------
local function resolve_unit()
  local t = rawget(_G, "tooltip")
  local tg = t and t.locked and (t.lockedTarget or t.target) or nil
  local u = (tg and tg.kind == "roster") and tg.ref or nil
  if not u and t and t.lastSelectedRef and rawget(_G, "battlefield") then
    local bf = rawget(_G, "battlefield")
    for _, r in ipairs(bf.rosterUnits or {}) do
      if r == t.lastSelectedRef then u = r break end
    end
  end
  return u
end

----------------------------------------------------------------
-- 命令实现
----------------------------------------------------------------
local function cmd_add_option(id)
  local u = resolve_unit()
  if not u then return "none" end
  local RO = require("src.data.randomoption")
  local o = RO.rollForId(id)
  if not o then
    local d
    for _, x in ipairs(RO.catalog) do if tostring(x.id) == tostring(id) then d = x end end
    if not d then return "no_id" end
    o = { id = d.id, name = d.name, effect = d.effect, icon = d.icon, rarity = d.rarity, source = d.source }
    local vs, total = d.variants or {}, 0
    for _, v in ipairs(vs) do total = total + (tonumber(v.chance or v.weight) or 0) end
    local r, pick = math.random() * total, vs[#vs]
    for _, v in ipairs(vs) do
      r = r - (tonumber(v.chance or v.weight) or 0)
      if r <= 0 then pick = v break end
    end
    if pick then o.variant = { value = pick.value } end
  end
  u.randomOptions = u.randomOptions or {}
  u.randomOptions[#u.randomOptions + 1] = o
  u.randomOption = u.randomOptions[1]
  return "ok"
end

local function cmd_remove_option(slot)
  local u = resolve_unit()
  if not u then return "none" end
  if u.randomOptions and u.randomOptions[slot] then table.remove(u.randomOptions, slot) end
  u.randomOption = u.randomOptions and u.randomOptions[1] or nil
  return "ok"
end

local function cmd_replace_option(id, slot)
  local r = cmd_remove_option(slot or 1)
  if r == "none" then return "none" end
  return cmd_add_option(id)
end

local function cmd_add_imprint(id, level)
  local u = resolve_unit()
  if not u then return "none" end
  local C = require("src.data.constants")
  local d = C.imprint.definitions[id]
  if not d then return "no_id" end
  local L = math.max(1, math.min(level or 1, #(d.levels or {})))
  u.imprints = u.imprints or {}
  local o = {}
  for k, v in pairs(d) do if k ~= "levels" then o[k] = v end end
  o.rarity = u.grade or "normal"
  o.maxLevel = #(d.levels or {})
  local lv = d.levels and d.levels[L]
  o.level = L
  if lv then o.stats = lv.stats; o.desc = lv.desc or o.desc; o.shortDesc = lv.shortDesc or o.shortDesc end
  u.imprints[#u.imprints + 1] = o
  if (u.maxImprintSlots or 1) < #u.imprints then u.maxImprintSlots = #u.imprints end
  return "ok"
end

local function cmd_remove_imprint(slot)
  local u = resolve_unit()
  if not u then return "none" end
  if u.imprints and u.imprints[slot] then table.remove(u.imprints, slot) end
  return "ok"
end

local function cmd_replace_imprint(id, slot)
  local u = resolve_unit()
  if not u then return "none" end
  local lv = nil
  if u.imprints and u.imprints[slot or 1] then lv = u.imprints[slot or 1].level end
  cmd_remove_imprint(slot or 1)
  return cmd_add_imprint(id, lv or 5)
end

local function cmd_set_imprint_slots(n)
  local u = resolve_unit()
  if not u then return "none" end
  u.maxImprintSlots = math.max(0, math.floor(tonumber(n) or 0))
  return "ok"
end

local function cmd_set_absorb_lv(lv)
  local u = resolve_unit()
  if not u then return "none" end
  lv = tonumber(lv) or 1
  local f = rawget(_G, "__slotSetAwakeningLevel")
  if type(f) == "function" then
    pcall(f, u, lv)
    -- 游戏内这个函数会把值夹到 100；超过 100 时直接写字段
    if tonumber(u.absorbLV) ~= lv then u.absorbLV = lv end
  else
    u.absorbLV = lv
  end
  return "ok:" .. tostring(u.absorbLV)
end

-- 吸收 LV 加法（面板的 +1 / +100 按钮）
local function cmd_absorb_add(n)
  local u = resolve_unit()
  if not u then return "none" end
  n = tonumber(n) or 1
  local cur = tonumber(u.absorbLV) or 1
  local target = cur + n
  local f = rawget(_G, "__slotSetAwakeningLevel")
  if type(f) == "function" then
    pcall(f, u, target)
    if tonumber(u.absorbLV) ~= target then u.absorbLV = target end
  else
    u.absorbLV = target
  end
  return "ok:" .. tostring(u.absorbLV)
end

local function cmd_raise_rank(rank)
  local u = resolve_unit()
  if not u then return "none" end
  local f = rawget(_G, "__slotStoneRaiseRank")
  if type(f) ~= "function" then return "no_fn" end
  f(u, rank)
  return "ok"
end

local function live_ally(u)
  local bf = rawget(_G, "battlefield")
  local a = u and u.allyRef
  if type(a) == "table" and bf and bf.mode == "battle" then
    for _, x in ipairs(bf.allies or {}) do if x == a then return a end end
  end
  return nil
end

local function cmd_set_stat(key, value, is_mul)
  local u = resolve_unit()
  if not u then return "none" end
  local st = u.stats
  if type(st) ~= "table" then return "no_stats" end
  local old = tonumber(st[key]) or 0
  local new = is_mul and (old * value) or value
  st[key] = new
  if key == "distance" then u.distance = new end
  local a = live_ally(u)
  if a and old > 0 and not a.dying then
    local r = new / old
    if key == "hp" then
      local frac = (a.maxhp and a.maxhp > 0) and (a.hp or a.maxhp) / a.maxhp or 1
      a.maxhp = math.max(1, math.floor((a.maxhp or new) * r + 0.5))
      a.hp = math.max(1, math.min(a.maxhp, a.maxhp * frac))
    elseif key == "atk" then
      a.dmg = (a.dmg or new) * r
    elseif key == "aspd" then
      a.atkPeriod = (a.atkPeriod or 1 / new) / r
      a.atkTicks = math.max(1, math.floor(a.atkPeriod * 60 + 0.5))
    elseif key == "distance" then
      a.distance = (a.distance or new) * r
    end
  end
  return "ok"
end

-- 面板加的物品：游戏 restorePurchasedItems() 会按存档重建，把面板临时加的直接清掉。
-- 这里记住这些物品，每次重建后再补回去；同时落盘 trainer_items.txt，重启也保留。
local injected_items = {}
local injected_guard = nil
local injected_base = nil
local injected_busy = false
local injected_loaded = false
-- 「一键清除所有核心」后持续压制：游戏会用存档/准备界面把 loadout 重新灌回来
local cores_wiped = false

local function dlog(msg)
  pcall(love.filesystem.append, "sbtrainer_backend.log",
    os.date("%H:%M:%S ") .. tostring(msg) .. "\n")
end

local function injected_save()
  local lines = {}
  for id, lv in pairs(injected_items) do
    lines[#lines + 1] = tostring(id) .. "\t" .. tostring(lv)
  end
  table.sort(lines)
  pcall(love.filesystem.write, "trainer_items.txt", table.concat(lines, "\n"))
end

local function injected_load()
  injected_items = {}
  local ok, data = pcall(love.filesystem.read, "trainer_items.txt")
  if not ok or type(data) ~= "string" then return end
  for id, lv in data:gmatch("([^\t\r\n]+)\t(%d+)") do
    injected_items[tostring(id)] = tonumber(lv) or 1
  end
end

local function injected_apply()
  if injected_busy then return end
  local ui = rawget(_G, "ui")
  if type(ui) ~= "table" then return end
  injected_busy = true
  local ok, I = pcall(require, "src.game.item")
  if ok and type(I) == "table" then
    ui._itemPurchased = ui._itemPurchased or {}
    ui._itemPurchasedKeys = ui._itemPurchasedKeys or {}
    for id, lv in pairs(injected_items) do
      local found = false
      for _, o in ipairs(ui._itemPurchased) do
        if tostring(o.id) == tostring(id) then
          o.level = lv
          if type(o.updateEffectString) == "function" then pcall(o.updateEffectString, o) end
          found = true
          break
        end
      end
      if not found then
        local d = I.getById(id)
        if d then
          local o = {}
          for k, v in pairs(d) do o[k] = v end
          o.level = lv
          if type(o.updateEffectString) == "function" then pcall(o.updateEffectString, o) end
          table.insert(ui._itemPurchased, o)
          local n = tonumber(ui._itemPanelNextId) or (#ui._itemPurchased + 100)
          table.insert(ui._itemPurchasedKeys, "p" .. tostring(n))
          ui._itemPanelNextId = n + 1
        end
      end
    end
  end
  injected_busy = false
end

-- 廉价检查：面板加的物品是否已经全在 _itemPurchased 里且等级一致
local function injected_need()
  local ui = rawget(_G, "ui")
  if type(ui) ~= "table" or type(ui._itemPurchased) ~= "table" then return true end
  for id, lv in pairs(injected_items) do
    local hit = false
    for _, o in ipairs(ui._itemPurchased) do
      if tostring(o.id) == tostring(id) then
        if tonumber(o.level) ~= tonumber(lv) then return true end
        hit = true
        break
      end
    end
    if not hit then return true end
  end
  return false
end

local function injected_hook()
  local cur = rawget(_G, "restorePurchasedItems")
  if type(cur) ~= "function" or cur == injected_guard then return end
  injected_base = cur
  injected_guard = function(...)
    pcall(injected_base, ...)
    pcall(injected_apply)
  end
  rawset(_G, "restorePurchasedItems", injected_guard)
end

local function cmd_add_item(id, level)
  local ui = rawget(_G, "ui")
  if type(ui) ~= "table" then return "noui" end
  local I = require("src.game.item")
  local d = I.getById(id)
  if not d then return "no_id" end
  local maxL = math.max(1, math.floor(tonumber(d.maxLevel) or 1))
  local L = math.max(1, math.min(maxL, level or 1))
  ui._itemPurchased = ui._itemPurchased or {}
  injected_items[tostring(d.id)] = L
  injected_save()
  injected_hook()
  for _, o in ipairs(ui._itemPurchased) do
    if tostring(o.id) == tostring(d.id) then
      o.level = L
      if type(o.updateEffectString) == "function" then pcall(o.updateEffectString, o) end
      return "ok"
    end
  end
  local o = {}
  for k, v in pairs(d) do o[k] = v end
  o.level = L
  if type(o.updateEffectString) == "function" then pcall(o.updateEffectString, o) end
  table.insert(ui._itemPurchased, o)
  ui._itemPurchasedKeys = ui._itemPurchasedKeys or {}
  local n = tonumber(ui._itemPanelNextId) or (#ui._itemPurchased + 100)
  table.insert(ui._itemPurchasedKeys, "p" .. tostring(n))
  ui._itemPanelNextId = n + 1
  return "ok"
end

local function cmd_remove_item(id)
  local ui = rawget(_G, "ui")
  if type(ui) ~= "table" then return "noui" end
  local list = ui._itemPurchased
  if type(list) ~= "table" then return "no_id" end
  for i, o in ipairs(list) do
    if tostring(o.id) == tostring(id) then
      table.remove(list, i)
      -- 背包和面板键是两条并行的列表，一起删（GGGLHHH items.cpp Remove）
      if type(ui._itemPurchasedKeys) == "table" and ui._itemPurchasedKeys[i] then
        table.remove(ui._itemPurchasedKeys, i)
      end
      injected_items[tostring(id)] = nil
      injected_save()
      return "ok"
    end
  end
  return "no_id"
end

local function cmd_replace_item(id, level)
  cmd_remove_item(id)
  return cmd_add_item(id, level)
end

-- 商店页：全部物品一次性加入背包 / 清空背包
local function cmd_items_all(level)
  local ok, m = pcall(require, "src.game.item")
  if not ok or type(m) ~= "table" or type(m.getAll) ~= "function" then return "noitem" end
  local n = 0
  for _, d in ipairs(m.getAll()) do
    if type(d) == "table" and d.id then
      local r = cmd_add_item(d.id, tonumber(level) or 1)
      if r == "ok" then n = n + 1 end
    end
  end
  return "ok:" .. tostring(n)
end

local function cmd_items_clear()
  local ui = rawget(_G, "ui")
  if type(ui) ~= "table" then return "noui" end
  ui._itemPurchased = {}
  ui._itemPurchasedKeys = {}
  injected_items = {}
  injected_save()
  return "ok"
end

local function cmd_add_awakening(id)
  local u = resolve_unit()
  if not u then return "none" end
  local A = require("src.game.awakening")
  pcall(A.normalize, u)
  local aw = u.awakening
  if type(aw) ~= "table" then return "no_aw" end
  local cat = A.catalog(u)
  if not (cat and cat.candidates and cat.candidates[id]) then return "no_id" end
  aw.selected = aw.selected or {}
  if #aw.selected >= 5 then return "full" end
  for _, x in ipairs(aw.selected) do if x == id then return "dup" end end
  aw.selected[#aw.selected + 1] = id
  aw.seen = aw.seen or {}
  aw.seen[id] = true
  pcall(A.normalize, u)
  local a = u.allyRef
  if type(a) == "table" and type(a.awakening) == "table" and a.awakening ~= u.awakening then
    local s = {}
    for i, x in ipairs(u.awakening.selected) do s[i] = x end
    a.awakening.selected = s
    pcall(A.normalize, a)
  end
  return "ok"
end

local function cmd_remove_awakening(slot)
  local u = resolve_unit()
  if not u then return "none" end
  local aw = u.awakening
  if type(aw) ~= "table" or type(aw.selected) ~= "table" then return "no_aw" end
  if aw.selected[slot] then table.remove(aw.selected, slot) end
  pcall(function()
    local A = require("src.game.awakening")
    pcall(A.normalize, u)
  end)
  return "ok"
end

local function cmd_replace_awakening(id, slot)
  local r = cmd_remove_awakening(slot or 1)
  if r == "none" then return "none" end
  return cmd_add_awakening(id)
end

----------------------------------------------------------------
-- 技能 hook（GGGLHHH luaops.h kCdHookLua 移植）
--   1) 主动技能冷却：包全局 __slotGetSkillCooldownMul，在游戏原倍率上
--      再乘单位的 __sbSkillCdMul（存在阵容单位表上，跟存档一起保存）。
--   2) 被动技能参数：包 awakening.runtime，单位有覆盖表 __sbSkillRt 时
--      返回「原参数 + 覆盖」的副本（原表是同技能单位共用的，不能改）。
--      副本按（单位，原表，覆盖表）缓存；改设置时整张换新覆盖表，缓存失效。
--   两个 hook 都是「已包过就跳过」，修改器不开时没人包 = 原版。
----------------------------------------------------------------
local function install_skill_hooks()
  if not rawget(_G, "__sbUnitField") then
    rawset(_G, "__sbUnitField", function(x, key)
      if type(x) ~= "table" then return nil end
      local v = rawget(x, key)
      if v ~= nil then return v end
      -- 传进来的是战场单位：靠阵容单位的 allyRef 反查
      local bf = rawget(_G, "battlefield")
      for _, r in ipairs(bf and bf.rosterUnits or {}) do
        if r.allyRef == x then return r[key] end
      end
      return nil
    end)
  end
  local unitField = rawget(_G, "__sbUnitField")

  local H = rawget(_G, "__sbCdHook")
  local cur = rawget(_G, "__slotGetSkillCooldownMul")
  if type(cur) == "function" and not (type(H) == "table" and H.wrapper == cur) then
    local orig = cur
    H = { orig = orig }
    function H.wrapper(x, ...)
      local m = orig(x, ...)
      local k = tonumber(unitField(x, "__sbSkillCdMul"))
      if k and type(m) == "number" then m = m * k end
      return m
    end
    rawset(_G, "__sbCdHook", H)
    rawset(_G, "__slotGetSkillCooldownMul", H.wrapper)
  end

  local A = package.loaded["src.game.awakening"]
  local R = rawget(_G, "__sbRtHook")
  if type(A) == "table" and type(A.runtime) == "function" and not (type(R) == "table" and R.wrapper == A.runtime) then
    local orig = A.runtime
    R = { orig = orig, cache = setmetatable({}, { __mode = "k" }) }
    function R.wrapper(x, ...)
      local r = orig(x, ...)
      local ov = unitField(x, "__sbSkillRt")
      if type(ov) ~= "table" or type(r) ~= "table" or next(ov) == nil then return r end
      local c = R.cache[x]
      if c and c.base == r and c.ov == ov then return c.value end
      local v = {}
      for k, val in pairs(r) do v[k] = val end
      for k, val in pairs(ov) do v[k] = val end
      R.cache[x] = { base = r, ov = ov, value = v }
      return v
    end
    rawset(_G, "__sbRtHook", R)
    A.runtime = R.wrapper
  end
end

-- 技能信息（GGGLHHH unitlevel.cpp kSkillInfoLua 移植）：
--   主动："active|名字|基础秒|总倍率|游戏原倍率|是否自定义"
--   被动："passive|名字|key:原值:现值;..."
--   无技能："none"
local function skill_info_string()
  local u = resolve_unit()
  if not u then return nil end
  local ok, info = pcall(function()
    local S = require("src.data.skill")
    local ok2, list = pcall(S.getSkillsForUnit, u)
    if not ok2 or type(list) ~= "table" or #list == 0 then return "none" end
    local Lang = require("src.data.language")
    local loc = Lang[rawget(_G, "currentGameLang") or "zh"] or Lang.zh or {}
    local function nm(d)
      return (loc["skill.name." .. tostring(d.id)] or tostring(d.name or d.id)):gsub("[|=\n]", "/")
    end
    for _, d in ipairs(list) do
      local base = tonumber(d.runtime and d.runtime.cooldown) or tonumber(d.cooldown)
      if d.activationType == "active" and base and base > 0 then
        local H = rawget(_G, "__sbCdHook")
        local f = rawget(_G, "__slotGetSkillCooldownMul")
        local mul = type(f) == "function" and tonumber(f(u)) or 1
        local nat = type(H) == "table" and tonumber(H.orig(u)) or mul
        return "active|" .. nm(d) .. "|" .. tostring(base) .. "|" .. tostring(mul) .. "|" .. tostring(nat) .. "|" ..
          (u.__sbSkillCdMul and "1" or "0")
      end
    end
    local d = list[1]
    local rt = type(d.runtime) == "table" and d.runtime or {}
    local ov = type(u.__sbSkillRt) == "table" and u.__sbSkillRt or {}
    local ps = {}
    for _, k in ipairs({ "charges", "chance", "internalCooldown" }) do
      local base = tonumber(rt[k])
      if base then ps[#ps + 1] = k .. ":" .. tostring(base) .. ":" .. tostring(tonumber(ov[k]) or base) end
    end
    return "passive|" .. nm(d) .. "|" .. table.concat(ps, ";")
  end)
  if not ok or type(info) ~= "string" then return "none" end
  return info
end

-- 主动技能冷却改成 seconds 秒（最短 0.1 秒；seconds < 0 = 恢复原版）。
-- GGGLHHH unitlevel.cpp SetSkillCooldown 移植：
-- 按「想要的秒数 ÷ (基础 × 游戏原倍率)」算出 __sbSkillCdMul 存在单位上。
local function cmd_set_skill_cd(seconds)
  local u = resolve_unit()
  if not u then return "none" end
  install_skill_hooks()
  local H = rawget(_G, "__sbCdHook")
  if type(H) ~= "table" then return "no_hook" end
  if seconds == nil or seconds < 0 then
    u.__sbSkillCdMul = nil
  else
    local base = nil
    pcall(function()
      local S = require("src.data.skill")
      local ok, list = pcall(S.getSkillsForUnit, u)
      if ok and type(list) == "table" then
        for _, d in ipairs(list) do
          local b = tonumber(d.runtime and d.runtime.cooldown) or tonumber(d.cooldown)
          if d.activationType == "active" and b and b > 0 then base = b break end
        end
      end
    end)
    if not base then return "no_skill" end
    local s = math.max(0.1, seconds)
    local nat = tonumber(H.orig(u)) or 1
    local m = s / (base * nat)
    if math.abs(m - 1) < 0.0005 then u.__sbSkillCdMul = nil else u.__sbSkillCdMul = m end
  end
  -- 战斗中：让游戏按新倍率重算战场单位的 skill.cd，剩余冷却不超过新冷却
  local a = live_ally(u)
  if a and type(a.skill) == "table" then
    local apply = rawget(_G, "__slotApplySkillCooldownOption")
    if type(apply) == "function" then pcall(apply, a) end
    local cd = tonumber(a.skill.cd)
    if cd and tonumber(a.skill.cdT) and a.skill.cdT > cd then a.skill.cdT = cd end
  end
  return "ok"
end

-- 被动技能触发条件（GGGLHHH unitlevel.cpp SetSkillParam 移植）：
-- 整张换新覆盖表（awakening.runtime 包装按覆盖表身份缓存副本，换表 = 缓存失效）。
-- field = "charges" / "chance" / "internalCooldown"；value = nil 时恢复原版。
local function cmd_set_passive(field, value)
  local u = resolve_unit()
  if not u then return "none" end
  if type(field) ~= "string" or field == "" then return "no_field" end
  install_skill_hooks()
  local ov = {}
  if type(u.__sbSkillRt) == "table" then for k, v in pairs(u.__sbSkillRt) do ov[k] = v end end
  if value == nil then ov[field] = nil else ov[field] = value end
  u.__sbSkillRt = next(ov) and ov or nil
  return "ok"
end

----------------------------------------------------------------
-- 核心添加（老虎机）
----------------------------------------------------------------
-- 中文名：从游戏 chinese.json 的 core.name.<key> 抽出（48 条，固定表，不依赖运行时语言）
local CORE_ZH = {
  ["01"] = "扭曲之铃",
  ["02"] = "双重账本",
  ["03"] = "双生樱桃",
  ["04"] = "禁用印章",
  ["05"] = "钱袋",
  ["06"] = "幸运钉",
  ["07"] = "X2",
  ["08"] = "回声之镜",
  ["09"] = "贪心之尾",
  ["10"] = "佣兵契约书",
  ["11"] = "养分叶",
  ["12"] = "旧王冠",
  ["13"] = "小丑种子",
  ["14"] = "残破音符",
  ["15"] = "血脉封印",
  ["16"] = "倒转时钟",
  ["17"] = "复制菇",
  ["18"] = "回声灯笼",
  ["19"] = "黑色音符",
  ["20"] = "共鸣铁砧",
  ["21"] = "交错尖牙",
  ["22"] = "万能牌",
  ["23"] = "黄金拉杆",
  ["24"] = "魔法神灯",
  ["25"] = "捣蛋鬼的魔方",
  ["26"] = "命运之锤",
  ["27"] = "女巫火炬",
  ["28"] = "贪婪圣杯",
  ["29"] = "小丑的微笑",
  ["30"] = "四叶草",
  ["31"] = "金牙",
  ["32"] = "回声之壳",
  ["33"] = "共鸣镜",
  ["34"] = "备用电池",
  ["35"] = "反动轴",
  ["36"] = "逆转轴",
  ["37"] = "循环之铃",
  ["38"] = "贪婪之珠",
  ["39"] = "小丑蜡烛",
  ["40"] = "黄金纹章",
  ["41"] = "火辣辣椒",
  ["42"] = "预知手镜",
  ["43"] = "爆破矿车",
  ["44"] = "上升羽毛",
  ["45"] = "孢子蘑菇",
  ["46"] = "纵火犯的打火机",
  ["47"] = "火药桶",
  ["48"] = "爆爆莓",
}

-- 核心是"本局拥有"的运行时列表（cores.getActive()），不是永久解锁：
--   getById(id) -> 定义表；select(def, wave) 把核心塞进当前 run；isOwned(def) 查重。
-- 真机实测：循环 select 后 getActive() 从 0 变成 48，老虎机里立即可用。
-- duration=0 的核心 expiryWave=inf，传 1 即可；有 duration 的按当前波数算。
local function current_wave()
  local w = 1
  pcall(function()
    local q = require("src.game.quest")
    if type(q.currentWave) == "function" then w = tonumber(q.currentWave()) or 1 end
  end)
  return w
end

local function cmd_core_add(id)
  local ok, cores = pcall(require, "src.game.cores")
  if not ok or type(cores) ~= "table" or type(cores.getById) ~= "function" then return "no_module" end
  local d = cores.getById(id)
  if type(d) ~= "table" then return "no_core" end
  if type(cores.isOwned) == "function" and cores.isOwned(d) then return "owned" end
  local ok2, err = pcall(cores.select, d, current_wave())
  if not ok2 then return "fail:" .. tostring(err) end
  cores_wiped = false
  return "ok"
end

local function cmd_core_add_all()
  local ok, cores = pcall(require, "src.game.cores")
  if not ok or type(cores) ~= "table" or type(cores.getIds) ~= "function" then return "no_module" end
  local w = current_wave()
  local n = 0
  for _, id in ipairs(cores.getIds() or {}) do
    local d = cores.getById(id)
    if type(d) == "table" and not (type(cores.isOwned) == "function" and cores.isOwned(d)) then
      if pcall(cores.select, d, w) then n = n + 1 end
    end
  end
  cores_wiped = false
  return "ok:" .. tostring(n)
end

-- 一键清除所有核心：逐个 remove 当前已激活的核心
local function cores_remove_all()
  local ok, cores = pcall(require, "src.game.cores")
  if not ok or type(cores) ~= "table" or type(cores.getActive) ~= "function" then return -1 end
  local snapshot = {}
  for _, c in ipairs(cores.getActive() or {}) do snapshot[#snapshot + 1] = c end
  local removed = 0
  for _, c in ipairs(snapshot) do
    if type(cores.remove) == "function" and pcall(cores.remove, c) then removed = removed + 1 end
  end
  return removed
end

local function cmd_cores_clear()
  local ok, cores = pcall(require, "src.game.cores")
  if not ok or type(cores) ~= "table" then return "no_module" end
  if type(cores.getActive) ~= "function" then return "no_api" end
  local removed = cores_remove_all()
  if removed < 0 then return "no_module" end
  cores_wiped = true   -- 之后 2Hz 持续压制，直到「添加核心」或「一键恢复」
  if removed == 0 and type(cores.reset) == "function" then
    pcall(cores.reset)
    return "reset"
  end
  return "ok:" .. tostring(removed)
end

local function core_count()
  local n, total = 0, 0
  pcall(function()
    local cores = require("src.game.cores")
    total = #(cores.getIds() or {})
    n = #(cores.getActive() or {})
  end)
  return n, total
end

----------------------------------------------------------------
-- 目录写回
----------------------------------------------------------------
local function clean(s)
  return (tostring(s or ""):gsub("[\t\n\r]", " "))
end

local function write_catalog()
  local ok_ro, RO = pcall(require, "src.data.randomoption")
  local ok_c, C = pcall(require, "src.data.constants")
  local ok_i, I = pcall(require, "src.game.item")
  local Lang = require("src.data.language")
  local loc = Lang[rawget(_G, "currentGameLang") or "zh"] or Lang.zh or {}
  local lines = {}
  if ok_ro and RO.catalog then
    lines[#lines + 1] = "[options]"
    for _, d in ipairs(RO.catalog) do
      local id = tostring(d.id)
      lines[#lines + 1] = id .. "\t" .. clean(loc["random_option.name." .. id] or d.name or id)
    end
  end
  if ok_c and C.imprint and C.imprint.definitions then
    lines[#lines + 1] = "[imprints]"
    for id, d in pairs(C.imprint.definitions) do
      lines[#lines + 1] = tostring(id) .. "\t" .. clean(loc["imprint.name." .. tostring(id)] or d.name or id) .. "\t" .. tostring(#(d.levels or {}))
    end
  end
  if ok_i and I.getAll then
    lines[#lines + 1] = "[items]"
    for _, d in ipairs(I.getAll()) do
      local id = tostring(d.id)
      lines[#lines + 1] = id .. "\t" .. clean(loc["item.name." .. id] or d.name or id) .. "\t" .. tostring(math.max(1, math.floor(tonumber(d.maxLevel) or 1)))
    end
  end
  -- 核心目录：老虎机页的滚轮用（id / 名字 / 稀有度）
  pcall(function()
    local cores = require("src.game.cores")
    if type(cores.getIds) ~= "function" then return end
    lines[#lines + 1] = "[cores]"
    for _, id in ipairs(cores.getIds() or {}) do
      local d = cores.getById(id)
      if type(d) == "table" then
        local nm = CORE_ZH[tostring(id)] or loc["core.name." .. tostring(d.key or "")] or d.name or d.key or tostring(id)
        local owned = 0
        if type(cores.isOwned) == "function" then
          local okOwn, o = pcall(cores.isOwned, d)
          if okOwn and o then owned = 1 end
        end
        lines[#lines + 1] = tostring(id) .. "\t" .. clean(nm) .. "\t" .. clean(d.rarity or "?") .. "\t" .. tostring(owned)
      end
    end
  end)
  -- 觉醒目录是按选中单位的职业来的（GGGLHHH awakening.cpp）：
  -- 本职业候选池 A.pool(u) + 已选的，名字按觉醒版本取本地化。
  pcall(function()
    local u = resolve_unit()
    if not u then return end
    local A = require("src.game.awakening")
    local okPool, pool = pcall(A.pool, u)
    local okCat, cat = pcall(A.catalog, u)
    local cands = okCat and type(cat) == "table" and cat.candidates or {}
    pool = okPool and type(pool) == "table" and pool or {}
    local aw = type(u.awakening) == "table" and u.awakening or {}
    local ver = tonumber(aw.version or u.awakeningVersion) or 10
    local listed = {}
    lines[#lines + 1] = "[awakenings]"
    local function emit(id)
      id = tostring(id)
      if listed[id] then return end
      listed[id] = true
      local c = cands[id] or {}
      local pre = "awakening." .. ver .. "." .. id
      lines[#lines + 1] = id .. "\t" .. clean(loc[pre .. ".name"] or c.name or id) .. "\t5"
    end
    for _, id in ipairs(pool) do emit(id) end
    local sel = type(aw.selected) == "table" and aw.selected or {}
    for _, id in ipairs(sel) do emit(id) end
  end)
  pcall(love.filesystem.write, "cheats_catalog.txt", table.concat(lines, "\n"))
end

----------------------------------------------------------------
-- 状态写回
----------------------------------------------------------------
local status_extra = nil
local function write_status(extra)
  if type(extra) == "table" then status_extra = extra end
  local coins = rawget(_G, "coins")
  local spins = rawget(_G, "spinsLeft")
  local jungsu = rawget(_G, "jungsu")
  local jb = jungsu
  pcall(function()
    local ui = rawget(_G, "ui")
    if type(ui) == "table" and type(ui.jungsuBalance) == "number" then jb = ui.jungsuBalance end
  end)
  local orig = get_originite()
  local core_n, core_total = core_count()
  local lines = {
    "return {",
    "  coins = " .. tostring(type(coins) == "number" and coins or 0) .. ",",
    "  spins = " .. tostring(type(spins) == "number" and spins or 0) .. ",",
    "  jungsu = " .. tostring(type(jungsu) == "number" and jungsu or 0) .. ",",
    "  jungsuBalance = " .. tostring(type(jb) == "number" and jb or 0) .. ",",
    "  originite = " .. tostring(type(orig) == "number" and orig or 0) .. ",",
    "  cores = " .. tostring(core_n) .. ",",
    "  coresTotal = " .. tostring(core_total) .. ",",
  }
  local sk = skill_info_string()
  if sk then
    lines[#lines + 1] = "  skill = \"" .. sk .. "\","
  end
  local u = resolve_unit()
  if u then
    lines[#lines + 1] = "  imprint_slots = " .. tostring(tonumber(u.maxImprintSlots) or 0) .. ","
    -- 选中单位信息每秒都写，面板才能实时刷新（原来只有 cmd_unit_info 时才写，
    -- 所以在游戏里换单位面板一直"没反应"）
    local E = {}
    pcall(function() E = require("src.data.constants").evolution or {} end)
    local maxR = (E.maxRankByGrade and u.grade and E.maxRankByGrade[u.grade]) or 3
    local sym = tostring(u.sym or u.id or "?")
    lines[#lines + 1] = string.format('  unit = "%s",', sym)
    lines[#lines + 1] = string.format('  unit_grade = "%s",', tostring(u.grade or ""))
    lines[#lines + 1] = "  unit_rank = " .. tostring(tonumber(u.rank) or 1) .. ","
    lines[#lines + 1] = "  unit_absorb = " .. tostring(tonumber(u.absorbLV) or 1) .. ","
    lines[#lines + 1] = "  unit_maxrank = " .. tostring(maxR) .. ","
  else
    lines[#lines + 1] = '  unit = "none",'
  end
  if status_extra then
    for k, v in pairs(status_extra) do
      lines[#lines + 1] = "  " .. k .. " = " .. tostring(v) .. ","
    end
  end
  lines[#lines + 1] = "}"
  pcall(love.filesystem.write, "cheats_status.lua", table.concat(lines, "\n"))
end

local function cmd_unit_info()
  local u = resolve_unit()
  if not u then
    write_status({ unit = "\"none\"" })
    return "none"
  end
  local E = require("src.data.constants").evolution or {}
  local maxR = E.maxRankByGrade and E.maxRankByGrade[u.grade] or 3
  write_status({
    unit = string.format("\"%s\"", tostring(u.sym or "?")),
    unit_grade = string.format("\"%s\"", tostring(u.grade or "")),
    unit_rank = tostring(u.rank or 1),
    unit_absorb = tostring(u.absorbLV or 1),
    unit_maxrank = tostring(maxR),
  })
  return "ok"
end

----------------------------------------------------------------
-- 抽奖页 / 开关页（14 项）/ 存档页
----------------------------------------------------------------
local function CN() return package.loaded["src.data.constants"] end
local function CO() return package.loaded["src.game.cores"] end
local function ST() return package.loaded["src.game.stone"] end
local function UP() return package.loaded["src.ui.upgrade"] end

local SYM_ORDER = { "A", "D", "H", "M", "S", "W" }
local SYM_ORIG = setmetatable({}, { __mode = "k" })
local GRADE_ORDER = { "normal", "advanced", "rare", "legendary", "prism" }
local GRADE_BASE = { normal = 0.80, advanced = 0.15, rare = 0.045, legendary = 0.004, prism = 0.001 }
local LUCK_MUL = {
  { normal = 1, advanced = 2, rare = 5, legendary = 12, prism = 30 },
  { normal = 0.5, advanced = 3, rare = 10, legendary = 35, prism = 120 },
}
local prob_snap, spin_snap, spin_cost_orig = nil, nil, nil
local wrap_mode, joker_applied, jester_on = nil, 0, false
local last_wave, last_spins_in_wave = nil, nil

-- 符号权重：游戏有两份表，只改一份会被另一份覆盖
local function sym_tables()
  local t = {}
  local c = CN()
  if c and c.slot and type(c.slot.symbolWeights) == "table" then t[#t + 1] = c.slot.symbolWeights end
  local co = CO()
  if co and type(co.MERC_CONTRACT_SYMBOL_WEIGHTS) == "table" then t[#t + 1] = co.MERC_CONTRACT_SYMBOL_WEIGHTS end
  return t
end

local function apply_symbol_lock(idx)
  idx = tonumber(idx) or 0
  local pick = SYM_ORDER[idx]
  for _, w in ipairs(sym_tables()) do
    if not SYM_ORIG[w] then
      local o = {}
      for _, k in ipairs(SYM_ORDER) do o[k] = w[k] end
      SYM_ORIG[w] = o
    end
    if pick then
      for _, k in ipairs(SYM_ORDER) do w[k] = (k == pick) and 1 or 0 end
    else
      local o = SYM_ORIG[w]
      for _, k in ipairs(SYM_ORDER) do w[k] = o[k] end
    end
  end
  return idx
end

local function prob_table() 
  local c = CN()
  return c and c.unitGrades and c.unitGrades.probabilities or nil
end

local function snapshot_probs()
  if prob_snap then return prob_snap end
  local s = { unit = {}, stone = {} }
  local p = prob_table()
  if type(p) == "table" then for k, v in pairs(p) do s.unit[k] = v end end
  local st = ST()
  if st and type(st.defs) == "table" then
    for id, d in pairs(st.defs) do
      if type(d) == "table" and type(d.probs) == "table" then
        local c = {}
        for k, v in pairs(d.probs) do c[k] = v end
        s.stone[id] = c
      end
    end
  end
  prob_snap = s
  return s
end

local function restore_probs()
  local s = prob_snap
  if not s then return end
  local p = prob_table()
  if type(p) == "table" then for k, v in pairs(s.unit) do p[k] = v end end
  local st = ST()
  if st and type(st.defs) == "table" then
    for id, d in pairs(st.defs) do
      local c = s.stone[id]
      if type(d) == "table" and type(c) == "table" and type(d.probs) == "table" then
        for k, v in pairs(c) do d.probs[k] = v end
      end
    end
  end
end

local function grade_weights(lock, tier)
  lock = tonumber(lock) or 0
  tier = tonumber(tier) or 0
  local w = {}
  if lock >= 1 and lock <= 5 then
    for i, g in ipairs(GRADE_ORDER) do w[g] = (i == lock) and 1 or 0 end
    return w, "lock"
  end
  if tier == 3 then                       -- 均衡：五项等概率
    for _, g in ipairs(GRADE_ORDER) do w[g] = 0.2 end
    return w, "even"
  end
  if tier >= 1 and tier <= 2 then
    local mul, sum = LUCK_MUL[tier], 0
    for _, g in ipairs(GRADE_ORDER) do
      local v = (GRADE_BASE[g] or 0) * (mul[g] or 1)
      w[g] = v; sum = sum + v
    end
    if sum > 0 then for _, g in ipairs(GRADE_ORDER) do w[g] = w[g] / sum end end
    return w, "tier"
  end
  return nil, "off"
end

local function apply_grade_lock(lock, tier)
  local w, mode = grade_weights(lock, tier)
  if not w then
    restore_probs()
    return "off"
  end
  snapshot_probs()
  local p = prob_table()
  if type(p) == "table" then
    local total = 0
    for _, g in ipairs(GRADE_ORDER) do total = total + (w[g] or 0) end
    for g, v in pairs(w) do p[g] = v end
    if p.special ~= nil then p.special = 0 end
  end
  local st = ST()
  if st and type(st.defs) == "table" then
    for _, d in pairs(st.defs) do
      if type(d) == "table" and type(d.probs) == "table" then
        for g, v in pairs(w) do d.probs[g] = v end
      end
    end
  end
  return mode
end

-- 每波抽奖次数
local function spin_econ()
  local c = CN()
  return c and c.economy and c.economy.spins or nil
end

local function apply_spin_wave(n)
  n = tonumber(n) or 0
  local e = spin_econ()
  if type(e) == "table" then
    if not spin_snap then
      spin_snap = { freePerWave = e.freePerWave, paidMaxPerWave = e.paidMaxPerWave }
    end
    if n <= 0 then
      e.freePerWave = spin_snap.freePerWave
      e.paidMaxPerWave = spin_snap.paidMaxPerWave
      last_wave, last_spins_in_wave = nil, nil
      return 0
    end
    local paids = tonumber(spin_snap.paidMaxPerWave) or 3
    local paid = n < paids and n or paids
    e.paidMaxPerWave = paid
    e.freePerWave = n - paid
  end
  if n <= 0 then return 0 end
  -- 换波时把剩余次数抬到目标值（游戏换波只给默认次数）
  local bf = rawget(_G, "battlefield")
  local w = (type(bf) == "table" and tonumber(bf.waveId)) or 0
  local si = tonumber(rawget(_G, "spinsInWave")) or 0
  local new_wave = (w > 0 and w ~= last_wave) or (last_spins_in_wave and last_spins_in_wave > 0 and si == 0)
  last_wave, last_spins_in_wave = w, si
  if new_wave then
    local left = tonumber(rawget(_G, "spinsLeft")) or 0
    if left < n then rawset(_G, "spinsLeft", n) end
  end
  return 1
end

-- 小丑核心（bit 1/2/4/8 → 13 种子 / 22 百搭 / 4 黑签 / 29 丑的微笑）
local JOKER_DEFS = {
  { bit = 1, id = "13", name = "小丑种子" },
  { bit = 2, id = "22", name = "百搭小丑" },
  { bit = 4, id = "4",  name = "黑签" },
  { bit = 8, id = "29", name = "丑的微笑" },
}

local function joker_def(id)
  local co = CO()
  if not co or type(co.getById) ~= "function" then return nil end
  local ok, d = pcall(co.getById, id)
  if ok and type(d) == "table" then return d end
  return nil
end

local function has_joker(id)
  local co = CO()
  if not co then return false end
  local list = nil
  if type(co.getActive) == "function" then
    local ok, v = pcall(co.getActive)
    if ok then list = v end
  end
  if type(list) ~= "table" then return false end
  for _, item in pairs(list) do
    local iid = type(item) == "table" and (item.id or item.coreId or item.key) or item
    if tostring(iid) == tostring(id) then return true end
    if type(item) == "table" and item.def and tostring(item.def.id) == tostring(id) then return true end
  end
  return false
end

local function apply_joker(bits)
  bits = tonumber(bits) or 0
  local co = CO()
  if not co then return 0 end
  for _, d in ipairs(JOKER_DEFS) do
    local want = (bits % (d.bit * 2)) >= d.bit
    local have = has_joker(d.id)
    local def = joker_def(d.id)
    if want and not have then
      if def and type(co.select) == "function" then pcall(co.select, def) end
    elseif (not want) and have then
      local key = def and def.key or nil
      if key and type(co.remove) == "function" then pcall(co.remove, key) end
    end
  end
  return bits
end

-- 直接把战场单位换成小丑（记原值，关掉能还原）
local JESTER_KEY = "Jester"
local JESTER_STATS = { hp = 90, atk = 32, distance = 20, aspd = 1.4 }

local function apply_jester(on)
  local bf = rawget(_G, "battlefield")
  local r = type(bf) == "table" and bf.rosterUnits or nil
  if type(r) ~= "table" then return 0 end
  local n = 0
  for i = 1, #r do
    local u = r[i]
    if type(u) == "table" then
      if on then
        if u.subclass ~= JESTER_KEY then
          u._sbOrigSubclass = u._sbOrigSubclass or u.subclass
          u.subclass, u.subclassKey, u.subclassName = JESTER_KEY, JESTER_KEY, JESTER_KEY
          local st = u.stats
          if type(st) == "table" then
            if not u._sbOrigStats then
              u._sbOrigStats = { hp = st.hp, atk = st.atk, distance = st.distance, aspd = st.aspd }
            end
            st.hp, st.atk, st.distance, st.aspd = JESTER_STATS.hp, JESTER_STATS.atk, JESTER_STATS.distance, JESTER_STATS.aspd
          end
          n = n + 1
        end
      elseif u._sbOrigSubclass then
        local k = u._sbOrigSubclass
        u.subclass, u.subclassKey, u.subclassName = k, k, k
        u._sbOrigSubclass = nil
        local b = u._sbOrigStats
        if b and type(u.stats) == "table" then
          u.stats.hp, u.stats.atk, u.stats.distance, u.stats.aspd = b.hp, b.atk, b.distance, b.aspd
        end
        u._sbOrigStats = nil
        n = n + 1
      end
    end
  end
  return n
end

-- 升级加成：包 src/ui/upgrade 的取值函数（比直接改数值耐久，换关不丢）
local WRAP_ORIG = {}
local function wrap_set(name, fn)
  local up = UP()
  if not up or type(up[name]) ~= "function" then return end
  if not WRAP_ORIG[name] then WRAP_ORIG[name] = up[name] end
  up[name] = fn or WRAP_ORIG[name]
end

local function num(x)
  x = tonumber(x)
  return x or 0
end

local function apply_upgrade_wraps(start_bonus, speed, unit_cap, item_cap, shop_free)
  local mode = table.concat({ start_bonus and 1 or 0, num(speed), num(unit_cap), num(item_cap), shop_free and 1 or 0 }, ":")
  if mode == wrap_mode then return end
  wrap_mode = mode

  wrap_set("getStartGoldBonus", start_bonus and function(b, ...)
    local o = WRAP_ORIG.getStartGoldBonus
    return (o and (tonumber(o(b, ...)) or 0) or 0) + 500000
  end or nil)

  wrap_set("getBaseHPBonus", start_bonus and function(b, ...)
    local o = WRAP_ORIG.getBaseHPBonus
    return (o and (tonumber(o(b, ...)) or 0) or 0) + 900
  end or nil)

  wrap_set("getCoreFreeRerollBonus", start_bonus and function(b, ...)
    local o = WRAP_ORIG.getCoreFreeRerollBonus
    return (o and (tonumber(o(b, ...)) or 0) or 0) + 99
  end or nil)

  local sp = num(speed)
  wrap_set("getBattleSpeedMultiplier", sp > 0 and function(...) return sp end or nil)

  local uc = num(unit_cap)
  local uc_orig = WRAP_ORIG.getMaxUnitBonus
  wrap_set("getMaxUnitBonus", uc > 0 and function(b, ...)
    local v = uc_orig and (tonumber(uc_orig(b, ...)) or 0) or 0
    return uc > v and uc or v
  end or nil)

  local ic = num(item_cap)
  local ic_orig = WRAP_ORIG.getItemInventoryAdd
  wrap_set("getItemInventoryAdd", ic > 0 and function(b, ...)
    local v = ic_orig and (tonumber(ic_orig(b, ...)) or 0) or 0
    return ic > v and ic or v
  end or nil)

  wrap_set("getShopFirstRerollDiscount", shop_free and function(...) return 99 end or nil)
  wrap_set("getQuestRerollEnabled", shop_free and function(...) return true end or nil)
end

-- 开关页 14 项：能锁的每帧补（抗结算扣减），能包的走 wraps
local function apply_locks()
  if cfg.coins_lock == 1 then
    local t = num(cfg.coins_value); if t <= 0 then t = 9999999 end
    local cur = rawget(_G, "coins")
    if type(cur) == "number" and cur < t then rawset(_G, "coins", t) end
  end
  if cfg.free_spin == 1 then
    local sc = rawget(_G, "spinCost")
    if type(sc) == "number" then
      if spin_cost_orig == nil then spin_cost_orig = sc end
      if sc ~= 0 then rawset(_G, "spinCost", 0) end
    end
  elseif spin_cost_orig then
    rawset(_G, "spinCost", spin_cost_orig)
    spin_cost_orig = nil
  end
  local slot = rawget(_G, "slot")
  if (cfg.force_win == 1 or cfg.hero_always == 1) and type(slot) == "table" then
    if slot.forceWinOnce ~= true then slot.forceWinOnce = true end
  elseif type(slot) == "table" and slot.forceWinOnce == true then
    slot.forceWinOnce = false
  end
  if cfg.reroll_lock == 1 then
    local v = rawget(_G, "coreFreeRerollsRemaining")
    if type(v) == "number" and v < 99 then rawset(_G, "coreFreeRerollsRemaining", 99) end
  end
  if cfg.freespin_lock == 1 then
    local v = rawget(_G, "freeSpinCredits")
    if type(v) == "number" and v < 99 then rawset(_G, "freeSpinCredits", 99) end
  end
  if cfg.basehp_lock == 1 then
    local bf = rawget(_G, "battlefield")
    local t = num(cfg.basehp_value); if t <= 0 then t = 999 end
    if type(bf) == "table" and type(bf.baseHP) == "number" and bf.baseHP < t then bf.baseHP = t end
  end
  if cfg.spins_lock == 1 then
    local t = num(cfg.spins_value); if t <= 0 then t = 99 end
    local v = rawget(_G, "spinsLeft")
    if type(v) == "number" and v < t then rawset(_G, "spinsLeft", t) end
  end
  if cfg.jungsu_lock == 1 then
    local v = rawget(_G, "jungsu")
    if type(v) == "number" and v < 9999 then set_jungsu(9999) end
  end
end

-- 抽奖页里需要按配置切换的部分（2Hz 足够，不必每帧）
local function apply_draw_page()
  apply_symbol_lock(cfg.sym_lock)
  if cfg.grade_lock ~= nil or cfg.luck_tier ~= nil then
    apply_grade_lock(cfg.grade_lock, cfg.luck_tier)
  end
  apply_spin_wave(cfg.spins_wave)
  local jb = tonumber(cfg.joker_bits) or 0
  if jb ~= joker_applied then
    joker_applied = jb
    apply_joker(jb)
  end
  local jh = (tonumber(cfg.jester_hero) or 0) ~= 0
  if jh ~= jester_on then
    jester_on = jh
    apply_jester(jh)
  elseif jh then
    apply_jester(true)
  end
  apply_upgrade_wraps(cfg.start_bonus == 1, cfg.speed_mul, cfg.unit_cap, cfg.item_cap, cfg.shop_free == 1)
end

----------------------------------------------------------------
-- 存档页
----------------------------------------------------------------
local SAVE_FILES = { "save.dat", "save_fallback.dat" }

local function file_exists(n)
  local ok, info = pcall(love.filesystem.getInfo, n)
  return ok and info ~= nil
end

local function copy_file(a, b)
  local ok, data = pcall(love.filesystem.read, a)
  if not ok or not data then return false end
  return (pcall(love.filesystem.write, b, data))
end

local function cmd_save_now()
  local ok = pcall(function() require("src.save").save() end)
  return ok and "ok" or "fail"
end

local function cmd_save_backup()
  local n = 0
  for _, f in ipairs(SAVE_FILES) do
    if file_exists(f) and copy_file(f, f .. ".sb_bak") then n = n + 1 end
  end
  return n > 0 and ("ok:" .. n) or "fail"
end

local function cmd_save_restore()
  local n = 0
  for _, f in ipairs(SAVE_FILES) do
    if file_exists(f .. ".sb_bak") and copy_file(f .. ".sb_bak", f) then n = n + 1 end
  end
  return n > 0 and ("ok:" .. n) or "fail"
end

local function cmd_reset_all()
  cfg.coins_lock, cfg.free_spin, cfg.force_win, cfg.hero_always = 0, 0, 0, 0
  cfg.basehp_lock, cfg.spins_lock, cfg.reroll_lock, cfg.freespin_lock = 0, 0, 0, 0
  cfg.jungsu_lock, cfg.start_bonus, cfg.unit_cap, cfg.item_cap = 0, 0, 0, 0
  cfg.shop_free, cfg.speed_mul = 0, 0
  cfg.sym_lock, cfg.grade_lock, cfg.luck_tier, cfg.spins_wave = 0, 0, 0, 0
  cfg.joker_bits, cfg.jester_hero = 0, 0
  pcall(apply_symbol_lock, 0)
  pcall(restore_probs)
  pcall(apply_spin_wave, 0)
  pcall(apply_jester, false)
  pcall(apply_upgrade_wraps, false, 0, 0, 0, false)
  wrap_mode = nil
  cores_wiped = false
  -- 面板加过的物品也一并撤掉（含落盘记录）
  injected_items = {}
  pcall(injected_save)
  local slot = rawget(_G, "slot")
  if type(slot) == "table" then slot.forceWinOnce = false end
  if spin_cost_orig then rawset(_G, "spinCost", spin_cost_orig); spin_cost_orig = nil end
  return "ok"
end

----------------------------------------------------------------
-- 命令分发
----------------------------------------------------------------
local commands = {
  catalog = function() catalog_dirty = true return "ok" end,
  add_option = function() return cmd_add_option(cfg.arg) end,
  remove_option = function() return cmd_remove_option(cfg.arg) end,
  replace_option = function() return cmd_replace_option(cfg.arg, cfg.arg2) end,
  add_imprint = function() return cmd_add_imprint(cfg.arg, cfg.arg2) end,
  remove_imprint = function() return cmd_remove_imprint(cfg.arg) end,
  replace_imprint = function() return cmd_replace_imprint(cfg.arg, cfg.arg2) end,
  set_imprint_slots = function() return cmd_set_imprint_slots(cfg.arg) end,
  set_absorb_lv = function() return cmd_set_absorb_lv(cfg.arg) end,
  absorb_add = function() return cmd_absorb_add(cfg.arg) end,
  raise_rank = function() return cmd_raise_rank(cfg.arg) end,
  set_stat = function() return cmd_set_stat(cfg.arg, cfg.arg2, false) end,
  mul_stat = function() return cmd_set_stat(cfg.arg, cfg.arg2, true) end,
  add_item = function() return cmd_add_item(cfg.arg, cfg.arg2) end,
  remove_item = function() return cmd_remove_item(cfg.arg) end,
  replace_item = function() return cmd_replace_item(cfg.arg, cfg.arg2) end,
  items_all = function() return cmd_items_all(cfg.arg) end,
  core_add = function() return cmd_core_add(cfg.arg) end,
  core_add_all = function() return cmd_core_add_all() end,
  cores_clear = function() return cmd_cores_clear() end,
  items_clear = function() return cmd_items_clear() end,
  add_awakening = function() return cmd_add_awakening(cfg.arg) end,
  remove_awakening = function() return cmd_remove_awakening(cfg.arg) end,
  replace_awakening = function() return cmd_replace_awakening(cfg.arg, cfg.arg2) end,
  set_skill_cd = function() return cmd_set_skill_cd(cfg.arg) end,
  set_passive = function() return cmd_set_passive(cfg.arg, cfg.arg2) end,
  catalog = function() write_catalog() return "ok" end,
  unit_info = function() return cmd_unit_info() end,
  save_now = function() return cmd_save_now() end,
  save_backup = function() return cmd_save_backup() end,
  save_restore = function() return cmd_save_restore() end,
  reset_all = function() return cmd_reset_all() end,
}

local function run_command()
  local c = cfg.cmd
  if type(c) ~= "string" or c == "" then return end
  local fn = commands[c]
  if fn then
    local ok, ret = pcall(fn)
    dlog("cmd " .. c .. " arg=" .. tostring(cfg.arg) .. " arg2=" .. tostring(cfg.arg2)
      .. " -> " .. (ok and tostring(ret) or ("ERR " .. tostring(ret))))
  else
    dlog("cmd " .. c .. " -> unknown")
  end
end

----------------------------------------------------------------
-- 一次性字段
----------------------------------------------------------------
local function apply_once()
  -- 面板加的物品要顶住游戏的 restorePurchasedItems()：先载盘，再挂钩子，再补一次
  if not injected_loaded then
    injected_loaded = true
    pcall(injected_load)
  end
  pcall(injected_hook)
  if next(injected_items) ~= nil then pcall(injected_apply) end
  if type(cfg.seq) ~= "number" then cfg.seq = 0 end
  if cfg.seq == applied_seq then return end
  -- 首次读取时，磁盘上的旧配置是上一次运行留下的：一次性动作（run_lua/cmd/加核心/大奖）
  -- 必须丢弃，否则每次启动都会把“一键解锁”这类操作重放一遍
  if applied_seq == -1 then
    cfg.run_lua, cfg.cmd, cfg.arg, cfg.arg2 = nil, nil, nil, nil
    cfg.core_add, cfg.core_add_all, cfg.jackpot = 0, 0, false
    cfg.coins_set, cfg.coins_add, cfg.spins_set, cfg.spins_add = nil, 0, nil, 0
    cfg.jungsu_set, cfg.originite_set, cfg.originite_add = nil, nil, 0
  end
  applied_seq = cfg.seq

  if type(cfg.coins_set) == "number" then rawset(_G, "coins", cfg.coins_set) end
  if type(cfg.coins_add) == "number" and cfg.coins_add ~= 0 then
    local cur = rawget(_G, "coins")
    rawset(_G, "coins", (type(cur) == "number" and cur or 0) + cfg.coins_add)
  end
  if type(cfg.spins_set) == "number" then rawset(_G, "spinsLeft", cfg.spins_set) end
  if type(cfg.spins_add) == "number" and cfg.spins_add ~= 0 then
    local cur = rawget(_G, "spinsLeft")
    rawset(_G, "spinsLeft", (type(cur) == "number" and cur or 0) + cfg.spins_add)
  end
  if type(cfg.jungsu_set) == "number" then set_jungsu(cfg.jungsu_set) end
  if type(cfg.originite_set) == "number" then set_originite(cfg.originite_set) end
  if type(cfg.originite_add) == "number" and cfg.originite_add ~= 0 then
    local cur = get_originite()
    if type(cur) == "number" then set_originite(cur + cfg.originite_add) end
  end
  if tonumber(cfg.core_add) and tonumber(cfg.core_add) > 0 then
    cmd_core_add(math.floor(tonumber(cfg.core_add)))
  end
  if tonumber(cfg.core_add_all) and tonumber(cfg.core_add_all) > 0 then
    cmd_core_add_all()
  end
  if type(cfg.run_lua) == "string" and cfg.run_lua ~= "" then
    local fn = load_chunk(cfg.run_lua)
    if fn then pcall(fn) end
  end
  run_command()
end

local function apply_continuous()
  if type(cfg.lock_coins) == "number" then
    local cur = rawget(_G, "coins")
    if type(cur) == "number" and cur < cfg.lock_coins then rawset(_G, "coins", cfg.lock_coins) end
  end
  if type(cfg.lock_spins) == "number" then
    local cur = rawget(_G, "spinsLeft")
    if type(cur) == "number" and cur < cfg.lock_spins then rawset(_G, "spinsLeft", cfg.lock_spins) end
  end
  if type(cfg.lock_jungsu) == "number" then
    local cur = rawget(_G, "jungsu")
    if type(cur) == "number" and cur < cfg.lock_jungsu then set_jungsu(cfg.lock_jungsu) end
  end
  if type(cfg.lock_originite) == "number" then
    local cur = get_originite()
    if type(cur) == "number" and cur < cfg.lock_originite then set_originite(cfg.lock_originite) end
  end
  apply_locks()
end

----------------------------------------------------------------
-- 老虎机大奖
----------------------------------------------------------------
local function install_jackpot()
  local s = rawget(_G, "slot")
  if type(s) ~= "table" or type(s.buildResultGrid) ~= "function" then return end
  local scfg = rawget(_G, "__sbSlotCfg")
  if type(scfg) ~= "table" then scfg = {}; rawset(_G, "__sbSlotCfg", scfg) end
  scfg.jackpot = not not cfg.jackpot
  scfg.symbol = type(cfg.jackpot) == "string" and cfg.jackpot or nil
  local wrapped = rawget(_G, "__sbSlotWrapped")
  if type(wrapped) ~= "table" then wrapped = setmetatable({}, { __mode = "k" }); rawset(_G, "__sbSlotWrapped", wrapped) end
  if wrapped[s.buildResultGrid] then return end
  local orig = s.buildResultGrid
  local function w(self, ...)
    local g = orig(self, ...)
    local c = rawget(_G, "__sbSlotCfg")
    if c and c.jackpot and type(g) == "table" then
      local pick = c.symbol
      if pick == "random" or pick == nil or pick == false then
        local list = { "W", "A", "S", "M", "H", "D" }
        pick = list[math.random(#list)]
      end
      for r = 1, 3 do
        g[r] = g[r] or {}
        for col = 1, 3 do g[r][col] = pick end
      end
      c.hits = (c.hits or 0) + 1
    end
    return g
  end
  wrapped[w] = true
  s.buildResultGrid = w
end

----------------------------------------------------------------
-- 每帧入口 + 自己包 love.update（注入版，不改 main.lua）
----------------------------------------------------------------
function M.tick(dt)
  tune_gc()

  poll_t = poll_t + (dt or 0)
  if poll_t >= 0.5 then
    poll_t = 0
    load_cfg()
    -- 这两个原来每帧都调（内部才短路）；降到 2Hz，省每帧的表查找
    install_skill_hooks()
    install_jackpot()
    apply_draw_page()
    -- 面板加的物品每 0.5s 检查一次：游戏重建 _itemPurchased 后立刻补回
    if next(injected_items) ~= nil and injected_need() then pcall(injected_apply) end
    -- 「一键清除所有核心」之后持续压制，游戏重新灌 loadout 也会被清掉
    if cores_wiped then
      local r = cores_remove_all()
      if r and r > 0 then dlog("core wipe again " .. r) end
    end
  end

  apply_once()
  apply_continuous()

  local now = love.timer.getTime()
  alive_t = alive_t + (dt or 0)
  if alive_t >= 1.0 then
    alive_t = 0
    alive_now = panel_alive(now)
  end
  local alive = alive_now

  -- 目录：只有"需要写"且（面板在 / 还没写过）才序列化那 128 条
  catalog_t = catalog_t + (dt or 0)
  if catalog_dirty and (alive or not catalog_written) then
    catalog_dirty = false
    catalog_written = true
    catalog_t = 0
    pcall(write_catalog)
  elseif catalog_t >= 30 then
    -- 30 秒兜底：面板可能是后打开的
    catalog_t = 0
    if alive then catalog_dirty = true end
  end

  -- 状态：面板开着 1Hz，关着降到 0.125Hz（没人看就别写盘）
  status_t = status_t + (dt or 0)
  if status_t >= (alive and 1.0 or 8.0) then
    status_t = 0
    pcall(write_status)
  end

end

-- 包住 love.update：先跑游戏自己的 update，再跑 tick。
-- 只包一次（__sbUpdateWrapped 标记），避免重复包。
if not rawget(_G, "__sbUpdateWrapped") then
  local orig_update = love.update
  if type(orig_update) == "function" then
    love.update = function(dt)
      orig_update(dt)
      pcall(M.tick, dt)
    end
    rawset(_G, "__sbUpdateWrapped", true)
  end
end

-- 首次加载就写一份目录和状态，让面板立刻有数据。
pcall(write_catalog)
pcall(write_status)

return M
