-- Slotbound drop-rate game logic (v3). No LÖVE UI drawing here;
-- the UI is a native iOS overlay (UIKit) that calls the setters below.
local G = {}
G.grades = {
  { key = "normal",    label = "普通" },
  { key = "advanced",  label = "高级" },
  { key = "rare",      label = "稀有" },
  { key = "legendary", label = "传说" },
  { key = "prism",     label = "棱镜" },
}
G.classes = {
  { key = "A", label = "弓手" },
  { key = "D", label = "决斗者" },
  { key = "H", label = "骑兵" },
  { key = "M", label = "法师" },
  { key = "S", label = "枪兵" },
  { key = "W", label = "战士" },
}
G.grade_val = { normal = 100, advanced = 0, rare = 0, legendary = 0, prism = 0 }
G.class_val = { A = 1, D = 1, H = 1, M = 1, S = 1, W = 1 }
G.grade_pct = { normal = 1, advanced = 0, rare = 0, legendary = 0, prism = 0 }

local function cfg_path()
  return "drop_rates_ui.lua"
end

function G.load()
  local ok, chunk = pcall(love.filesystem.load, cfg_path())
  if ok and chunk then
    local ok2, tbl = pcall(chunk)
    if ok2 and type(tbl) == "table" then
      if type(tbl.grade) == "table" then
        for _, g in ipairs(G.grades) do
          local v = tonumber(tbl.grade[g.key])
          if v and v >= 0 and v <= 100 then G.grade_val[g.key] = v end
        end
      end
      if type(tbl.class) == "table" then
        for _, c in ipairs(G.classes) do
          local v = tonumber(tbl.class[c.key])
          if v and v >= 0 and v <= 5 then G.class_val[c.key] = v end
        end
      end
    end
  end
end

function G.save()
  local lines = { "return {", "  grade = {" }
  for _, g in ipairs(G.grades) do
    lines[#lines + 1] = "    " .. g.key .. " = " .. tostring(G.grade_val[g.key]) .. ","
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "  class = {"
  for _, c in ipairs(G.classes) do
    lines[#lines + 1] = "    " .. c.key .. " = " .. tostring(G.class_val[c.key]) .. ","
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "}"
  pcall(love.filesystem.write, cfg_path(), table.concat(lines, "\n"))
end

function G.class_mult(k)
  local v = G.class_val[k]
  if type(v) == "number" then return v end
  return 1
end

function G.apply_grades()
  local total = 0
  for _, g in ipairs(G.grades) do total = total + (G.grade_val[g.key] or 0) end
  for _, g in ipairs(G.grades) do
    if total > 0 then
      G.grade_pct[g.key] = (G.grade_val[g.key] or 0) / total
    else
      G.grade_pct[g.key] = (g.key == "normal") and 1 or 0
    end
  end
  local ok, constants = pcall(require, "src.data.constants")
  if ok and constants and constants.unitGrades and constants.unitGrades.probabilities then
    local p = constants.unitGrades.probabilities
    for _, g in ipairs(G.grades) do p[g.key] = G.grade_pct[g.key] end
    p.special = 0
  end
  G.save()
end

-- Setters called from the native (UIKit) overlay.
function SetDropGrade(key, pct)
  pct = tonumber(pct)
  if not pct then return false end
  if pct < 0 then pct = 0 end
  if pct > 100 then pct = 100 end
  if G.grade_val[key] == nil then return false end
  G.grade_val[key] = pct
  G.apply_grades()
  return true
end

function SetDropClass(key, mult)
  mult = tonumber(mult)
  if not mult then return false end
  if mult < 0 then mult = 0 end
  if mult > 5 then mult = 5 end
  if G.class_val[key] == nil then return false end
  G.class_val[key] = mult
  G.save()
  return true
end

function GetDropGrade(key)
  return G.grade_val[key]
end

function GetDropClass(key)
  return G.class_val[key]
end

function ResetDropRates()
  G.grade_val = { normal = 100, advanced = 0, rare = 0, legendary = 0, prism = 0 }
  G.class_val = { A = 1, D = 1, H = 1, M = 1, S = 1, W = 1 }
  G.apply_grades()
  return true
end

function GetDropGradePct(key)
  return G.grade_pct[key]
end

-- Bootstrap: load config, apply grades, hook cores for class weights.
G.load()
G.apply_grades()
local function hook_cores(mod)
  if type(mod) ~= "table" or mod.__gradeui_hooked then return mod end
  mod.__gradeui_hooked = true
  local function wrap_weights(fname)
    if type(mod[fname]) == "function" then
      local orig = mod[fname]
      mod[fname] = function(...)
        local w = orig(...)
        if type(w) == "table" then
          local out = {}
          local total = 0
          for k, v in pairs(w) do
            local m = G.class_mult(k)
            local nv = (tonumber(v) or 0) * m
            out[k] = nv
            total = total + nv
          end
          if total > 0 then
            for k in pairs(out) do out[k] = out[k] / total end
            return out
          end
        end
        return w
      end
    end
  end
  wrap_weights("getProjectedSymbolWeights")
  wrap_weights("baseSymbolWeights")
  return mod
end
if package and package.loaded and package.loaded["src.game.cores"] then
  hook_cores(package.loaded["src.game.cores"])
end
local _require = require
function require(name)
  local mod = _require(name)
  if name == "src.game.cores" then hook_cores(mod) end
  return mod
end
