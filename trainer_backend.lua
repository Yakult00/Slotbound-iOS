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
  jackpot = false, run_lua = nil,
  cmd = nil, arg = nil, arg2 = nil,
}
local applied_seq = -1
local last_content = nil
local poll_t = 0
local status_t = 0
local catalog_t = 0

----------------------------------------------------------------
-- 配置读取（dylib → 游戏）
----------------------------------------------------------------
local function load_cfg()
  local ok, content = pcall(love.filesystem.read, "cheats_ui.lua")
  if not ok or not content then return end
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

local function cmd_add_item(id, level)
  local ui = rawget(_G, "ui")
  if type(ui) ~= "table" then return "noui" end
  local I = require("src.game.item")
  local d = I.getById(id)
  if not d then return "no_id" end
  local maxL = math.max(1, math.floor(tonumber(d.maxLevel) or 1))
  local L = math.max(1, math.min(maxL, level or 1))
  ui._itemPurchased = ui._itemPurchased or {}
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
  local lines = {
    "return {",
    "  coins = " .. tostring(type(coins) == "number" and coins or 0) .. ",",
    "  spins = " .. tostring(type(spins) == "number" and spins or 0) .. ",",
    "  jungsu = " .. tostring(type(jungsu) == "number" and jungsu or 0) .. ",",
    "  jungsuBalance = " .. tostring(type(jb) == "number" and jb or 0) .. ",",
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
-- 命令分发
----------------------------------------------------------------
local commands = {
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
  items_clear = function() return cmd_items_clear() end,
  add_awakening = function() return cmd_add_awakening(cfg.arg) end,
  remove_awakening = function() return cmd_remove_awakening(cfg.arg) end,
  replace_awakening = function() return cmd_replace_awakening(cfg.arg, cfg.arg2) end,
  set_skill_cd = function() return cmd_set_skill_cd(cfg.arg) end,
  set_passive = function() return cmd_set_passive(cfg.arg, cfg.arg2) end,
  catalog = function() write_catalog() return "ok" end,
  unit_info = function() return cmd_unit_info() end,
}

local function run_command()
  local c = cfg.cmd
  if type(c) ~= "string" or c == "" then return end
  local fn = commands[c]
  if fn then pcall(fn) end
end

----------------------------------------------------------------
-- 一次性字段
----------------------------------------------------------------
local function apply_once()
  if type(cfg.seq) ~= "number" then cfg.seq = 0 end
  if cfg.seq == applied_seq then return end
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
  poll_t = poll_t + (dt or 0)
  if poll_t >= 0.5 then
    poll_t = 0
    load_cfg()
  end
  install_skill_hooks()
  apply_once()
  apply_continuous()
  install_jackpot()

  catalog_t = catalog_t + (dt or 0)
  if catalog_t >= 5.0 then
    catalog_t = 0
    pcall(write_catalog)
  end

  status_t = status_t + (dt or 0)
  if status_t >= 1.0 then
    status_t = 0
    write_status()
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
