if jit then
	jit.off(true, true)
end

local var_0_0 = {}
local var_0_1 = require("src.ui.mainmenu")
local var_0_2 = require("src.data.constants")
local var_0_3 = require("src.data.language")
local var_0_4 = require("src.data.font_resolver")
local var_0_5 = require("src.ui.config")
local var_0_6 = require("src.ui.widgets").count_impact
local var_0_7 = {}
local var_0_8 = {
	slotrare = "src/sprites/icons/menu/upgrade/21rareresearch1.png",
	slotrare2 = "src/sprites/icons/menu/upgrade/21rareresearch2.png",
	slotadvanced3 = "src/sprites/icons/menu/upgrade/20advancedresearch3.png",
	slotrare3 = "src/sprites/icons/menu/upgrade/21rareresearch3.png",
	slotadvanced2 = "src/sprites/icons/menu/upgrade/19advancedresearch2.png",
	slotlegend = "src/sprites/icons/menu/upgrade/35legendresearch1.png",
	slotadvanced = "src/sprites/icons/menu/upgrade/04advancedresearch1.png",
	slotlegend2 = "src/sprites/icons/menu/upgrade/35legendresearch2.png",
	slotodds = "src/sprites/icons/menu/upgrade/01slotodds.png",
	slotlegend3 = "src/sprites/icons/menu/upgrade/35legendresearch3.png",
	factionsynergy = "src/sprites/icons/menu/upgrade/34factionsynergy.png",
	slotprism = "src/sprites/icons/menu/upgrade/36prismresearch1.png",
	growthbranch = "src/sprites/icons/menu/upgrade/33growthbranch.png",
	slotprism2 = "src/sprites/icons/menu/upgrade/36prismresearch2.png",
	dormantpower = "src/sprites/icons/menu/upgrade/32dormantpower.png",
	slotprism3 = "src/sprites/icons/menu/upgrade/36prismresearch3.png",
	interest = "src/sprites/icons/menu/upgrade/07InterestBonus.png",
	fatestone = "src/sprites/icons/menu/upgrade/36fatestone.png",
	preptime = "src/sprites/icons/menu/upgrade/06prephourglass.png",
	stonetwin = "src/sprites/icons/menu/upgrade/37stonetwin.png",
	slotnudge = "src/sprites/icons/menu/upgrade/05nudge.png",
	stonebreeze = "src/sprites/icons/menu/upgrade/38stonebreeze.png",
	startgold2 = "src/sprites/icons/menu/upgrade/17startgold2.png",
	stoneomen = "src/sprites/icons/menu/upgrade/39stoneomen.png",
	comebackgold = "src/sprites/icons/menu/upgrade/16comebackgold.png",
	stonespecial = "src/sprites/icons/menu/upgrade/40stonespecial.png",
	gateheal = "src/sprites/icons/menu/upgrade/15regenhp.png",
	stonemastery = "src/sprites/icons/menu/upgrade/41stonemastery.png",
	comebackspin = "src/sprites/icons/menu/upgrade/14emergencygrant.png",
	stonerift = "src/sprites/icons/menu/upgrade/42stonerift.png",
	startingmerccontract = "src/sprites/icons/menu/upgrade/31merccontract.png",
	stoneconstellation = "src/sprites/icons/menu/upgrade/43stoneconstellation.png",
	startgold = "src/sprites/icons/menu/upgrade/13startgold.png",
	stonesanctum = "src/sprites/icons/menu/upgrade/44stonesanctum.png",
	noviceshield = "src/sprites/icons/menu/upgrade/12noviceshield.png",
	stonegambit = "src/sprites/icons/menu/upgrade/45stonegambit.png",
	maxhp2 = "src/sprites/icons/menu/upgrade/18heartII.png",
	preptime2 = "src/sprites/icons/menu/upgrade/08prephourglass2.png",
	maxhp = "src/sprites/icons/menu/upgrade/02heart.png",
	preptimerdisabled = "src/sprites/icons/menu/upgrade/09prephourglass3.png",
	maxunit3 = "src/sprites/icons/menu/upgrade/11maxunit3.png",
	maxunit2 = "src/sprites/icons/menu/upgrade/10maxunit2.png",
	maxunit = "src/sprites/icons/menu/upgrade/03maxunit.png",
	shoppin = "src/sprites/icons/menu/upgrade/28shoppin.png",
	itemresearch = "src/sprites/icons/menu/upgrade/27debuffitemresearch.png",
	iteminventory2 = "src/sprites/icons/menu/upgrade/26iteminventory2.png",
	itemrefund = "src/sprites/icons/menu/upgrade/25refundbook.png",
	iteminventory = "src/sprites/icons/menu/upgrade/24iteminventory.png",
	shopreroll = "src/sprites/icons/menu/upgrade/23shopreroll.png",
	firstcoreuncommon = "src/sprites/icons/menu/upgrade/30corechoice.png",
	firstcorespin = "src/sprites/icons/menu/upgrade/29firstcorespin.png",
	corereroll = "src/sprites/icons/menu/upgrade/22corereroll.png"
}
local var_0_9
local var_0_10
local var_0_11
local var_0_12
local var_0_13
local var_0_14
local var_0_15
local var_0_16
local var_0_17
local var_0_18
local var_0_19
local var_0_20
local var_0_21
local var_0_22
local var_0_23
local var_0_24
local var_0_25 = {
	pressed = false,
	scale = 0.9
}
local var_0_26
local var_0_27
local var_0_28 = 0
local var_0_29 = "src/data/font/Chinese/arkpixel10.ttf"
local var_0_30 = 10
local var_0_31 = "normal"
local var_0_32
local var_0_33 = 0
local var_0_34 = {}

local function var_0_35()
	return var_0_4.isChinese()
end

local function var_0_36()
	return _G.currentGameLang or "ko"
end

local function var_0_37(arg_3_0)
	local var_3_0 = rawget(_G, "getChineseLatinFallbackFont")

	if type(var_3_0) == "function" then
		local var_3_1 = var_3_0(arg_3_0)

		if var_3_1 then
			return var_3_1
		end
	end

	return arg_3_0
end

local function var_0_38(arg_4_0, arg_4_1)
	if var_0_35() then
		arg_4_0 = var_0_29
		arg_4_1 = arg_4_1 or var_0_30
	end

	if type(arg_4_0) ~= "string" or arg_4_0 == "" or not love.filesystem.getInfo(arg_4_0) then
		return nil
	end

	local var_4_0
	local var_4_1

	if not arg_4_0:lower():match("%.ttf$") and not arg_4_0:lower():match("%.otf$") then
		var_4_0, var_4_1 = pcall(love.graphics.newFont, arg_4_0)
	else
		var_4_0, var_4_1 = pcall(love.graphics.newFont, arg_4_0, arg_4_1 or var_0_30, var_0_31)
	end

	if var_4_0 and var_4_1 then
		var_4_1:setFilter("nearest", "nearest")
		var_0_4.attachFallbacks(var_4_1, arg_4_0)

		if var_0_35() and _G.registerChineseShadowFont then
			_G.registerChineseShadowFont(var_4_1)
		end

		return var_4_1
	end

	return nil
end

local function var_0_39(arg_5_0, arg_5_1)
	if type(arg_5_0) ~= "string" or arg_5_0 == "" or not love.filesystem.getInfo(arg_5_0) then
		return nil
	end

	local var_5_0
	local var_5_1
	local var_5_2 = tostring(arg_5_0):lower()

	if not var_5_2:match("%.ttf$") and not var_5_2:match("%.otf$") then
		var_5_0, var_5_1 = pcall(love.graphics.newFont, arg_5_0)
	else
		var_5_0, var_5_1 = pcall(love.graphics.newFont, arg_5_0, arg_5_1 or var_0_30, var_0_31)
	end

	if var_5_0 and var_5_1 then
		var_5_1:setFilter("nearest", "nearest")

		return var_5_1
	end

	return nil
end

local function var_0_40(arg_6_0)
	local var_6_0 = var_0_36()
	local var_6_1 = var_0_35() and var_0_29 or var_0_4.resolve(arg_6_0, var_6_0)

	if type(var_6_1) ~= "string" or var_6_1 == "" then
		var_6_1 = arg_6_0
	end

	return var_6_1, var_6_0
end

local function var_0_41(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0, var_7_1 = var_0_40(arg_7_2)
	local var_7_2 = tostring(var_7_1) .. "|" .. tostring(var_7_0)

	if arg_7_1 == var_7_2 then
		return arg_7_0, arg_7_1
	end

	local var_7_3 = var_0_38(var_7_0, var_0_35() and var_0_30 or nil)

	if var_7_3 then
		if _G.maybeRegisterSLineTtfTextEffect then
			_G.maybeRegisterSLineTtfTextEffect(var_7_3, arg_7_2, var_7_0, var_7_1)
		end

		if var_0_35() and _G.registerChineseLatinFallbackFont then
			local var_7_4 = _G.resolveChineseLatinFallbackPath and _G.resolveChineseLatinFallbackPath(arg_7_2) or arg_7_2

			_G.registerChineseLatinFallbackFont(var_7_3, var_0_39(var_7_4, var_0_30))
		end

		return var_7_3, var_7_2
	end

	return nil, var_7_2
end

function var_0_0.getOriginiteFont()
	var_0_14, var_0_15 = var_0_41(var_0_14, var_0_15, "src/data/font/Galmuri9WSLine.fnt")

	return var_0_14
end

function var_0_0.getTooltipFont()
	var_0_16, var_0_17 = var_0_41(var_0_16, var_0_17, "src/data/font/Galmuri9WS.fnt")

	return var_0_16
end

function var_0_0.reloadLanguageFonts()
	var_0_14 = nil
	var_0_15 = nil
	var_0_16 = nil
	var_0_17 = nil
	var_0_19 = nil
	var_0_20 = nil
end

local var_0_42
local var_0_43 = "    extern number time;\n    extern number scale;\n\n    // Precision-safe scalar hash. The old sin(dot(...)) hash multiplied a\n    // large trigonometric result by 43758, which becomes blocky on fragment\n    // hardware with reduced float precision. This version keeps coordinates\n    // bounded and uses only small fract/dot operations.\n    float hash12(vec2 p) {\n        p = mod(p, 71.0);\n        vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);\n        p3 += dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);\n        return fract((p3.x + p3.y) * p3.z);\n    }\n\n    float valueNoise(vec2 st) {\n        vec2 i = floor(st);\n        vec2 f = fract(st);\n        float a = hash12(i);\n        float b = hash12(i + vec2(1.0, 0.0));\n        float c = hash12(i + vec2(0.0, 1.0));\n        float d = hash12(i + vec2(1.0, 1.0));\n        vec2 u = f * f * (3.0 - 2.0 * f);\n        return mix(a, b, u.x)\n            + (c - a) * u.y * (1.0 - u.x)\n            + (d - b) * u.x * u.y;\n    }\n\n    float fbm(vec2 st) {\n        float value = 0.0;\n        float amplitude = 0.5;\n        for (int i = 0; i < 4; i++) {\n            value += amplitude * valueNoise(st);\n            st *= 2.0;\n            amplitude *= 0.5;\n        }\n        return value;\n    }\n\n    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {\n        // Preserve the original three-pixel cloudy/pixelated appearance.\n        float pixelSize = max(1.0, 3.0 * scale);\n        vec2 samplePx = floor(screen_coords / pixelSize);\n        vec2 uv = samplePx / 200.0;\n\n        // A cosine loop follows nearly the same slow drift as the old linear\n        // timer for its first half, then returns smoothly without ever sending\n        // large time values to the shader.\n        const float TAU = 6.28318530718;\n        float phase = time * (TAU / 100.0);\n        float drift = 0.5 - 0.5 * cos(phase);\n        uv += vec2(drift, drift * 0.5);\n        float n = fbm(uv);\n        float n2 = fbm(uv + vec2(n * 2.0, n * 0.5) - vec2(drift * 2.5));\n        float finalNoise = mix(n, n2, 0.6);\n\n        // Original upgrade-screen palette.\n\n        vec3 colDeep = vec3(0.10, 0.08, 0.14); // Darker than #2e222f (Abyss)\n        vec3 colBase = vec3(0.18, 0.13, 0.18); // #2e222f (UI Dark)\n        vec3 colMid  = vec3(0.24, 0.21, 0.28); // #3e3546 (UI Light)\n        vec3 colHigh = vec3(0.35, 0.25, 0.35); // Faint Highlight\n\n        vec3 col = colDeep;\n\n        // Smooth mixing based on noise height.\n        col = mix(col, colBase, smoothstep(0.2, 0.5, finalNoise));\n        col = mix(col, colMid,  smoothstep(0.5, 0.7, finalNoise));\n        col = mix(col, colHigh, smoothstep(0.7, 1.0, finalNoise));\n\n        // Darken edges to focus on the upgrade tree.\n        vec2 vUV = screen_coords / love_ScreenSize.xy;\n        float vignette = 1.0 - smoothstep(0.5, 1.5, length(vUV - 0.5) * 1.5);\n        col *= vignette;\n\n        // A one-LSB interleaved dither prevents visible color bands on 8/10-bit\n        // output without introducing another grid into the cloud field.\n        float dither = fract(52.9829189\n            * fract(dot(screen_coords, vec2(0.06711056, 0.00583715)))) - 0.5;\n        col += vec3(dither * (1.0 / 255.0));\n\n        return vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0) * color;\n    }\n"
local var_0_44 = 0
local var_0_45 = 0
local var_0_46 = 1
local var_0_47 = {
	0.3,
	0.34,
	0.39,
	0.45,
	0.51,
	0.59,
	0.67,
	0.77,
	0.88,
	1,
	1.1,
	1.2
}
local var_0_48 = 1
local var_0_49 = 0
local var_0_50 = 0
local var_0_51 = false
local var_0_52 = 1280
local var_0_53 = 720
local var_0_54 = false
local var_0_55 = 0
local var_0_56 = 0
local var_0_57 = 0
local var_0_58 = 0
local var_0_59 = 0
local var_0_60 = 0
local var_0_61 = 680

var_0_0.TREE_SPREAD = 1.2

local var_0_62 = {}
local var_0_63 = 80
local var_0_64 = 64

local function var_0_65(arg_11_0)
	local var_11_0 = math.max(0, arg_11_0 - 1) * var_0_61 * 0.5
	local var_11_1 = -(50 + var_11_0)
	local var_11_2 = 50 + var_11_0
	local var_11_3 = -(270 + var_11_0)
	local var_11_4 = 190 + var_11_0
	local var_11_5
	local var_11_6
	local var_11_7
	local var_11_8

	for iter_11_0, iter_11_1 in pairs(var_0_62) do
		local var_11_9 = math.floor((iter_11_1.x + iter_11_1.w / 2 - var_0_52 / 2) / 20 + 0.5) * 20
		local var_11_10 = math.floor((iter_11_1.y + iter_11_1.h / 2 - var_0_53 / 2) / 20 + 0.5) * 20

		var_11_5 = math.min(var_11_5 or var_11_9, var_11_9)
		var_11_6 = math.max(var_11_6 or var_11_9, var_11_9)
		var_11_7 = math.min(var_11_7 or var_11_10, var_11_10)
		var_11_8 = math.max(var_11_8 or var_11_10, var_11_10)
	end

	if var_11_5 then
		local var_11_11 = var_0_63

		var_11_1 = math.min(var_11_1, -(var_11_6 + var_11_11) * arg_11_0)
		var_11_2 = math.max(var_11_2, -(var_11_5 - var_11_11) * arg_11_0)
		var_11_3 = math.min(var_11_3, -(var_11_8 + var_11_11) * arg_11_0)
		var_11_4 = math.max(var_11_4, -(var_11_7 - var_11_11) * arg_11_0)
	end

	return var_11_1, var_11_2, var_11_3, var_11_4
end

local function var_0_66(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local var_12_0, var_12_1, var_12_2, var_12_3 = var_0_65(arg_12_2)

	if arg_12_3 then
		var_12_0, var_12_1 = math.min(var_12_0, arg_12_3), math.max(var_12_1, arg_12_3)
	end

	if arg_12_4 then
		var_12_2, var_12_3 = math.min(var_12_2, arg_12_4), math.max(var_12_3, arg_12_4)
	end

	return math.max(var_12_0, math.min(var_12_1, arg_12_0)), math.max(var_12_2, math.min(var_12_3, arg_12_1))
end

local function var_0_67(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = 0
	local var_13_1 = 1
	local var_13_2 = arg_13_2

	if arg_13_2 < arg_13_0 then
		var_13_0 = arg_13_0 - arg_13_2
	elseif arg_13_0 < arg_13_1 then
		var_13_0, var_13_1, var_13_2 = arg_13_1 - arg_13_0, -1, arg_13_1
	else
		return arg_13_0
	end

	local var_13_3 = var_0_64

	if arg_13_3 then
		var_13_0 = math.min(var_13_0, var_13_3 * 0.95)

		return var_13_2 + var_13_1 * var_13_0 * var_13_3 / (var_13_3 - var_13_0)
	end

	return var_13_2 + var_13_1 * var_13_0 * var_13_3 / (var_13_0 + var_13_3)
end

local function var_0_68(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4)
	local var_14_0, var_14_1, var_14_2, var_14_3 = var_0_65(arg_14_4)

	return var_0_67(var_0_67(arg_14_0, var_14_0, var_14_1, true) + arg_14_2, var_14_0, var_14_1), var_0_67(var_0_67(arg_14_1, var_14_2, var_14_3, true) + arg_14_3, var_14_2, var_14_3)
end

local var_0_69 = false
local var_0_70 = {}

function var_0_0.isSandboxActive()
	local var_15_0 = love and love.filesystem

	return var_0_69 and var_15_0 and var_15_0.getInfo and not var_15_0.getInfo("release.flag", "file") and not var_15_0.getInfo("build_release.flag", "file") or false
end

local var_0_71 = {}

local function var_0_72(arg_16_0)
	if not var_0_71[arg_16_0] then
		var_0_71[arg_16_0] = {
			pulseT = 0,
			shakeAmp = 0,
			shakeDur = 0,
			shakeT = 0,
			pressTimer = 0,
			scaleY = 1,
			scaleX = 1,
			pressed = false,
			disappearTimer = 0,
			isDisappearing = false,
			appearTimer = 0,
			isAppearing = false,
			revealed = false,
			unlockLineProgress = 0,
			popTimer = 0,
			isPopping = false,
			flashT = 0,
			shineT = love.math.random() * -2,
			energyParticles = {}
		}
	end

	return var_0_71[arg_16_0]
end

local function var_0_73(arg_17_0)
	if not arg_17_0 then
		return
	end

	arg_17_0.isDisappearing = true
	arg_17_0.disappearTimer = 0
	arg_17_0.isAppearing = false
end

var_0_72("slotodds").revealed = true
var_0_72("maxhp").revealed = false

var_0_72("maxhp2")
var_0_72("noviceshield")
var_0_72("startgold")
var_0_72("startingmerccontract")
var_0_72("comebackspin")
var_0_72("gateheal")
var_0_72("comebackgold")
var_0_72("startgold2")
var_0_72("maxunit")
var_0_72("maxunit2")
var_0_72("maxunit3")
var_0_72("slotnudge")
var_0_72("slotadvanced")
var_0_72("slotadvanced2")
var_0_72("slotadvanced3")
var_0_72("slotrare")
var_0_72("corereroll")
var_0_72("firstcorespin")
var_0_72("firstcoreuncommon")
var_0_72("shopreroll")
var_0_72("iteminventory")
var_0_72("itemrefund")
var_0_72("iteminventory2")
var_0_72("itemresearch")
var_0_72("shoppin")
var_0_72("preptime")
var_0_72("interest")
var_0_72("dormantpower")
var_0_72("growthbranch")
var_0_72("factionsynergy")
var_0_72("preptime2")
var_0_72("preptimerdisabled")

local var_0_74
local var_0_75

local function var_0_76()
	if var_0_26 and var_0_27 then
		return
	end

	local var_18_0 = love.timer.getTime()

	if var_18_0 < var_0_28 then
		return
	end

	var_0_28 = var_18_0 + 3

	if not var_0_26 then
		local var_18_1 = loadedAssets and loadedAssets.audio and loadedAssets.audio.buttonHover

		if not var_18_1 then
			local var_18_2 = "src/audio/ui/buttonhover1.wav"
			local var_18_3, var_18_4 = pcall(love.audio.newSource, var_18_2, "static")

			if not var_18_3 then
				local var_18_5 = "audio/ui/buttonhover1.wav"

				var_18_3, var_18_4 = pcall(love.audio.newSource, var_18_5, "static")
			end

			if var_18_3 and var_18_4 then
				var_18_1 = var_18_4
			end
		end

		if var_18_1 then
			local var_18_6 = ui and ui.menuSettings and ui.menuSettings.sfxVolume or 1

			if var_18_1.setVolume then
				var_18_1:setVolume(var_18_6 * 1.6)
			end

			var_0_26 = var_18_1
		end
	end

	if not var_0_27 then
		local var_18_7 = loadedAssets and loadedAssets.audio and loadedAssets.audio.buttonClick

		if not var_18_7 then
			local var_18_8 = "src/audio/ui/buttonclick1.wav"
			local var_18_9, var_18_10 = pcall(love.audio.newSource, var_18_8, "static")

			if not var_18_9 then
				local var_18_11 = "audio/ui/buttonclick1.wav"

				var_18_9, var_18_10 = pcall(love.audio.newSource, var_18_11, "static")
			end

			if var_18_9 and var_18_10 then
				var_18_7 = var_18_10
			end
		end

		if var_18_7 then
			local var_18_12 = ui and ui.menuSettings and ui.menuSettings.sfxVolume or 1

			if var_18_7.setVolume then
				var_18_7:setVolume(var_18_12 * 1.6)
			end

			var_0_27 = var_18_7
		end
	end
end

local var_0_77
local var_0_78 = {}
local var_0_79 = 100
local var_0_80 = 2000

for iter_0_0 = 1, var_0_79 do
	table.insert(var_0_78, {
		x = love.math.random(-var_0_80 / 2, var_0_80 / 2),
		y = love.math.random(-var_0_80 / 2, var_0_80 / 2),
		size = love.math.random(1, 2),
		speedX = love.math.random(-5, 5),
		speedY = love.math.random(-5, 5),
		alpha = love.math.random() * 0.5 + 0.2,
		t = love.math.random() * 100,
		blinkSpeed = love.math.random() * 2 + 1
	})
end

local var_0_81 = {}
local var_0_82 = 0
local var_0_83 = 2

function var_0_0.resetCamera()
	var_0_44 = 0
	var_0_45 = 0
	var_0_46 = 1
	var_0_49 = 0
	var_0_50 = 0
	var_0_48 = 1
	var_0_51 = false
	var_0_54 = false
	var_0_55, var_0_56 = 0, 0

	for iter_19_0, iter_19_1 in pairs(var_0_71) do
		iter_19_1.scaleX = 1
		iter_19_1.scaleY = 1
		iter_19_1.pressed = false
		iter_19_1.shakeT = 0
	end

	var_0_74 = nil

	if var_0_25 then
		var_0_25.pressed = false
		var_0_25.scale = 0.9
	end

	for iter_19_2, iter_19_3 in ipairs(var_0_78) do
		iter_19_3.x = love.math.random(-var_0_80 / 2, var_0_80 / 2)
		iter_19_3.y = love.math.random(-var_0_80 / 2, var_0_80 / 2)
	end
end

local function var_0_84(arg_20_0)
	arg_20_0 = arg_20_0:gsub("#", "")

	if arg_20_0 == "6FAACC" then
		arg_20_0 = "73A1B8"
	elseif arg_20_0 == "5FAF6F" then
		arg_20_0 = "69A873"
	elseif arg_20_0 == "A84F5A" then
		arg_20_0 = "A65B67"
	end

	local var_20_0 = tonumber(arg_20_0:sub(1, 2), 16) / 255
	local var_20_1 = tonumber(arg_20_0:sub(3, 4), 16) / 255
	local var_20_2 = tonumber(arg_20_0:sub(5, 6), 16) / 255

	return var_20_0, var_20_1, var_20_2, 1
end

local function var_0_85(arg_21_0)
	return math.floor(arg_21_0 or 0)
end

local var_0_86 = {
	boxFill = {
		0,
		0,
		0,
		0.8
	},
	label = (function()
		local var_22_0, var_22_1, var_22_2 = var_0_84("#999999")

		return {
			var_22_0,
			var_22_1,
			var_22_2,
			1
		}
	end)(),
	value = {
		1,
		1,
		1,
		1
	},
	gaugeBg = (function()
		local var_23_0, var_23_1, var_23_2 = var_0_84("#2A2A2A")

		return {
			var_23_0,
			var_23_1,
			var_23_2,
			1
		}
	end)(),
	gaugeFill = (function()
		local var_24_0, var_24_1, var_24_2 = var_0_84("#4FC3F7")

		return {
			var_24_0,
			var_24_1,
			var_24_2,
			1
		}
	end)(),
	hint = (function()
		local var_25_0, var_25_1, var_25_2 = var_0_84("#EDE6F3")

		return {
			var_25_0,
			var_25_1,
			var_25_2,
			1
		}
	end)(),
	separator = {
		1,
		1,
		1,
		0.2
	}
}
local var_0_87 = 3

local function var_0_88()
	return 1
end

local function var_0_89(arg_27_0, arg_27_1, arg_27_2, arg_27_3, arg_27_4, arg_27_5)
	local var_27_0 = var_0_88()
	local var_27_1 = math.max(1, math.floor((var_0_87 or 3) / var_27_0 + 0.5))
	local var_27_2 = math.min(math.floor(arg_27_2 / (2 * var_27_0)), math.floor(arg_27_3 / (2 * var_27_0)))

	if var_27_2 < 1 then
		var_27_2 = 1
	end

	if var_27_2 < var_27_1 then
		var_27_1 = var_27_2
	end

	local var_27_3 = var_27_1 * var_27_0

	if arg_27_4 then
		love.graphics.setColor(arg_27_4[1], arg_27_4[2], arg_27_4[3], arg_27_4[4] or 1)
	end

	if arg_27_3 - 2 * var_27_3 > 0 then
		love.graphics.rectangle("fill", var_0_85(arg_27_0 + var_27_3), var_0_85(arg_27_1 + var_27_3), var_0_85(arg_27_2 - 2 * var_27_3), var_0_85(arg_27_3 - 2 * var_27_3))
	end

	if arg_27_3 - 2 * var_27_3 > 0 then
		love.graphics.rectangle("fill", var_0_85(arg_27_0), var_0_85(arg_27_1 + var_27_3), var_0_85(var_27_3), var_0_85(arg_27_3 - 2 * var_27_3))
		love.graphics.rectangle("fill", var_0_85(arg_27_0 + arg_27_2 - var_27_3), var_0_85(arg_27_1 + var_27_3), var_0_85(var_27_3), var_0_85(arg_27_3 - 2 * var_27_3))
	end

	for iter_27_0 = 0, var_27_1 - 1 do
		local var_27_4 = var_27_3 - (iter_27_0 + 1) * var_27_0

		if var_27_4 < 0 then
			var_27_4 = 0
		end

		local var_27_5 = arg_27_2 - 2 * var_27_4

		if var_27_5 > 0 then
			love.graphics.rectangle("fill", var_0_85(arg_27_0 + var_27_4), var_0_85(arg_27_1 + iter_27_0 * var_27_0), var_0_85(var_27_5), var_0_85(var_27_0))
			love.graphics.rectangle("fill", var_0_85(arg_27_0 + var_27_4), var_0_85(arg_27_1 + arg_27_3 - (iter_27_0 + 1) * var_27_0), var_0_85(var_27_5), var_0_85(var_27_0))
		end
	end

	if arg_27_5 then
		love.graphics.setColor(arg_27_5[1], arg_27_5[2], arg_27_5[3], arg_27_5[4] or 1)

		local var_27_6 = var_27_0

		for iter_27_1 = 0, var_27_1 - 1 do
			local var_27_7 = var_27_3 - (iter_27_1 + 1) * var_27_0

			if var_27_7 < 0 then
				var_27_7 = 0
			end

			if iter_27_1 ~= 0 then
				love.graphics.rectangle("fill", var_0_85(arg_27_0 + var_27_7), var_0_85(arg_27_1 + iter_27_1 * var_27_0), var_0_85(var_27_6), var_0_85(var_27_6))
				love.graphics.rectangle("fill", var_0_85(arg_27_0 + arg_27_2 - var_27_7 - var_27_6), var_0_85(arg_27_1 + iter_27_1 * var_27_0), var_0_85(var_27_6), var_0_85(var_27_6))
				love.graphics.rectangle("fill", var_0_85(arg_27_0 + var_27_7), var_0_85(arg_27_1 + arg_27_3 - (iter_27_1 + 1) * var_27_0), var_0_85(var_27_6), var_0_85(var_27_6))
				love.graphics.rectangle("fill", var_0_85(arg_27_0 + arg_27_2 - var_27_7 - var_27_6), var_0_85(arg_27_1 + arg_27_3 - (iter_27_1 + 1) * var_27_0), var_0_85(var_27_6), var_0_85(var_27_6))
			else
				local var_27_8 = arg_27_2 - 2 * var_27_7

				if var_27_8 > 0 then
					love.graphics.rectangle("fill", var_0_85(arg_27_0 + var_27_7), var_0_85(arg_27_1 + iter_27_1 * var_27_0), var_0_85(var_27_8), var_0_85(var_27_6))
					love.graphics.rectangle("fill", var_0_85(arg_27_0 + var_27_7), var_0_85(arg_27_1 + arg_27_3 - (iter_27_1 + 1) * var_27_0), var_0_85(var_27_8), var_0_85(var_27_6))
				end
			end
		end

		local var_27_9 = arg_27_3 - 2 * var_27_3

		if var_27_9 > 0 then
			love.graphics.rectangle("fill", var_0_85(arg_27_0), var_0_85(arg_27_1 + var_27_3), var_0_85(var_27_6), var_0_85(var_27_9))
			love.graphics.rectangle("fill", var_0_85(arg_27_0 + arg_27_2 - var_27_6), var_0_85(arg_27_1 + var_27_3), var_0_85(var_27_6), var_0_85(var_27_9))
		end
	end
end

local var_0_90
local var_0_91 = {
	maxhp = {
		cost = 1,
		nameKey = "upgrade_maxhp_name",
		nodeId = "A01",
		stat = "5 -> 6",
		descKey = "upgrade_maxhp_desc"
	},
	maxhp2 = {
		descKey = "upgrade_maxhp2_desc",
		nameKey = "upgrade_maxhp2_name",
		cost = 22,
		nodeId = "A11",
		stat = "6 -> 7",
		statKey = "upgrade_maxhp2_stat"
	},
	noviceshield = {
		descKey = "upgrade_noviceshield_desc",
		nameKey = "upgrade_noviceshield_name",
		cost = 4,
		nodeId = "A03",
		stat = "First life loss 0 -> 1",
		statKey = "upgrade_noviceshield_stat"
	},
	startgold = {
		descKey = "upgrade_startgold_desc",
		nameKey = "upgrade_startgold_name",
		cost = 2,
		nodeId = "A02",
		stat = "Starting {gold.png} 450 -> 500",
		statKey = "upgrade_startgold_stat"
	},
	startingmerccontract = {
		cost = 12,
		nameKey = "upgrade_startingmerccontract_name",
		nodeId = "A07",
		stat = "startingmerccontract 0 -> 1",
		unlockCoreKey = "MercContract",
		descKey = "upgrade_startingmerccontract_desc"
	},
	comebackspin = {
		descKey = "upgrade_comebackspin_desc",
		nameKey = "upgrade_comebackspin_name",
		cost = 20,
		nodeId = "A06",
		stat = "First spin guaranteed win",
		statKey = "upgrade_comebackspin_stat"
	},
	gateheal = {
		descKey = "upgrade_gateheal_desc",
		nameKey = "upgrade_gateheal_name",
		cost = 48,
		nodeId = "A09",
		stat = "Life recovery",
		statKey = "upgrade_gateheal_stat"
	},
	comebackgold = {
		descKey = "upgrade_comebackgold_desc",
		nameKey = "upgrade_comebackgold_name",
		cost = 9,
		nodeId = "A05",
		stat = "After defeat {gold.png} 0 -> 100",
		statKey = "upgrade_comebackgold_stat"
	},
	startgold2 = {
		descKey = "upgrade_startgold2_desc",
		nameKey = "upgrade_startgold2_name",
		cost = 7,
		nodeId = "A04",
		stat = "Starting {gold.png} 500 -> 550",
		statKey = "upgrade_startgold2_stat"
	},
	slotnudge = {
		descKey = "upgrade_slotnudge_desc",
		nameKey = "upgrade_slotnudge_name",
		cost = 3,
		nodeId = "B02",
		stat = "Nudge spin cost reduction",
		statKey = "upgrade_slotnudge_stat"
	},
	interest = {
		descKey = "upgrade_interest_desc",
		nameKey = "upgrade_interest_name",
		cost = 8,
		nodeId = "B03",
		stat = "Interest 0 -> 50",
		statKey = "upgrade_interest_stat"
	},
	dormantpower = {
		descKey = "upgrade_dormantpower_desc",
		nameKey = "upgrade_dormantpower_name",
		cost = 12,
		nodeId = "B04",
		stat = "awakeningUnlocked 0 -> 1",
		statKey = "upgrade_dormantpower_stat"
	},
	growthbranch = {
		descKey = "upgrade_growthbranch_desc",
		nameKey = "upgrade_growthbranch_name",
		cost = 45,
		nodeId = "B05",
		stat = "promotionTraitChoice 0 -> 1",
		statKey = "upgrade_growthbranch_stat"
	},
	factionsynergy = {
		descKey = "upgrade_factionsynergy_desc",
		nameKey = "upgrade_factionsynergy_name",
		cost = 60,
		nodeId = "B10",
		stat = "factionSynergyUnlocked 0 -> 1",
		statKey = "upgrade_factionsynergy_stat"
	},
	slotodds = {
		descKey = "upgrade_slotodds_desc",
		nameKey = "upgrade_slotodds_name",
		cost = 1,
		nodeId = "S01",
		stat = "Locked -> Unsealed",
		statKey = "upgrade_slotodds_stat"
	},
	slotadvanced = {
		descKey = "upgrade_slotadvanced_desc",
		nameKey = "upgrade_slotadvanced_name",
		cost = 4,
		nodeId = "R01",
		stat = "怨좉툒 0% -> 5%",
		statKey = "upgrade_slotadvanced_stat"
	},
	slotadvanced2 = {
		descKey = "upgrade_slotadvanced2_desc",
		nameKey = "upgrade_slotadvanced2_name",
		cost = 12,
		nodeId = "R02",
		stat = "Advanced 5% -> 10%",
		statKey = "upgrade_slotadvanced2_stat"
	},
	slotadvanced3 = {
		descKey = "upgrade_slotadvanced3_desc",
		nameKey = "upgrade_slotadvanced3_name",
		cost = 28,
		nodeId = "R03",
		stat = "Advanced 10% -> 15%",
		statKey = "upgrade_slotadvanced3_stat"
	},
	slotrare = {
		statKey = "upgrade_slotrare_stat",
		cost = 70,
		stat = "Rare 0% -> 2%",
		descKey = "upgrade_slotrare_desc",
		nameKey = "upgrade_slotrare_name",
		nodeId = "R04",
		reqFull = true,
		reqDiff = 2,
		reqStage = 2
	},
	corereroll = {
		descKey = "upgrade_corereroll_desc",
		nameKey = "upgrade_corereroll_name",
		cost = 10,
		nodeId = "K01",
		stat = "Free reroll 0 -> 1",
		statKey = "upgrade_corereroll_stat"
	},
	firstcorespin = {
		descKey = "upgrade_firstcorespin_desc",
		nameKey = "upgrade_firstcorespin_name",
		cost = 30,
		nodeId = "K02",
		stat = "First core required spins 0 -> -1",
		statKey = "upgrade_firstcorespin_stat"
	},
	firstcoreuncommon = {
		descKey = "upgrade_firstcoreuncommon_desc",
		nameKey = "upgrade_firstcoreuncommon_name",
		cost = 60,
		nodeId = "K03",
		stat = "Uncommon core appears",
		statKey = "upgrade_firstcoreuncommon_stat"
	},
	shopreroll = {
		descKey = "upgrade_shopreroll_desc",
		nameKey = "upgrade_shopreroll_name",
		cost = 6,
		nodeId = "M01",
		stat = "Shop reroll discount 0 -> 1",
		statKey = "upgrade_shopreroll_stat"
	},
	iteminventory = {
		descKey = "upgrade_iteminventory_desc",
		nameKey = "upgrade_iteminventory_name",
		cost = 45,
		nodeId = "M03",
		stat = "Item slots 6 -> 7",
		statKey = "upgrade_iteminventory_stat"
	},
	itemrefund = {
		descKey = "upgrade_itemrefund_desc",
		nameKey = "upgrade_itemrefund_name",
		cost = 35,
		nodeId = "M04",
		stat = "Refund rate 50% -> 80%",
		statKey = "upgrade_itemrefund_stat"
	},
	iteminventory2 = {
		descKey = "upgrade_iteminventory2_desc",
		nameKey = "upgrade_iteminventory2_name",
		cost = 160,
		nodeId = "M12",
		stat = "Item slots 7 -> 8",
		statKey = "upgrade_iteminventory2_stat"
	},
	itemresearch = {
		statKey = "upgrade_itemresearch_stat",
		nameKey = "upgrade_itemresearch_name",
		stat = "2 specialist items added",
		nodeId = "M05",
		cost = 24,
		hidden = true,
		descKey = "upgrade_itemresearch_desc"
	},
	shoppin = {
		statKey = "upgrade_shoppin_stat",
		nameKey = "upgrade_shoppin_name",
		stat = "Pin product",
		nodeId = "M02",
		cost = 30,
		hidden = true,
		descKey = "upgrade_shoppin_desc"
	},
	maxunit = {
		cost = 6,
		nameKey = "upgrade_maxunit_name",
		nodeId = "B01",
		stat = "5 -> 6",
		descKey = "upgrade_maxunit_desc"
	},
	maxunit2 = {
		descKey = "upgrade_maxunit2_desc",
		nameKey = "upgrade_maxunit2_name",
		cost = 70,
		nodeId = "B06",
		stat = "6 -> 7",
		statKey = "upgrade_maxunit2_stat"
	},
	maxunit3 = {
		descKey = "upgrade_maxunit3_desc",
		nameKey = "upgrade_maxunit3_name",
		cost = 180,
		nodeId = "B09",
		stat = "7 -> 8",
		statKey = "upgrade_maxunit3_stat"
	}
}

local function var_0_92(arg_28_0, arg_28_1, arg_28_2, arg_28_3, arg_28_4, arg_28_5, arg_28_6)
	local var_28_0 = {
		nodeId = arg_28_1,
		nameKey = "upgrade_" .. arg_28_0 .. "_name",
		descKey = "upgrade_" .. arg_28_0 .. "_desc",
		statKey = "upgrade_" .. arg_28_0 .. "_stat",
		stat = arg_28_6.stat,
		cost = arg_28_3,
		parent = arg_28_2,
		posX = arg_28_4,
		posY = arg_28_5,
		maxedGrade = arg_28_6.grade,
		maxedValue = arg_28_6.value,
		reqStage = arg_28_6.reqStage,
		reqDiff = arg_28_6.reqDiff,
		reqFull = arg_28_6.reqFull
	}

	var_0_91[arg_28_0] = var_28_0
end

var_0_92("slotrare2", "R05", "slotrare", 100, -140, -300, {
	grade = "rare",
	stat = "Rare 2% -> 3%",
	value = "3%"
})
var_0_92("slotrare3", "R06", "slotrare2", 140, -200, -360, {
	grade = "rare",
	stat = "Rare 3% -> 4.5%",
	value = "4.5%"
})
var_0_92("slotlegend", "R07", "slotrare", 120, -80, -320, {
	reqFull = true,
	value = "0.1%",
	grade = "legendary",
	stat = "Legendary 0% -> 0.1%",
	reqDiff = 1,
	reqStage = 4
})
var_0_92("slotlegend2", "R08", "slotlegend", 170, -140, -380, {
	grade = "legendary",
	stat = "Legendary 0.1% -> 0.2%",
	value = "0.2%"
})
var_0_92("slotlegend3", "R09", "slotlegend2", 230, -200, -440, {
	grade = "legendary",
	stat = "Legendary 0.2% -> 0.4%",
	value = "0.4%"
})
var_0_92("slotprism", "R10", "slotlegend", 200, -80, -400, {
	reqFull = true,
	value = "0.02%",
	grade = "prism",
	stat = "Prism 0% -> 0.02%",
	reqDiff = 1,
	reqStage = 5
})
var_0_92("slotprism2", "R11", "slotprism", 280, -140, -460, {
	grade = "prism",
	stat = "Prism 0.02% -> 0.05%",
	value = "0.05%"
})
var_0_92("slotprism3", "R12", "slotprism2", 380, -200, -520, {
	grade = "prism",
	stat = "Prism 0.05% -> 0.1%",
	value = "0.1%"
})
var_0_92("fatestone", "F01", "slotlegend", 90, 0, -400, {
	stat = "Locked -> Unlocked"
})
var_0_92("stonetwin", "F02", "fatestone", 45, 60, -460, {
	stat = "Locked -> Unlocked"
})
var_0_92("stonebreeze", "F03", "stonetwin", 90, 120, -520, {
	stat = "Locked -> Unlocked",
	reqDiff = 2,
	reqStage = 5
})
var_0_92("stoneomen", "F04", "stonebreeze", 120, 180, -580, {
	stat = "Locked -> Unlocked",
	reqDiff = 2,
	reqStage = 5
})
var_0_92("stonespecial", "F05", "fatestone", 70, 80, -400, {
	stat = "Locked -> Unlocked"
})
var_0_92("stonemastery", "F06", "stonespecial", 130, 140, -460, {
	stat = "Locked -> Unlocked",
	reqDiff = 2,
	reqStage = 5
})
var_0_92("stonerift", "F07", "stonemastery", 170, 200, -520, {
	stat = "Locked -> Unlocked",
	reqDiff = 2,
	reqStage = 5
})
var_0_92("stoneconstellation", "F08", "fatestone", 110, 0, -480, {
	stat = "Locked -> Unlocked"
})
var_0_92("stonesanctum", "F09", "stoneconstellation", 180, 60, -540, {
	stat = "Locked -> Unlocked",
	reqDiff = 2,
	reqStage = 5
})
var_0_92("stonegambit", "F10", "stonesanctum", 230, 120, -600, {
	stat = "Locked -> Unlocked",
	reqDiff = 2,
	reqStage = 5
})

for iter_0_1, iter_0_2 in pairs(var_0_91) do
	if iter_0_2.parent then
		var_0_72(iter_0_1)
	end
end

local var_0_93 = {
	item = function(arg_29_0)
		return "item.name." .. arg_29_0.id, "item.effect." .. arg_29_0.id .. ".1"
	end,
	core = function(arg_30_0)
		return "core.name." .. arg_30_0.key, "core.desc." .. arg_30_0.key
	end,
	trait = function(arg_31_0)
		return "random_option.name." .. arg_31_0.id, "random_option.effect." .. arg_31_0.id
	end,
	machine = function(arg_32_0)
		return "machine_" .. arg_32_0.id .. "_name", "machine_" .. arg_32_0.id .. "_desc"
	end,
	faction = function(arg_33_0)
		return "faction." .. arg_33_0.id, nil
	end
}
local var_0_94 = {
	item = "upgrade_unlock_item_label",
	trait = "upgrade_unlock_trait_label",
	core = "upgrade_unlock_label"
}

local function var_0_95(arg_34_0, arg_34_1, arg_34_2, arg_34_3, arg_34_4, arg_34_5, arg_34_6, arg_34_7)
	local var_34_0 = {
		stat = "Locked -> Unlocked",
		tree2 = true,
		nodeId = arg_34_1,
		cost = arg_34_3,
		parent = arg_34_2,
		posX = arg_34_4,
		posY = arg_34_5
	}

	if arg_34_6 then
		var_34_0.reqStage, var_34_0.reqDiff = arg_34_6[1], arg_34_6[2]

		if arg_34_6[1] >= 2 then
			var_34_0.reqNoDemo = true
		end
	end

	if not arg_34_7 then
		var_34_0.nameKey = "upgrade_" .. arg_34_0 .. "_name"
		var_34_0.descKey = "upgrade_" .. arg_34_0 .. "_desc"
		var_34_0.statKey = "upgrade_" .. arg_34_0 .. "_stat"
	else
		var_34_0.unlock = arg_34_7
		var_34_0.wideTooltip = true
		var_34_0.nameKey, var_34_0.descKey = var_0_93[arg_34_7.kind](arg_34_7)
		var_34_0.statKey = "upgrade_unlock_" .. arg_34_7.kind .. "_stat"

		if arg_34_7.kind == "faction" then
			var_34_0.descKey = "upgrade_unlock_faction_desc"
			var_34_0.descNamed = true
		elseif arg_34_7.kind == "machine" then
			var_34_0.nameKey = "upgrade_unlock_machine_" .. arg_34_7.id .. "_name"
			var_34_0.descNameKey = "machine_" .. arg_34_7.id .. "_name"
			var_34_0.descKey = "upgrade_unlock_machine_" .. arg_34_7.id .. "_desc"
			var_34_0.descNamed = true
		end

		if var_0_94[arg_34_7.kind] then
			var_34_0.unlockSection = {
				labelKey = var_0_94[arg_34_7.kind],
				nameKey = var_34_0.nameKey,
				descKey = var_34_0.descKey,
				dropLevel = arg_34_7.kind == "item"
			}
			var_34_0.descKey = "upgrade_unlock_" .. arg_34_7.kind .. "_desc"
		end
	end

	var_0_91[arg_34_0] = var_34_0
	var_0_8[arg_34_0] = "src/sprites/icons/menu/upgrade/placeholder/" .. arg_34_0 .. ".png"

	var_0_72(arg_34_0)
end

var_0_95("corereroll2", "K04", "corereroll", 24, -80, -160, {
	1,
	2
}, nil)
var_0_95("unlock_core_31", "C31", "corereroll", 8, -160, -80, nil, {
	id = "31",
	kind = "core",
	key = "GoldTooth"
})
var_0_95("unlock_core_28", "C28", "unlock_core_31", 8, -220, -140, nil, {
	id = "28",
	kind = "core",
	key = "ChaliceGreed"
})
var_0_95("unlock_core_29", "C29", "unlock_core_28", 12, -280, -200, {
	1,
	2
}, {
	id = "29",
	kind = "core",
	key = "JokerGrin"
})
var_0_95("unlock_core_27", "C27", "unlock_core_29", 14, -340, -260, {
	1,
	2
}, {
	id = "27",
	kind = "core",
	key = "WitchTorch"
})
var_0_95("unlock_core_19", "C19", "unlock_core_31", 12, -240, -80, nil, {
	id = "19",
	kind = "core",
	key = "BlackNote"
})
var_0_95("unlock_core_20", "C20", "unlock_core_19", 12, -300, -140, nil, {
	id = "20",
	kind = "core",
	key = "ResonantAnvil"
})
var_0_95("unlock_core_21", "C21", "unlock_core_20", 20, -360, -200, {
	1,
	2
}, {
	id = "21",
	kind = "core",
	key = "CrookedFang"
})
var_0_95("unlock_core_25", "C25", "unlock_core_21", 40, -420, -260, {
	2,
	2
}, {
	id = "25",
	kind = "core",
	key = "TricksterCube"
})
var_0_95("unlock_core_24", "C24", "unlock_core_25", 40, -480, -320, {
	2,
	2
}, {
	id = "24",
	kind = "core",
	key = "MagicLamp"
})
var_0_95("unlock_core_30", "C30", "unlock_core_24", 45, -540, -380, {
	2,
	2
}, {
	id = "30",
	kind = "core",
	key = "FourLeafClover"
})
var_0_95("unlock_core_26", "C26", "unlock_core_30", 60, -600, -440, {
	3,
	2
}, {
	id = "26",
	kind = "core",
	key = "HammerOfFate"
})
var_0_95("unlock_core_22", "C22", "unlock_core_19", 40, -320, -80, {
	1,
	2
}, {
	id = "22",
	kind = "core",
	key = "Wildcard"
})
var_0_95("unlock_core_23", "C23", "unlock_core_22", 45, -380, -140, {
	1,
	2
}, {
	id = "23",
	kind = "core",
	key = "GoldenLever"
})
var_0_95("unlock_core_32", "C32", "unlock_core_23", 150, -440, -200, {
	4,
	2
}, {
	id = "32",
	kind = "core",
	key = "EchoShell"
})
var_0_95("secondcoreuncommon", "K05", "firstcoreuncommon", 80, -300, -20, {
	3,
	2
}, nil)
var_0_95("corefav", "K06", "corereroll2", 20, -160, -160, {
	1,
	2
}, nil)

var_0_91.corefav.reqNoDemo = true

var_0_95("corefav2", "K07", "corereroll2", 150, -140, -220, {
	5,
	2
}, nil)
var_0_95("mercextend", "A12", "startingmerccontract", 18, -280, 120, {
	1,
	2
}, nil)
var_0_95("startessence", "A13", "maxhp", 30, -140, 60, {
	2,
	2
}, nil)
var_0_95("wingold", "A14", "interest", 45, -340, 180, {
	2,
	2
}, nil)
var_0_95("lastspin", "A15", "wingold", 70, -420, 180, {
	3,
	2
}, nil)
var_0_95("comebackgold2", "A16", "comebackgold", 35, -120, 280, {
	2,
	2
}, nil)
var_0_95("unlock_item_07", "I07", "shopreroll", 5, 160, -80, nil, {
	kind = "item",
	id = "07"
})
var_0_95("unlock_item_08", "I08", "unlock_item_07", 8, 240, -80, {
	1,
	2
}, {
	kind = "item",
	id = "08"
})
var_0_95("unlock_item_37", "I37", "unlock_item_08", 10, 320, -80, {
	1,
	2
}, {
	kind = "item",
	id = "37"
})
var_0_95("unlock_item_17", "I17", "unlock_item_08", 24, 300, -140, {
	2,
	2
}, {
	kind = "item",
	id = "17"
})
var_0_95("unlock_item_27", "I27", "unlock_item_17", 50, 360, -200, {
	3,
	2
}, {
	kind = "item",
	id = "27"
})
var_0_95("unlock_item_24", "I24", "unlock_item_27", 80, 420, -260, {
	4,
	2
}, {
	kind = "item",
	id = "24"
})
var_0_95("unlock_item_11", "I11", "unlock_item_37", 28, 380, -140, {
	2,
	2
}, {
	kind = "item",
	id = "11"
})
var_0_95("unlock_item_40", "I40", "unlock_item_11", 28, 440, -200, {
	2,
	2
}, {
	kind = "item",
	id = "40"
})
var_0_95("unlock_item_28", "I28", "unlock_item_40", 55, 500, -260, {
	3,
	2
}, {
	kind = "item",
	id = "28"
})
var_0_95("unlock_item_45", "I45", "unlock_item_28", 160, 560, -320, {
	4,
	2
}, {
	kind = "item",
	id = "45"
})
var_0_95("unlock_item_23", "I23", "unlock_item_37", 55, 400, -80, {
	3,
	2
}, {
	kind = "item",
	id = "23"
})
var_0_95("unlock_item_48", "I48", "unlock_item_23", 140, 460, -140, {
	4,
	2
}, {
	kind = "item",
	id = "48"
})
var_0_95("shopdiscount", "M06", "itemrefund", 50, 280, -200, {
	3,
	2
}, nil)
var_0_95("unlock_core_38", "C38", "slotnudge", 5, -280, 40, nil, {
	id = "38",
	kind = "core",
	key = "GreedyPearl"
})
var_0_95("unlock_core_36", "C36", "unlock_core_38", 10, -360, 40, {
	1,
	2
}, {
	id = "36",
	kind = "core",
	key = "ReverseAxis"
})
var_0_95("unlock_core_37", "C37", "unlock_core_36", 12, -440, 40, {
	1,
	2
}, {
	id = "37",
	kind = "core",
	key = "CycleBell"
})
var_0_95("unlock_core_39", "C39", "unlock_core_35", 36, -580, 100, {
	2,
	2
}, {
	id = "39",
	kind = "core",
	key = "JesterCandle"
})
var_0_95("unlock_core_40", "C40", "unlock_core_39", 110, -660, 100, {
	3,
	2
}, {
	id = "40",
	kind = "core",
	key = "GoldenCrest"
})
var_0_95("unlock_core_35", "C35", "unlock_core_37", 16, -500, 100, {
	1,
	2
}, {
	id = "35",
	kind = "core",
	key = "ReboundAxis"
})
var_0_95("blastmachine", "X01", "slotodds", 60, 80, 0, {
	2,
	2
}, {
	kind = "machine",
	id = "blast"
})
var_0_95("unlock_core_43", "C43", "blastmachine", 20, 160, 0, {
	2,
	2
}, {
	id = "43",
	kind = "core",
	key = "BlastCart"
})
var_0_95("unlock_core_44", "C44", "unlock_core_43", 20, 240, 0, {
	2,
	2
}, {
	id = "44",
	kind = "core",
	key = "UpdraftFeather"
})
var_0_95("unlock_core_45", "C45", "unlock_core_44", 22, 320, 0, {
	2,
	2
}, {
	id = "45",
	kind = "core",
	key = "SporeShroom"
})
var_0_95("unlock_core_46", "C46", "unlock_core_45", 50, 380, 60, {
	3,
	2
}, {
	id = "46",
	kind = "core",
	key = "ArsonistLighter"
})
var_0_95("unlock_core_47", "C47", "unlock_core_46", 55, 460, 60, {
	3,
	2
}, {
	id = "47",
	kind = "core",
	key = "PowderKeg"
})
var_0_95("unlock_core_48", "C48", "unlock_core_47", 150, 540, 60, {
	4,
	2
}, {
	id = "48",
	kind = "core",
	key = "Burstberry"
})
var_0_95("blastmastery", "X02", "blastmachine", 30, 140, 60, {
	2,
	2
}, nil)
var_0_95("unlock_trait_23", "T23", "dormantpower", 12, 260, 180, {
	1,
	2
}, {
	kind = "trait",
	id = "23"
})
var_0_95("unlock_trait_11", "T11", "unlock_trait_23", 24, 340, 180, {
	2,
	2
}, {
	kind = "trait",
	id = "11"
})
var_0_95("unlock_trait_25", "T25", "unlock_trait_11", 28, 420, 180, {
	2,
	2
}, {
	kind = "trait",
	id = "25"
})
var_0_95("unlock_trait_28", "T28", "unlock_trait_25", 40, 500, 180, {
	3,
	2
}, {
	kind = "trait",
	id = "28"
})
var_0_95("unlock_trait_26", "T26", "unlock_trait_28", 130, 580, 180, {
	4,
	2
}, {
	kind = "trait",
	id = "26"
})
var_0_95("unlock_trait_29", "T29", "unlock_trait_23", 28, 260, 260, {
	2,
	2
}, {
	kind = "trait",
	id = "29"
})
var_0_95("unlock_trait_32", "T32", "unlock_trait_29", 48, 340, 260, {
	3,
	2
}, {
	kind = "trait",
	id = "32"
})
var_0_95("unlock_faction_arcane", "P01", "factionsynergy", 40, 0, 200, {
	2,
	2
}, {
	kind = "faction",
	id = "arcane"
})
var_0_95("unlock_faction_abyss", "P02", "unlock_faction_arcane", 70, 0, 280, {
	3,
	2
}, {
	kind = "faction",
	id = "abyss"
})
var_0_95("unlock_faction_undead", "P03", "unlock_faction_abyss", 70, 0, 360, {
	3,
	2
}, {
	kind = "faction",
	id = "undead"
})
var_0_95("unlock_faction_celestial", "P04", "unlock_faction_undead", 120, 0, 440, {
	4,
	1
}, {
	kind = "faction",
	id = "celestial"
})
var_0_95("questreroll", "F11", "fatestone", 60, -60, -460, {
	4,
	2
}, nil)
var_0_95("stoneshop", "F12", "fatestone", 60, 60, -340, {
	5,
	1
}, nil)
var_0_95("stoneshop2", "F13", "stoneshop", 150, 140, -340, {
	5,
	2
}, nil)

var_0_8.stoneshop = "src/sprites/icons/menu/upgrade/46stoneshop.png"
var_0_8.stoneshop2 = "src/sprites/icons/menu/upgrade/47stoneshop2.png"
var_0_8.questreroll = "src/sprites/icons/menu/upgrade/48questreroll.png"
var_0_8.secondcoreuncommon = "src/sprites/icons/menu/upgrade/49secondcoreuncommon.png"
var_0_8.corereroll2 = "src/sprites/icons/menu/upgrade/50corereroll2.png"
var_0_8.comebackgold2 = "src/sprites/icons/menu/upgrade/51comebackgold2.png"
var_0_8.mercextend = "src/sprites/icons/menu/upgrade/52mercextend.png"
var_0_8.corefav = "src/sprites/icons/menu/upgrade/108corefav.png"
var_0_8.corefav2 = "src/sprites/icons/menu/upgrade/109corefav2.png"
var_0_8.unlock_faction_arcane = "src/sprites/icons/menu/upgrade/53factionarcane.png"
var_0_8.unlock_faction_abyss = "src/sprites/icons/menu/upgrade/54factionabyss.png"
var_0_8.unlock_faction_undead = "src/sprites/icons/menu/upgrade/55factionundead.png"
var_0_8.unlock_faction_celestial = "src/sprites/icons/menu/upgrade/56factioncelestial.png"

for iter_0_3, iter_0_4 in pairs({
	["32"] = "70coreechoshell",
	["19"] = "57coreblacknote",
	["28"] = "66corechalicegreed",
	["36"] = "72corereverseaxis",
	["29"] = "67corejokergrin",
	["27"] = "65corewitchtorch",
	["25"] = "63coretrickstercube",
	["38"] = "74coregreedypearl",
	["24"] = "62coremagiclamp",
	["26"] = "64corehammeroffate",
	["44"] = "78coreupdraftfeather",
	["37"] = "73corecyclebell",
	["48"] = "82coreburstberry",
	["30"] = "68corefourleafclover",
	["43"] = "77coreblastcart",
	["22"] = "60corewildcard",
	["45"] = "79coresporeshroom",
	["31"] = "69coregoldtooth",
	["46"] = "80corearsonistlighter",
	["23"] = "61coregoldenlever",
	["35"] = "71corereboundaxis",
	["40"] = "76coregoldencrest",
	["21"] = "59corecrookedfang",
	["39"] = "75corejestercandle",
	["20"] = "58coreresonantanvil",
	["47"] = "81corepowderkeg"
}) do
	var_0_8["unlock_core_" .. iter_0_3] = "src/sprites/icons/menu/upgrade/" .. iter_0_4 .. ".png"
end

for iter_0_5, iter_0_6 in pairs({
	["25"] = "85traitpredatoryinstinct",
	["23"] = "83traitcalculatedluck",
	["11"] = "84traitallydeath",
	["26"] = "87traitversatile",
	["29"] = "88traitanchoredstance",
	["28"] = "86traitrapidstrikes",
	["32"] = "89traitheavyweight"
}) do
	var_0_8["unlock_trait_" .. iter_0_5] = "src/sprites/icons/menu/upgrade/" .. iter_0_6 .. ".png"
end

var_0_8.blastmachine = "src/sprites/icons/menu/upgrade/90blastmachine.png"
var_0_8.blastmastery = "src/sprites/icons/menu/upgrade/91blastmastery.png"

for iter_0_7, iter_0_8 in pairs({
	["17"] = "95itemricochetstone",
	["24"] = "100itemguardiantotem",
	["08"] = "93itemcursedmushroom",
	["37"] = "94itemshieldmanual",
	["07"] = "92itemdustcloak",
	["27"] = "96itemtunnel",
	["40"] = "99itemmagiccircle",
	["45"] = "101itempeddlerspack",
	["23"] = "102itemoverflowingchalice",
	["11"] = "98itemhealingspring",
	["48"] = "103itemburningheart",
	["28"] = "97itemreapershourglass"
}) do
	var_0_8["unlock_item_" .. iter_0_7] = "src/sprites/icons/menu/upgrade/" .. iter_0_8 .. ".png"
end

var_0_8.startessence = "src/sprites/icons/menu/upgrade/104startessence.png"
var_0_8.wingold = "src/sprites/icons/menu/upgrade/105wingold.png"
var_0_8.shopdiscount = "src/sprites/icons/menu/upgrade/106shopdiscount.png"
var_0_8.lastspin = "src/sprites/icons/menu/upgrade/107lastspin.png"

var_0_95("codex", "D01", "slotodds", 3, -80, 0, nil, nil)

var_0_91.codex.reqFullEdition = true
var_0_8.codex = "src/sprites/icons/menu/upgrade/49codex.png"

var_0_95("battlespeed3", "D02", "maxunit3", 60, 200, 200, {
	6,
	1
}, nil)

var_0_8.battlespeed3 = "src/sprites/icons/menu/upgrade/110battlespeed3.png"
var_0_91.factionsynergy.parent = "slotodds"
var_0_91.factionsynergy.posX, var_0_91.factionsynergy.posY = 0, 80
var_0_91.factionsynergy.cost = 15

for iter_0_9, iter_0_10 in pairs({
	slotnudge = {
		"firstcorespin",
		-200,
		40
	},
	interest = {
		"startgold2",
		-260,
		180
	},
	dormantpower = {
		"maxunit2",
		200,
		120
	},
	growthbranch = {
		"maxunit",
		60,
		140
	},
	itemrefund = {
		"unlock_item_07",
		220,
		-140
	}
}) do
	var_0_91[iter_0_9].parent, var_0_91[iter_0_9].posX, var_0_91[iter_0_9].posY = iter_0_10[1], iter_0_10[2], iter_0_10[3]
end

var_0_91.firstcorespin.posX, var_0_91.firstcorespin.posY = -140, -20
var_0_91.firstcoreuncommon.posX, var_0_91.firstcoreuncommon.posY = -220, -20

local var_0_96 = {}

for iter_0_11, iter_0_12 in pairs(var_0_91) do
	local var_0_97 = iter_0_12.unlock

	if var_0_97 then
		var_0_96[var_0_97.kind] = var_0_96[var_0_97.kind] or {}
		var_0_96[var_0_97.kind][var_0_97.id] = iter_0_11
	end
end

var_0_0._unlockNodeFor = var_0_96
var_0_0._demoCoreNodes = {}

for iter_0_13, iter_0_14 in ipairs({
	"19",
	"20",
	"21",
	"22",
	"23",
	"35"
}) do
	var_0_0._demoCoreNodes[#var_0_0._demoCoreNodes + 1] = var_0_96.core[iter_0_14]
end

function var_0_0.isEditionLocked(arg_35_0)
	if not arg_35_0 then
		return false
	end

	if arg_35_0.reqNoDemo and _G.GameEditionMode == "demo" then
		return true
	end

	return arg_35_0.reqFullEdition == true and (_G.GameEditionMode == "demo" or _G.GameEditionMode == "semi_demo")
end

local function var_0_98()
	local var_36_0 = var_0_1 and var_0_1.stageSelect
	local var_36_1 = var_36_0 and var_36_0.clearedDifficulties

	return var_36_1 and var_36_1[1] and var_36_1[1][1] == true
end

local function var_0_99()
	local var_37_0 = var_0_1 and var_0_1.stageSelect
	local var_37_1 = var_37_0 and var_37_0.clearedDifficulties

	return var_37_1 and var_37_1[3] and var_37_1[3][2] == true
end

local function var_0_100(arg_38_0, arg_38_1)
	local var_38_0 = var_0_1 and var_0_1.stageSelect
	local var_38_1 = var_38_0 and var_38_0.clearedDifficulties

	return var_38_1 and var_38_1[arg_38_0] and var_38_1[arg_38_0][arg_38_1] == true
end

local function var_0_101(arg_39_0)
	local var_39_0 = var_0_91 and var_0_91[arg_39_0]

	if var_0_0.isEditionLocked(var_39_0) then
		return false
	end

	if var_39_0 and var_39_0.reqStage then
		if var_39_0.reqFull and _G.GameEditionMode ~= "full" then
			return false
		end

		return var_0_100(var_39_0.reqStage, var_39_0.reqDiff or 1) == true
	end

	if arg_39_0 == "slotadvanced" then
		return var_0_98()
	end

	if arg_39_0 == "itemresearch" then
		return false
	end

	if arg_39_0 == "shoppin" then
		return false
	end

	return true
end

local function var_0_102(arg_40_0)
	if not var_0_0.sectionRewardMet(arg_40_0) then
		return false
	end

	local var_40_0 = var_0_91[arg_40_0]

	if var_40_0 and var_40_0.parent then
		return var_0_91[var_40_0.parent] ~= nil and var_0_91[var_40_0.parent].maxed == true and var_0_101(arg_40_0)
	end

	if arg_40_0 == "noviceshield" then
		return var_0_91.maxhp and var_0_91.maxhp.maxed == true
	end

	if arg_40_0 == "startgold" then
		return var_0_91.maxhp and var_0_91.maxhp.maxed == true
	end

	if arg_40_0 == "startingmerccontract" then
		return var_0_91.startgold and var_0_91.startgold.maxed == true
	end

	if arg_40_0 == "comebackspin" then
		return var_0_91.noviceshield and var_0_91.noviceshield.maxed == true
	end

	if arg_40_0 == "gateheal" then
		return var_0_91.comebackspin and var_0_91.comebackspin.maxed == true
	end

	if arg_40_0 == "comebackgold" then
		return var_0_91.startgold and var_0_91.startgold.maxed == true
	end

	if arg_40_0 == "startgold2" then
		return var_0_91.startgold and var_0_91.startgold.maxed == true
	end

	if arg_40_0 == "maxhp2" then
		return var_0_91.comebackgold and var_0_91.comebackgold.maxed == true
	end

	if arg_40_0 == "maxunit2" then
		return var_0_91.maxunit and var_0_91.maxunit.maxed == true
	end

	if arg_40_0 == "maxunit3" then
		return var_0_91.maxunit2 and var_0_91.maxunit2.maxed == true
	end

	if arg_40_0 == "slotadvanced" then
		return var_0_91.slotadvanced and var_0_91.slotadvanced.maxed == true or var_0_101(arg_40_0)
	end

	if arg_40_0 == "slotadvanced2" then
		return var_0_91.slotadvanced and var_0_91.slotadvanced.maxed == true
	end

	if arg_40_0 == "slotadvanced3" then
		return var_0_91.slotadvanced2 and var_0_91.slotadvanced2.maxed == true
	end

	if arg_40_0 == "slotrare" then
		return var_0_91.slotadvanced3 and var_0_91.slotadvanced3.maxed == true and var_0_101(arg_40_0)
	end

	if arg_40_0 == "corereroll" then
		return var_0_91.slotadvanced and var_0_91.slotadvanced.maxed == true
	end

	if arg_40_0 == "firstcorespin" then
		return var_0_91.corereroll and var_0_91.corereroll.maxed == true
	end

	if arg_40_0 == "firstcoreuncommon" then
		return var_0_91.firstcorespin and var_0_91.firstcorespin.maxed == true
	end

	if arg_40_0 == "shopreroll" then
		return var_0_91.slotadvanced and var_0_91.slotadvanced.maxed == true
	end

	if arg_40_0 == "iteminventory" then
		return var_0_91.shopreroll and var_0_91.shopreroll.maxed == true
	end

	if arg_40_0 == "iteminventory2" then
		return var_0_91.iteminventory and var_0_91.iteminventory.maxed == true
	end

	if arg_40_0 == "itemresearch" then
		return var_0_91.shopreroll and var_0_91.shopreroll.maxed == true and var_0_101(arg_40_0)
	end

	if arg_40_0 == "shoppin" then
		return var_0_91.shopreroll and var_0_91.shopreroll.maxed == true and var_0_101(arg_40_0)
	end

	return true
end

local function var_0_103(arg_41_0)
	return arg_41_0 == "slotadvanced" or arg_41_0 == "itemresearch" or arg_41_0 == "shoppin" or var_0_91[arg_41_0] ~= nil and (var_0_91[arg_41_0].reqStage ~= nil or var_0_91[arg_41_0].reqNoDemo == true or var_0_91[arg_41_0].reqFullEdition == true)
end

local var_0_104 = {
	"difficulty_easy",
	"difficulty_normal",
	"difficulty_hard"
}

local function var_0_105(arg_42_0, arg_42_1)
	local var_42_0 = var_0_91[arg_42_0]

	if var_0_0.isEditionLocked(var_42_0) then
		return var_0_3.getText("full_version_hint", arg_42_1)
	end

	if var_42_0 and var_42_0.reqStage then
		if var_42_0.reqFull and _G.GameEditionMode ~= "full" then
			return var_0_3.getText("full_version_hint", arg_42_1)
		end

		return var_0_3.getText("menu_stage_name_" .. tostring(var_42_0.reqStage), arg_42_1) .. " " .. var_0_3.getText(var_0_104[var_42_0.reqDiff or 1] or "difficulty_easy", arg_42_1) .. " " .. var_0_3.getText("clear_label", arg_42_1)
	end

	if arg_42_0 == "itemresearch" or arg_42_0 == "shoppin" then
		return var_0_3.getText("full_version_hint", arg_42_1)
	end

	if arg_42_0 == "slotadvanced" then
		return var_0_3.getText("clear_open_forest_easy_hint", arg_42_1)
	end

	return nil
end

local function var_0_106(arg_43_0, arg_43_1)
	local var_43_0 = var_0_91[arg_43_0]

	if var_0_0.isEditionLocked(var_43_0) then
		return nil
	end

	if var_43_0 and var_43_0.reqStage then
		if var_43_0.reqFull and _G.GameEditionMode ~= "full" then
			return nil
		end

		return {
			{
				kind = "stage",
				text = var_0_3.getText("menu_stage_name_" .. tostring(var_43_0.reqStage), arg_43_1)
			},
			{
				kind = "difficulty",
				text = var_0_3.getText(var_0_104[var_43_0.reqDiff or 1] or "difficulty_easy", arg_43_1)
			},
			{
				kind = "clear",
				text = var_0_3.getText("clear_label", arg_43_1)
			}
		}
	end

	if arg_43_0 == "itemresearch" or arg_43_0 == "shoppin" then
		return nil
	end

	if arg_43_0 == "slotadvanced" then
		return {
			{
				kind = "stage",
				text = var_0_3.getText("menu_stage_name_1", arg_43_1)
			},
			{
				kind = "difficulty",
				text = var_0_3.getText("difficulty_easy", arg_43_1)
			},
			{
				kind = "clear",
				text = var_0_3.getText("clear_label", arg_43_1)
			}
		}
	end

	return nil
end

local function var_0_107(arg_44_0, arg_44_1)
	if arg_44_0 then
		return {
			stage = {
				var_0_84("#9EDFFF")
			},
			difficulty = {
				var_0_84("#6FAACC")
			},
			clear = {
				var_0_84("#C7F1FF")
			}
		}
	elseif arg_44_1 then
		return {
			stage = {
				var_0_84("#8DFFB2")
			},
			difficulty = {
				var_0_84("#D7FF7A")
			},
			clear = {
				var_0_84("#5FAF6F")
			}
		}
	end

	return {
		stage = {
			var_0_84("#FF9A9A")
		},
		difficulty = {
			var_0_84("#FFB05F")
		},
		clear = {
			var_0_84("#A84F5A")
		}
	}
end

function var_0_0.isPrismOpen()
	local function var_45_0(arg_46_0)
		return var_0_91[arg_46_0] ~= nil and var_0_91[arg_46_0].maxed == true
	end

	return _G.GameEditionMode == "full" and var_45_0("slotrare") and var_45_0("slotprism")
end

function var_0_0.applyUpgradeEffects()
	if var_0_2 and var_0_2.slot then
		var_0_2.slot.winSuppressProb = 0
		var_0_2.slot.forceWinProb = 0
	end

	if var_0_2 and var_0_2.unitGrades and var_0_2.unitGrades.probabilities then
		local var_47_0 = var_0_2.unitGrades.probabilities

		local function var_47_1(arg_48_0)
			return var_0_91[arg_48_0] ~= nil and var_0_91[arg_48_0].maxed == true
		end

		local var_47_2 = _G.GameEditionMode == "full"
		local var_47_3 = _G.GameEditionMode == "semi_demo" and 0.02 or 0
		local var_47_4 = 0
		local var_47_5 = 0

		if var_47_2 and var_47_1("slotrare") then
			var_47_0.advanced = 0.15
			var_47_3 = var_47_1("slotrare3") and 0.045 or var_47_1("slotrare2") and 0.03 or 0.02

			if var_47_1("slotlegend") then
				var_47_4 = var_47_1("slotlegend3") and 0.004 or var_47_1("slotlegend2") and 0.002 or 0.001
			end

			if var_47_1("slotprism") then
				var_47_5 = var_47_1("slotprism3") and 0.001 or var_47_1("slotprism2") and 0.0005 or 0.0002
			end
		elseif var_47_1("slotadvanced3") then
			var_47_0.advanced = 0.15
		elseif var_47_1("slotadvanced2") then
			var_47_0.advanced = 0.1
		elseif var_47_1("slotadvanced") then
			var_47_0.advanced = 0.05
		else
			var_47_0.advanced = 0
		end

		var_47_0.rare = var_47_3
		var_47_0.legendary = var_47_4
		var_47_0.prism = var_47_5
		var_47_0.normal = 1 - var_47_0.advanced - var_47_3 - var_47_4 - var_47_5

		local var_47_6, var_47_7 = pcall(require, "src.game.luck")

		if var_47_6 and type(var_47_7) == "table" and type(var_47_7.grade) == "table" and var_47_7.grade.setResearch then
			local var_47_8 = 0

			if var_47_2 and var_47_1("slotrare") and var_47_1("slotlegend") then
				var_47_8 = var_47_1("slotlegend3") and 3 or var_47_1("slotlegend2") and 2 or 1
			end

			var_47_7.grade.setResearch({
				full = var_47_2,
				rare = var_47_2 and var_47_1("slotrare"),
				legendaryTier = var_47_8
			})
		end
	end
end

var_0_0.applyUpgradeEffects()

function var_0_0.getUpgradeState()
	local var_49_0 = {}

	for iter_49_0, iter_49_1 in pairs(var_0_91) do
		if iter_49_1.maxed then
			var_49_0[iter_49_0] = true
		end
	end

	var_49_0.__tree2 = true
	var_49_0.__codex = true
	var_49_0.__standRoll = var_0_0._standRoll or 0
	var_49_0.__standSold = var_0_0._standSold and 1 or nil
	var_49_0.__standCarry = var_0_0._standCarry and {
		unpack(var_0_0._standCarry)
	} or nil

	if var_0_0._coreFav then
		local var_49_1 = {}
		local var_49_2 = {}
		local var_49_3 = false

		for iter_49_2 = 1, 2 do
			var_49_1[iter_49_2] = var_0_0._coreFav[iter_49_2] or ""
			var_49_2[iter_49_2] = var_0_0._coreFav[iter_49_2] and not var_0_0.isCoreFavoriteOn(iter_49_2) and 1 or 0
			var_49_3 = var_49_3 or var_49_2[iter_49_2] == 1
		end

		var_49_0.__coreFav = var_49_1
		var_49_0.__coreFavOff = var_49_3 and var_49_2 or nil
	end

	return var_49_0
end

function var_0_0.setUpgradeState(arg_50_0)
	if not arg_50_0 then
		return
	end

	var_0_0._sandboxUnlockRestore = nil

	if arg_50_0.stonejester and arg_50_0.stonespecial == nil then
		arg_50_0.stonespecial = true
	end

	var_0_0._legacyTreeState = arg_50_0.__tree2 ~= true
	var_0_0._standRoll = math.max(0, math.floor(tonumber(arg_50_0.__standRoll) or 0))
	var_0_0._standSold = tonumber(arg_50_0.__standSold) == 1 or nil
	var_0_0._standCarry = nil
	var_0_0._coreFav, var_0_0._coreFavOff = nil

	if type(arg_50_0.__coreFav) == "table" then
		local var_50_0 = {}
		local var_50_1 = {}

		for iter_50_0 = 1, 2 do
			local var_50_2 = arg_50_0.__coreFav[iter_50_0]

			var_50_0[iter_50_0] = type(var_50_2) == "string" and var_50_2 ~= "" and var_50_2 or nil
			var_50_1[iter_50_0] = var_50_0[iter_50_0] and type(arg_50_0.__coreFavOff) == "table" and tonumber(arg_50_0.__coreFavOff[iter_50_0]) == 1 or nil
		end

		var_0_0._coreFav, var_0_0._coreFavOff = var_50_0, var_50_1
	end

	if type(arg_50_0.__standCarry) == "table" then
		local var_50_3 = {}

		for iter_50_1, iter_50_2 in ipairs(arg_50_0.__standCarry) do
			if type(iter_50_2) == "string" then
				var_50_3[#var_50_3 + 1] = iter_50_2
			end
		end

		var_0_0._standCarry = #var_50_3 > 0 and var_50_3 or nil
	end

	for iter_50_3, iter_50_4 in pairs(var_0_91) do
		if not arg_50_0[iter_50_3] then
			iter_50_4.maxed = false
		else
			iter_50_4.maxed = true
		end
	end

	if arg_50_0.__codex ~= true and var_0_91.codex and not var_0_91.codex.maxed then
		for iter_50_5, iter_50_6 in pairs(var_0_91) do
			if iter_50_6.maxed then
				var_0_91.codex.maxed = true

				break
			end
		end
	end

	if not var_0_91.slotodds.maxed then
		local var_50_4 = var_0_72("maxunit")

		var_50_4.revealed = false
		var_50_4.unlockLineProgress = 0
		var_50_4.isAppearing = false
		var_50_4.isDisappearing = false
		var_50_4.scaleX = 0
		var_50_4.scaleY = 0

		local var_50_5 = var_0_72("maxhp")

		var_50_5.revealed = false
		var_50_5.unlockLineProgress = 0
		var_50_5.isAppearing = false
		var_50_5.isDisappearing = false
		var_50_5.scaleX = 0
		var_50_5.scaleY = 0

		local var_50_6 = var_0_72("noviceshield")

		var_50_6.revealed = false
		var_50_6.unlockLineProgress = 0
		var_50_6.isAppearing = false
		var_50_6.isDisappearing = false
		var_50_6.scaleX = 0
		var_50_6.scaleY = 0

		local var_50_7 = var_0_72("startgold")

		var_50_7.revealed = false
		var_50_7.unlockLineProgress = 0
		var_50_7.isAppearing = false
		var_50_7.isDisappearing = false
		var_50_7.scaleX = 0
		var_50_7.scaleY = 0

		local var_50_8 = var_0_72("comebackspin")

		var_50_8.revealed = false
		var_50_8.unlockLineProgress = 0
		var_50_8.isAppearing = false
		var_50_8.isDisappearing = false
		var_50_8.scaleX = 0
		var_50_8.scaleY = 0

		local var_50_9 = var_0_72("gateheal")

		var_50_9.revealed = false
		var_50_9.unlockLineProgress = 0
		var_50_9.isAppearing = false
		var_50_9.isDisappearing = false
		var_50_9.scaleX = 0
		var_50_9.scaleY = 0

		local var_50_10 = var_0_72("comebackgold")

		var_50_10.revealed = false
		var_50_10.unlockLineProgress = 0
		var_50_10.isAppearing = false
		var_50_10.isDisappearing = false
		var_50_10.scaleX = 0
		var_50_10.scaleY = 0

		local var_50_11 = var_0_72("maxhp2")

		var_50_11.revealed = false
		var_50_11.unlockLineProgress = 0
		var_50_11.isAppearing = false
		var_50_11.isDisappearing = false
		var_50_11.scaleX = 0
		var_50_11.scaleY = 0

		local var_50_12 = var_0_72("startgold2")

		var_50_12.revealed = false
		var_50_12.unlockLineProgress = 0
		var_50_12.isAppearing = false
		var_50_12.isDisappearing = false
		var_50_12.scaleX = 0
		var_50_12.scaleY = 0

		local var_50_13 = var_0_72("slotnudge")

		var_50_13.revealed = false
		var_50_13.unlockLineProgress = 0
		var_50_13.isAppearing = false
		var_50_13.isDisappearing = false
		var_50_13.scaleX = 0
		var_50_13.scaleY = 0

		local var_50_14 = var_0_72("preptime")

		var_50_14.revealed = false
		var_50_14.unlockLineProgress = 0
		var_50_14.isAppearing = false
		var_50_14.isDisappearing = false
		var_50_14.scaleX = 0
		var_50_14.scaleY = 0

		local var_50_15 = var_0_72("maxunit2")

		var_50_15.revealed = false
		var_50_15.unlockLineProgress = 0
		var_50_15.isAppearing = false
		var_50_15.isDisappearing = false
		var_50_15.scaleX = 0
		var_50_15.scaleY = 0

		local var_50_16 = var_0_72("maxunit3")

		var_50_16.revealed = false
		var_50_16.unlockLineProgress = 0
		var_50_16.isAppearing = false
		var_50_16.isDisappearing = false
		var_50_16.scaleX = 0
		var_50_16.scaleY = 0

		local var_50_17 = var_0_72("interest")

		var_50_17.revealed = false
		var_50_17.unlockLineProgress = 0
		var_50_17.isAppearing = false
		var_50_17.isDisappearing = false
		var_50_17.scaleX = 0
		var_50_17.scaleY = 0

		local var_50_18 = var_0_72("preptime2")

		var_50_18.revealed = false
		var_50_18.unlockLineProgress = 0
		var_50_18.isAppearing = false
		var_50_18.isDisappearing = false
		var_50_18.scaleX = 0
		var_50_18.scaleY = 0

		local var_50_19 = var_0_72("preptimerdisabled")

		var_50_19.revealed = false
		var_50_19.unlockLineProgress = 0
		var_50_19.isAppearing = false
		var_50_19.isDisappearing = false
		var_50_19.scaleX = 0
		var_50_19.scaleY = 0

		local var_50_20 = var_0_72("slotadvanced")

		var_50_20.revealed = false
		var_50_20.unlockLineProgress = 0
		var_50_20.isAppearing = false
		var_50_20.isDisappearing = false
		var_50_20.scaleX = 0
		var_50_20.scaleY = 0

		local var_50_21 = var_0_72("slotadvanced2")

		var_50_21.revealed = false
		var_50_21.unlockLineProgress = 0
		var_50_21.isAppearing = false
		var_50_21.isDisappearing = false
		var_50_21.scaleX = 0
		var_50_21.scaleY = 0

		local var_50_22 = var_0_72("corereroll")

		var_50_22.revealed = false
		var_50_22.unlockLineProgress = 0
		var_50_22.isAppearing = false
		var_50_22.isDisappearing = false
		var_50_22.scaleX = 0
		var_50_22.scaleY = 0

		local var_50_23 = var_0_72("firstcorespin")

		var_50_23.revealed = false
		var_50_23.unlockLineProgress = 0
		var_50_23.isAppearing = false
		var_50_23.isDisappearing = false
		var_50_23.scaleX = 0
		var_50_23.scaleY = 0

		local var_50_24 = var_0_72("firstcoreuncommon")

		var_50_24.revealed = false
		var_50_24.unlockLineProgress = 0
		var_50_24.isAppearing = false
		var_50_24.isDisappearing = false
		var_50_24.scaleX = 0
		var_50_24.scaleY = 0

		local var_50_25 = var_0_72("shopreroll")

		var_50_25.revealed = false
		var_50_25.unlockLineProgress = 0
		var_50_25.isAppearing = false
		var_50_25.isDisappearing = false
		var_50_25.scaleX = 0
		var_50_25.scaleY = 0

		local var_50_26 = var_0_72("iteminventory")

		var_50_26.revealed = false
		var_50_26.unlockLineProgress = 0
		var_50_26.isAppearing = false
		var_50_26.isDisappearing = false
		var_50_26.scaleX = 0
		var_50_26.scaleY = 0

		local var_50_27 = var_0_72("itemrefund")

		var_50_27.revealed = false
		var_50_27.unlockLineProgress = 0
		var_50_27.isAppearing = false
		var_50_27.isDisappearing = false
		var_50_27.scaleX = 0
		var_50_27.scaleY = 0

		local var_50_28 = var_0_72("iteminventory2")

		var_50_28.revealed = false
		var_50_28.unlockLineProgress = 0
		var_50_28.isAppearing = false
		var_50_28.isDisappearing = false
		var_50_28.scaleX = 0
		var_50_28.scaleY = 0

		local var_50_29 = var_0_72("itemresearch")

		var_50_29.revealed = false
		var_50_29.unlockLineProgress = 0
		var_50_29.isAppearing = false
		var_50_29.isDisappearing = false
		var_50_29.scaleX = 0
		var_50_29.scaleY = 0

		local var_50_30 = var_0_72("shoppin")

		var_50_30.revealed = false
		var_50_30.unlockLineProgress = 0
		var_50_30.isAppearing = false
		var_50_30.isDisappearing = false
		var_50_30.scaleX = 0
		var_50_30.scaleY = 0

		local var_50_31 = var_0_72("slotadvanced3")

		var_50_31.revealed = false
		var_50_31.unlockLineProgress = 0
		var_50_31.isAppearing = false
		var_50_31.isDisappearing = false
		var_50_31.scaleX = 0
		var_50_31.scaleY = 0

		local var_50_32 = var_0_72("slotrare")

		var_50_32.revealed = false
		var_50_32.unlockLineProgress = 0
		var_50_32.isAppearing = false
		var_50_32.isDisappearing = false
		var_50_32.scaleX = 0
		var_50_32.scaleY = 0
	else
		local var_50_33 = var_0_72("maxunit")

		var_50_33.revealed = true
		var_50_33.unlockLineProgress = 1
		var_50_33.isAppearing = false
		var_50_33.scaleX = 1
		var_50_33.scaleY = 1

		local var_50_34 = var_0_72("maxhp")

		var_50_34.revealed = true
		var_50_34.unlockLineProgress = 1
		var_50_34.isAppearing = false
		var_50_34.scaleX = 1
		var_50_34.scaleY = 1

		local var_50_35 = var_0_72("noviceshield")
		local var_50_36 = var_0_91.maxhp and var_0_91.maxhp.maxed == true

		var_50_35.revealed = var_50_36
		var_50_35.unlockLineProgress = var_50_36 and 1 or 0
		var_50_35.isAppearing = false
		var_50_35.scaleX = var_50_36 and 1 or 0
		var_50_35.scaleY = var_50_36 and 1 or 0

		local var_50_37 = var_0_72("startgold")

		var_50_37.revealed = var_50_36
		var_50_37.unlockLineProgress = var_50_36 and 1 or 0
		var_50_37.isAppearing = false
		var_50_37.scaleX = var_50_36 and 1 or 0
		var_50_37.scaleY = var_50_36 and 1 or 0

		local var_50_38 = var_0_72("comebackspin")
		local var_50_39 = var_0_91.noviceshield and var_0_91.noviceshield.maxed == true

		var_50_38.revealed = var_50_39
		var_50_38.unlockLineProgress = var_50_39 and 1 or 0
		var_50_38.isAppearing = false
		var_50_38.scaleX = var_50_39 and 1 or 0
		var_50_38.scaleY = var_50_39 and 1 or 0

		local var_50_40 = var_0_72("gateheal")
		local var_50_41 = var_0_91.comebackspin and var_0_91.comebackspin.maxed == true

		var_50_40.revealed = var_50_41
		var_50_40.unlockLineProgress = var_50_41 and 1 or 0
		var_50_40.isAppearing = false
		var_50_40.scaleX = var_50_41 and 1 or 0
		var_50_40.scaleY = var_50_41 and 1 or 0

		local var_50_42 = var_0_72("comebackgold")
		local var_50_43 = var_0_91.startgold and var_0_91.startgold.maxed == true

		var_50_42.revealed = var_50_43
		var_50_42.unlockLineProgress = var_50_43 and 1 or 0
		var_50_42.isAppearing = false
		var_50_42.scaleX = var_50_43 and 1 or 0
		var_50_42.scaleY = var_50_43 and 1 or 0

		local var_50_44 = var_0_72("maxhp2")
		local var_50_45 = var_0_91.comebackgold and var_0_91.comebackgold.maxed == true

		var_50_44.revealed = var_50_45
		var_50_44.unlockLineProgress = var_50_45 and 1 or 0
		var_50_44.isAppearing = false
		var_50_44.scaleX = var_50_45 and 1 or 0
		var_50_44.scaleY = var_50_45 and 1 or 0

		local var_50_46 = var_0_72("startgold2")

		var_50_46.revealed = var_50_43
		var_50_46.unlockLineProgress = var_50_43 and 1 or 0
		var_50_46.isAppearing = false
		var_50_46.scaleX = var_50_43 and 1 or 0
		var_50_46.scaleY = var_50_43 and 1 or 0

		local var_50_47 = var_0_72("slotnudge")
		local var_50_48 = var_0_91.maxunit and var_0_91.maxunit.maxed == true

		var_50_47.revealed = var_50_48
		var_50_47.unlockLineProgress = var_50_48 and 1 or 0
		var_50_47.isAppearing = false
		var_50_47.scaleX = var_50_48 and 1 or 0
		var_50_47.scaleY = var_50_48 and 1 or 0

		local var_50_49 = var_0_72("preptime")

		var_50_49.revealed = false
		var_50_49.unlockLineProgress = 0
		var_50_49.isAppearing = false
		var_50_49.scaleX = 0
		var_50_49.scaleY = 0

		local var_50_50 = var_0_72("maxunit2")

		var_50_50.revealed = var_50_48
		var_50_50.unlockLineProgress = var_50_48 and 1 or 0
		var_50_50.isAppearing = false
		var_50_50.scaleX = var_50_48 and 1 or 0
		var_50_50.scaleY = var_50_48 and 1 or 0

		local var_50_51 = var_0_72("maxunit3")
		local var_50_52 = var_0_91.maxunit2 and var_0_91.maxunit2.maxed == true

		var_50_51.revealed = var_50_52
		var_50_51.unlockLineProgress = var_50_52 and 1 or 0
		var_50_51.isAppearing = false
		var_50_51.scaleX = var_50_52 and 1 or 0
		var_50_51.scaleY = var_50_52 and 1 or 0

		local var_50_53 = var_0_72("interest")

		var_50_53.revealed = var_50_48
		var_50_53.unlockLineProgress = var_50_48 and 1 or 0
		var_50_53.isAppearing = false
		var_50_53.scaleX = var_50_48 and 1 or 0
		var_50_53.scaleY = var_50_48 and 1 or 0

		local var_50_54 = var_0_72("preptime2")

		var_50_54.revealed = false
		var_50_54.unlockLineProgress = 0
		var_50_54.isAppearing = false
		var_50_54.scaleX = 0
		var_50_54.scaleY = 0

		local var_50_55 = var_0_72("preptimerdisabled")

		var_50_55.revealed = false
		var_50_55.unlockLineProgress = 0
		var_50_55.isAppearing = false
		var_50_55.scaleX = 0
		var_50_55.scaleY = 0

		local var_50_56 = var_0_72("slotadvanced")

		var_50_56.revealed = true
		var_50_56.unlockLineProgress = 1
		var_50_56.isAppearing = false
		var_50_56.scaleX = 1
		var_50_56.scaleY = 1

		local var_50_57 = var_0_72("slotadvanced2")
		local var_50_58 = var_0_91.slotadvanced and var_0_91.slotadvanced.maxed == true

		var_50_57.revealed = var_50_58
		var_50_57.unlockLineProgress = var_50_58 and 1 or 0
		var_50_57.isAppearing = false
		var_50_57.scaleX = var_50_58 and 1 or 0
		var_50_57.scaleY = var_50_58 and 1 or 0

		local var_50_59 = var_0_72("corereroll")

		var_50_59.revealed = var_50_58
		var_50_59.unlockLineProgress = var_50_58 and 1 or 0
		var_50_59.isAppearing = false
		var_50_59.scaleX = var_50_58 and 1 or 0
		var_50_59.scaleY = var_50_58 and 1 or 0

		local var_50_60 = var_0_72("firstcorespin")
		local var_50_61 = var_0_91.corereroll and var_0_91.corereroll.maxed == true

		var_50_60.revealed = var_50_61
		var_50_60.unlockLineProgress = var_50_61 and 1 or 0
		var_50_60.isAppearing = false
		var_50_60.scaleX = var_50_61 and 1 or 0
		var_50_60.scaleY = var_50_61 and 1 or 0

		local var_50_62 = var_0_72("firstcoreuncommon")
		local var_50_63 = var_0_91.firstcorespin and var_0_91.firstcorespin.maxed == true

		var_50_62.revealed = var_50_63
		var_50_62.unlockLineProgress = var_50_63 and 1 or 0
		var_50_62.isAppearing = false
		var_50_62.scaleX = var_50_63 and 1 or 0
		var_50_62.scaleY = var_50_63 and 1 or 0

		local var_50_64 = var_0_72("shopreroll")

		var_50_64.revealed = var_50_58
		var_50_64.unlockLineProgress = var_50_58 and 1 or 0
		var_50_64.isAppearing = false
		var_50_64.scaleX = var_50_58 and 1 or 0
		var_50_64.scaleY = var_50_58 and 1 or 0

		local var_50_65 = var_0_72("iteminventory")
		local var_50_66 = var_0_91.shopreroll and var_0_91.shopreroll.maxed == true

		var_50_65.revealed = var_50_66
		var_50_65.unlockLineProgress = var_50_66 and 1 or 0
		var_50_65.isAppearing = false
		var_50_65.scaleX = var_50_66 and 1 or 0
		var_50_65.scaleY = var_50_66 and 1 or 0

		local var_50_67 = var_0_72("itemrefund")
		local var_50_68 = var_0_91.iteminventory and var_0_91.iteminventory.maxed == true

		var_50_67.revealed = var_50_68
		var_50_67.unlockLineProgress = var_50_68 and 1 or 0
		var_50_67.isAppearing = false
		var_50_67.scaleX = var_50_68 and 1 or 0
		var_50_67.scaleY = var_50_68 and 1 or 0

		local var_50_69 = var_0_72("iteminventory2")

		var_50_69.revealed = var_50_68
		var_50_69.unlockLineProgress = var_50_68 and 1 or 0
		var_50_69.isAppearing = false
		var_50_69.scaleX = var_50_68 and 1 or 0
		var_50_69.scaleY = var_50_68 and 1 or 0

		local var_50_70 = var_0_72("itemresearch")

		var_50_70.revealed = var_50_66
		var_50_70.unlockLineProgress = var_50_66 and 1 or 0
		var_50_70.isAppearing = false
		var_50_70.scaleX = var_50_66 and 1 or 0
		var_50_70.scaleY = var_50_66 and 1 or 0

		local var_50_71 = var_0_72("shoppin")

		var_50_71.revealed = var_50_66
		var_50_71.unlockLineProgress = var_50_66 and 1 or 0
		var_50_71.isAppearing = false
		var_50_71.scaleX = var_50_66 and 1 or 0
		var_50_71.scaleY = var_50_66 and 1 or 0

		local var_50_72 = var_0_72("slotadvanced3")
		local var_50_73 = var_0_91.slotadvanced2 and var_0_91.slotadvanced2.maxed == true

		var_50_72.revealed = var_50_73
		var_50_72.unlockLineProgress = var_50_73 and 1 or 0
		var_50_72.isAppearing = false
		var_50_72.scaleX = var_50_73 and 1 or 0
		var_50_72.scaleY = var_50_73 and 1 or 0

		local var_50_74 = var_0_72("slotrare")
		local var_50_75 = var_0_91.slotadvanced3 and var_0_91.slotadvanced3.maxed == true

		var_50_74.revealed = var_50_75
		var_50_74.unlockLineProgress = var_50_75 and 1 or 0
		var_50_74.isAppearing = false
		var_50_74.scaleX = var_50_75 and 1 or 0
		var_50_74.scaleY = var_50_75 and 1 or 0
	end

	local var_50_76 = var_0_72("startingmerccontract")
	local var_50_77 = var_0_91.slotodds and var_0_91.slotodds.maxed == true and var_0_91.startgold and var_0_91.startgold.maxed == true

	var_50_76.revealed = var_50_77
	var_50_76.unlockLineProgress = var_50_77 and 1 or 0
	var_50_76.isAppearing = false
	var_50_76.isDisappearing = false
	var_50_76.scaleX = var_50_77 and 1 or 0
	var_50_76.scaleY = var_50_77 and 1 or 0

	for iter_50_7, iter_50_8 in pairs(var_0_91) do
		if iter_50_8.parent then
			local var_50_78 = var_0_72(iter_50_7)
			local var_50_79 = var_0_91.slotodds.maxed == true and var_0_91[iter_50_8.parent] ~= nil and (var_0_91[iter_50_8.parent].maxed == true or iter_50_8.maxed == true)

			var_50_78.revealed = var_50_79
			var_50_78.unlockLineProgress = var_50_79 and 1 or 0
			var_50_78.isAppearing = false
			var_50_78.isDisappearing = false
			var_50_78.scaleX = var_50_79 and 1 or 0
			var_50_78.scaleY = var_50_79 and 1 or 0
		end
	end

	var_0_0.applyUpgradeEffects()
end

function var_0_0.toggleSandboxUnlockAll()
	if not var_0_0.isSandboxActive() then
		return false
	end

	local var_51_0 = var_0_0._sandboxUnlockRestore

	if not var_51_0 then
		local var_51_1 = var_0_0.getUpgradeState()
		local var_51_2 = var_0_0.getUpgradeState()

		for iter_51_0 in pairs(var_0_91) do
			var_51_2[iter_51_0] = true
		end

		var_0_0.setUpgradeState(var_51_2)

		var_0_0._sandboxUnlockRestore = var_51_1
	else
		var_0_0.setUpgradeState(var_51_0)
	end

	for iter_51_1, iter_51_2 in pairs(var_0_71) do
		iter_51_2.pressed, iter_51_2.isPopping = false, false
		iter_51_2.pressTimer, iter_51_2.popTimer, iter_51_2.flashT, iter_51_2.shakeT = 0, 0, 0, 0
		iter_51_2.energyParticles = {}
	end

	var_0_74, var_0_75, var_0_77 = nil

	return true
end

function var_0_0.sandboxUnlockHover(arg_52_0, arg_52_1)
	local var_52_0 = var_0_70.unlockAll

	var_0_0._sandboxAllHover = var_0_0.isSandboxActive() and var_52_0 and arg_52_0 and arg_52_1 and arg_52_0 >= var_52_0.x and arg_52_0 < var_52_0.x + var_52_0.w and arg_52_1 >= var_52_0.y and arg_52_1 < var_52_0.y + var_52_0.h or false

	return var_0_0._sandboxAllHover
end

function var_0_0.drawSandboxUnlockAll(arg_53_0, arg_53_1)
	var_0_70.unlockAll = nil

	if not var_0_0.isSandboxActive() then
		var_0_0._sandboxAllHover = false

		return
	end

	local var_53_0 = love.graphics
	local var_53_1 = require("src.ui.widgets").text_fit
	local var_53_2 = var_0_0.getTooltipFont() or var_53_0.getFont()
	local var_53_3 = var_0_36()
	local var_53_4 = var_0_3.getText("upgrade_sandbox_unlock_all", var_53_3)
	local var_53_5 = math.min(arg_53_0.virtual.W - 40, math.max(132, math.ceil(var_53_2:getWidth(var_53_4)) + 44))
	local var_53_6 = math.max(30, var_53_2:getHeight() + 16)
	local var_53_7 = {
		x = math.floor(arg_53_0.virtual.W - 20 - var_53_5),
		y = math.floor(arg_53_1),
		w = var_53_5,
		h = var_53_6
	}

	var_0_70.unlockAll = var_53_7

	local var_53_8 = var_0_0._sandboxUnlockRestore ~= nil

	var_53_0.push("all")
	var_53_0.setColor(0.11, 0.08, 0.16, 0.97)
	var_53_0.rectangle("fill", var_53_7.x, var_53_7.y, var_53_7.w, var_53_7.h)

	if var_53_8 then
		var_53_0.setColor(0.82, 0.7, 0.44, 1)
	elseif var_0_0._sandboxAllHover then
		var_53_0.setColor(0.72, 0.65, 0.84, 1)
	else
		var_53_0.setColor(0.45, 0.38, 0.55, 1)
	end

	var_53_0.rectangle("fill", var_53_7.x, var_53_7.y, var_53_7.w, 1)
	var_53_0.rectangle("fill", var_53_7.x, var_53_7.y + var_53_7.h - 1, var_53_7.w, 1)
	var_53_0.rectangle("fill", var_53_7.x, var_53_7.y, 1, var_53_7.h)
	var_53_0.rectangle("fill", var_53_7.x + var_53_7.w - 1, var_53_7.y, 1, var_53_7.h)

	local var_53_9 = var_53_7.y + math.floor((var_53_7.h - 12) / 2)

	var_53_0.rectangle("fill", var_53_7.x + 10, var_53_9, 12, 12)
	var_53_0.setColor(0.11, 0.08, 0.16, 1)
	var_53_0.rectangle("fill", var_53_7.x + 11, var_53_9 + 1, 10, 10)

	if var_53_8 then
		var_53_0.setColor(0.66, 0.89, 0.64, 1)
		var_53_0.rectangle("fill", var_53_7.x + 13, var_53_9 + 3, 6, 6)
	end

	local var_53_10 = var_53_1.fit(var_53_4, var_53_7.w - 42, var_53_2, {
		maxLines = 1,
		maxH = var_53_7.h - 16,
		lang = var_53_3
	})

	var_53_0.setColor(0.94, 0.91, 0.84, 1)
	var_53_1.draw(var_53_10, var_53_7.x + 32, var_53_7.y + 8, var_53_7.w - 42, var_53_7.h - 16, {
		key = "upgrade_sandbox_unlock_all"
	})
	var_53_0.pop()
end

local function var_0_108(arg_54_0, arg_54_1, arg_54_2, arg_54_3)
	local var_54_0 = {}
	local var_54_1 = 1

	arg_54_0 = tostring(arg_54_0 or "")

	while var_54_1 <= #arg_54_0 do
		local var_54_2, var_54_3, var_54_4 = arg_54_0:find("{([%w_]+)%.png}", var_54_1)
		local var_54_5, var_54_6 = arg_54_0:find("{infinity}", var_54_1, true)
		local var_54_7
		local var_54_8
		local var_54_9

		if var_54_2 and (not var_54_5 or var_54_2 < var_54_5) then
			var_54_7, var_54_8, var_54_9 = var_54_2, var_54_3, var_54_4 == "gold" and "gold" or "staticon"
		elseif var_54_5 then
			var_54_7, var_54_8, var_54_9 = var_54_5, var_54_6, "infinity"
		end

		if not var_54_7 then
			local var_54_10 = arg_54_0:sub(var_54_1)

			if #var_54_10 > 0 then
				table.insert(var_54_0, {
					type = "text",
					text = var_54_10
				})
			end

			break
		end

		if var_54_1 < var_54_7 then
			table.insert(var_54_0, {
				type = "text",
				text = arg_54_0:sub(var_54_1, var_54_7 - 1)
			})
		end

		local var_54_11 = var_54_8 + 1

		if var_54_9 == "infinity" then
			table.insert(var_54_0, {
				type = "infinity",
				fallback = "INF"
			})

			var_54_1 = var_54_11
		elseif var_54_9 == "staticon" then
			local var_54_12, var_54_13 = pcall(require("src.data.assets").getTooltipStatIcon, nil, var_54_4)

			if var_54_12 and var_54_13 then
				table.insert(var_54_0, {
					type = "icon",
					fallback = "",
					icon = var_54_13
				})
			end

			var_54_1 = var_54_11
		else
			local var_54_14 = arg_54_0:sub(var_54_11)
			local var_54_15, var_54_16 = var_54_14:match("^(%s*)(%S+)")

			if not var_54_16 then
				table.insert(var_54_0, {
					type = "icon",
					fallback = "G",
					icon = var_0_13
				})

				var_54_1 = var_54_11
			else
				local var_54_17, var_54_18 = var_54_16:match("^(%d+)(.*)$")
				local var_54_19 = 0

				if var_54_17 and (not var_54_18 or var_54_18 == "") then
					local var_54_20, var_54_21 = var_54_14:sub(#var_54_15 + #var_54_16 + 1):match("^(%s+)(%S+)")

					if var_54_21 == "s" or var_54_21 == "sec" or var_54_21 == "seconds" then
						var_54_18 = var_54_21
						var_54_19 = #var_54_20 + #var_54_21
					end
				end

				table.insert(var_54_0, {
					type = "iconword",
					icon = var_0_13,
					word = var_54_16,
					number = var_54_17,
					suffix = var_54_18,
					fallback = "G" .. var_54_16
				})

				var_54_1 = var_54_11 + #var_54_15 + #var_54_16 + var_54_19
			end
		end
	end

	return var_54_0
end

local function var_0_109(arg_55_0)
	arg_55_0 = tostring(arg_55_0 or "")

	return arg_55_0:find("{[%w_]+%.png}") ~= nil or arg_55_0:find("{infinity}", 1, true) ~= nil
end

local function var_0_110(arg_56_0, arg_56_1, arg_56_2)
	arg_56_0 = tostring(arg_56_0 or "")
	arg_56_2 = arg_56_2 or 1

	local var_56_0 = rawget(_G, "measureChineseMixedTextWidth")

	if type(var_56_0) == "function" then
		local var_56_1, var_56_2 = pcall(var_56_0, arg_56_0, arg_56_1)

		if var_56_1 and type(var_56_2) == "number" then
			return var_56_2 * arg_56_2
		end
	end

	return arg_56_1:getWidth(arg_56_0) * arg_56_2
end

function var_0_0.requirementRowWidth(arg_57_0, arg_57_1, arg_57_2, arg_57_3, arg_57_4, arg_57_5)
	return var_0_110(arg_57_0, arg_57_2, arg_57_3) + var_0_110(" ", arg_57_2, arg_57_3) + var_0_110(arg_57_1, arg_57_2, arg_57_3) + arg_57_4 + arg_57_5
end

function var_0_0.drawRequirementRow(arg_58_0)
	local var_58_0 = arg_58_0.maxed and {
		var_0_84("#6FAACC")
	} or arg_58_0.met and {
		var_0_84("#5FAF6F")
	} or {
		var_0_84("#A84F5A")
	}
	local var_58_1 = var_0_107(arg_58_0.maxed, arg_58_0.met)

	var_0_89(math.floor(arg_58_0.barX), math.floor(arg_58_0.y), math.floor(arg_58_0.barW), math.floor(arg_58_0.h), {
		var_58_0[1] * 0.25,
		var_58_0[2] * 0.25,
		var_58_0[3] * 0.25,
		1
	}, nil)

	local var_58_2 = var_0_88()
	local var_58_3 = math.floor(arg_58_0.x)
	local var_58_4 = math.floor(arg_58_0.box)
	local var_58_5 = math.floor(arg_58_0.y + math.floor((arg_58_0.h - arg_58_0.box) / 2))

	local function var_58_6(arg_59_0)
		love.graphics.rectangle("fill", var_58_3, var_58_5 + arg_59_0, var_58_4, var_58_2)
		love.graphics.rectangle("fill", var_58_3, var_58_5 + arg_59_0 + var_58_4 - var_58_2, var_58_4, var_58_2)
		love.graphics.rectangle("fill", var_58_3, var_58_5 + arg_59_0, var_58_2, var_58_4)
		love.graphics.rectangle("fill", var_58_3 + var_58_4 - var_58_2, var_58_5 + arg_59_0, var_58_2, var_58_4)

		if arg_58_0.met then
			for iter_59_0, iter_59_1 in ipairs({
				{
					2,
					5
				},
				{
					3,
					6
				},
				{
					4,
					5
				},
				{
					5,
					4
				},
				{
					6,
					3
				},
				{
					7,
					2
				}
			}) do
				love.graphics.rectangle("fill", var_58_3 + iter_59_1[1] * var_58_2, var_58_5 + arg_59_0 + iter_59_1[2] * var_58_2, var_58_2, var_58_2)
			end
		end
	end

	love.graphics.setColor(0, 0, 0, 0.45)
	var_58_6(var_58_2)
	love.graphics.setColor(var_58_0[1], var_58_0[2], var_58_0[3], 1)
	var_58_6(0)

	local var_58_7 = arg_58_0.x + arg_58_0.box + arg_58_0.gap
	local var_58_8 = math.floor(arg_58_0.y + math.floor((arg_58_0.h - arg_58_0.textH) / 2) - 2)
	local var_58_9 = var_58_1.stage

	love.graphics.setColor(var_58_9[1], var_58_9[2], var_58_9[3], 1)
	love.graphics.print(arg_58_0.label, math.floor(var_58_7), var_58_8, 0, arg_58_0.scale, arg_58_0.scale)

	local var_58_10 = var_58_7 + var_0_110(arg_58_0.label, arg_58_0.font, arg_58_0.scale) + var_0_110(" ", arg_58_0.font, arg_58_0.scale)
	local var_58_11 = var_58_1.difficulty

	love.graphics.setColor(var_58_11[1], var_58_11[2], var_58_11[3], 1)
	love.graphics.print(arg_58_0.count, math.floor(var_58_10), var_58_8, 0, arg_58_0.scale, arg_58_0.scale)
end

local function var_0_111(arg_60_0, arg_60_1, arg_60_2, arg_60_3)
	local var_60_0 = 0
	local var_60_1 = var_0_37(arg_60_1):getHeight() * arg_60_2

	for iter_60_0, iter_60_1 in ipairs(arg_60_0 or {}) do
		if iter_60_1.type == "icon" and iter_60_1.icon then
			local var_60_2, var_60_3 = iter_60_1.icon:getDimensions()

			var_60_0 = var_60_0 + var_60_2 * arg_60_3
			var_60_1 = math.max(var_60_1, var_60_3 * arg_60_3)
		elseif iter_60_1.type == "iconword" and iter_60_1.icon then
			local var_60_4, var_60_5 = iter_60_1.icon:getDimensions()
			local var_60_6 = math.max(3, math.floor(4 * arg_60_2))

			var_60_0 = var_60_0 + var_60_4 * arg_60_3 + var_60_6

			if iter_60_1.number then
				local var_60_7 = iter_60_1.suffix and iter_60_1.suffix ~= "" and " " .. iter_60_1.suffix or ""

				var_60_0 = var_60_0 + var_0_110(iter_60_1.number, arg_60_1, arg_60_2) + var_0_110(var_60_7, arg_60_1, arg_60_2)
			else
				var_60_0 = var_60_0 + var_0_110(iter_60_1.word or "", arg_60_1, arg_60_2)
			end

			var_60_1 = math.max(var_60_1, var_60_5 * arg_60_3)
		elseif iter_60_1.type == "infinity" then
			local var_60_8 = var_0_88()

			var_60_0 = var_60_0 + 16 * var_60_8
			var_60_1 = math.max(var_60_1, 7 * var_60_8)
		else
			var_60_0 = var_60_0 + var_0_110(iter_60_1.text or iter_60_1.fallback or "", arg_60_1, arg_60_2)
		end
	end

	return var_60_0, var_60_1
end

local function var_0_112(arg_61_0, arg_61_1, arg_61_2)
	local var_61_0 = var_0_88()
	local var_61_1 = {
		{
			2,
			0
		},
		{
			3,
			0
		},
		{
			4,
			0
		},
		{
			10,
			0
		},
		{
			11,
			0
		},
		{
			12,
			0
		},
		{
			1,
			1
		},
		{
			5,
			1
		},
		{
			9,
			1
		},
		{
			13,
			1
		},
		{
			0,
			2
		},
		{
			6,
			2
		},
		{
			8,
			2
		},
		{
			14,
			2
		},
		{
			0,
			3
		},
		{
			7,
			3
		},
		{
			14,
			3
		},
		{
			0,
			4
		},
		{
			6,
			4
		},
		{
			8,
			4
		},
		{
			14,
			4
		},
		{
			1,
			5
		},
		{
			5,
			5
		},
		{
			9,
			5
		},
		{
			13,
			5
		},
		{
			2,
			6
		},
		{
			3,
			6
		},
		{
			4,
			6
		},
		{
			10,
			6
		},
		{
			11,
			6
		},
		{
			12,
			6
		}
	}
	local var_61_2 = math.floor(arg_61_0)
	local var_61_3 = math.floor(arg_61_1)

	local function var_61_4(arg_62_0)
		for iter_62_0, iter_62_1 in ipairs(var_61_1) do
			love.graphics.rectangle("fill", var_61_2 + iter_62_1[1] * var_61_0, var_61_3 + iter_62_1[2] * var_61_0 + arg_62_0, var_61_0, var_61_0)
		end
	end

	love.graphics.setColor(0, 0, 0, 0.45)
	var_61_4(var_61_0)
	love.graphics.setColor(arg_61_2 or {
		1,
		1,
		1,
		1
	})
	var_61_4(0)
end

local function var_0_113(arg_63_0, arg_63_1, arg_63_2, arg_63_3, arg_63_4, arg_63_5, arg_63_6, arg_63_7, arg_63_8, arg_63_9)
	local var_63_0 = arg_63_1
	local var_63_1 = var_0_37(arg_63_3):getHeight() * arg_63_4
	local var_63_2 = ""

	local function var_63_3()
		if var_63_2 == "" then
			return
		end

		var_63_0 = var_63_0 + require("src.ui.widgets").text_color.drawRich(var_63_2, var_63_0, arg_63_2, {
			font = arg_63_3,
			scale = arg_63_4,
			color = arg_63_6 or {
				1,
				1,
				1,
				1
			},
			numberColor = arg_63_8,
			terms = arg_63_9 and arg_63_9.terms,
			lang = arg_63_9 and arg_63_9.lang,
			extra = arg_63_9 and arg_63_9.extra,
			measure = function(arg_65_0)
				return var_0_110(arg_65_0, arg_63_3, arg_63_4)
			end
		})
		var_63_2 = ""
	end

	for iter_63_0, iter_63_1 in ipairs(arg_63_0 or {}) do
		if not ((iter_63_1.type == "icon" or iter_63_1.type == "iconword") and iter_63_1.icon or iter_63_1.type == "infinity") then
			var_63_2 = var_63_2 .. tostring(iter_63_1.text or iter_63_1.fallback or "")
		else
			var_63_3()
		end

		if iter_63_1.type == "icon" and iter_63_1.icon then
			local var_63_4, var_63_5 = iter_63_1.icon:getDimensions()

			love.graphics.setColor(arg_63_7 or {
				1,
				1,
				1,
				1
			})

			local var_63_6 = arg_63_2 + math.floor((var_63_1 - var_63_5 * arg_63_5) / 2) + 2

			love.graphics.draw(iter_63_1.icon, math.floor(var_63_0), math.floor(var_63_6), 0, arg_63_5, arg_63_5)

			var_63_0 = var_63_0 + var_63_4 * arg_63_5
		elseif iter_63_1.type == "iconword" and iter_63_1.icon then
			local var_63_7, var_63_8 = iter_63_1.icon:getDimensions()
			local var_63_9 = math.max(3, math.floor(4 * arg_63_4))

			love.graphics.setColor(arg_63_7 or {
				1,
				1,
				1,
				1
			})

			local var_63_10 = arg_63_2 + math.floor((var_63_1 - var_63_8 * arg_63_5) / 2) + 2

			love.graphics.draw(iter_63_1.icon, math.floor(var_63_0), math.floor(var_63_10), 0, arg_63_5, arg_63_5)

			var_63_0 = var_63_0 + var_63_7 * arg_63_5 + var_63_9

			if iter_63_1.number then
				love.graphics.setColor(arg_63_8 or arg_63_6 or {
					1,
					1,
					1,
					1
				})
				love.graphics.print(iter_63_1.number, math.floor(var_63_0), math.floor(arg_63_2), 0, arg_63_4, arg_63_4)

				var_63_0 = var_63_0 + var_0_110(iter_63_1.number, arg_63_3, arg_63_4)

				if iter_63_1.suffix and iter_63_1.suffix ~= "" then
					local var_63_11 = " " .. iter_63_1.suffix

					love.graphics.setColor(arg_63_6 or {
						1,
						1,
						1,
						1
					})
					love.graphics.print(var_63_11, math.floor(var_63_0), math.floor(arg_63_2), 0, arg_63_4, arg_63_4)

					var_63_0 = var_63_0 + var_0_110(var_63_11, arg_63_3, arg_63_4)
				end
			else
				love.graphics.setColor(arg_63_6 or {
					1,
					1,
					1,
					1
				})

				local var_63_12 = iter_63_1.word or ""

				love.graphics.print(var_63_12, math.floor(var_63_0), math.floor(arg_63_2), 0, arg_63_4, arg_63_4)

				var_63_0 = var_63_0 + var_0_110(var_63_12, arg_63_3, arg_63_4)
			end
		elseif iter_63_1.type == "infinity" then
			local var_63_13 = var_0_88()
			local var_63_14 = arg_63_2 + math.floor((var_63_1 - 7 * var_63_13) / 2) + var_63_13 * 2

			var_0_112(var_63_0, var_63_14, arg_63_6 or {
				1,
				1,
				1,
				1
			})

			var_63_0 = var_63_0 + 16 * var_63_13
		end
	end

	var_63_3()
end

local function var_0_114(arg_66_0, arg_66_1, arg_66_2, arg_66_3, arg_66_4)
	local var_66_0 = var_0_108(arg_66_0, arg_66_1, arg_66_3, arg_66_4)
	local var_66_1 = {}

	for iter_66_0, iter_66_1 in ipairs(var_66_0) do
		if iter_66_1.type ~= "text" then
			table.insert(var_66_1, iter_66_1)
		else
			for iter_66_2 in tostring(iter_66_1.text):gmatch("%s*%S+") do
				table.insert(var_66_1, {
					type = "text",
					text = iter_66_2
				})
			end
		end
	end

	for iter_66_3 = #var_66_1 - 1, 1, -1 do
		local var_66_2 = var_66_1[iter_66_3]
		local var_66_3 = var_66_1[iter_66_3 + 1]

		if var_66_2.type ~= "text" and var_66_2.type ~= "glued" and var_66_3.type == "text" and tostring(var_66_3.text):match("^%s*%d") then
			var_66_1[iter_66_3] = {
				type = "glued",
				parts = {
					var_66_2,
					var_66_3
				}
			}

			table.remove(var_66_1, iter_66_3 + 1)
		end
	end

	for iter_66_4 = #var_66_1 - 1, 1, -1 do
		local var_66_4 = var_66_1[iter_66_4]
		local var_66_5 = var_66_1[iter_66_4 + 1]
		local var_66_6 = var_66_5.type == "text" and tostring(var_66_5.text) or ""

		if var_66_4.type == "text" and (var_66_6:match("^%s+[%%:;!%?]") or var_66_6:match("^%s+»")) then
			var_66_1[iter_66_4] = {
				type = "text",
				text = tostring(var_66_4.text) .. var_66_6
			}

			table.remove(var_66_1, iter_66_4 + 1)
		end
	end

	local var_66_7 = {}
	local var_66_8 = {}
	local var_66_9 = 0

	local function var_66_10()
		table.insert(var_66_7, var_66_8)

		var_66_8, var_66_9 = {}, 0
	end

	local function var_66_11(arg_68_0)
		local var_68_0 = {}
		local var_68_1 = ""

		for iter_68_0 in tostring(arg_68_0 or ""):gmatch("[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*") do
			if var_68_1 == "" and iter_68_0:match("%s") then
				var_68_1 = iter_68_0
			elseif var_68_1 ~= "" and var_68_1:match("^%s+$") then
				var_68_1 = var_68_1 .. iter_68_0
			else
				if var_68_1 ~= "" then
					var_68_0[#var_68_0 + 1] = var_68_1
				end

				var_68_1 = iter_68_0
			end
		end

		if var_68_1 ~= "" then
			var_68_0[#var_68_0 + 1] = var_68_1
		end

		return var_68_0
	end

	for iter_66_5, iter_66_6 in ipairs(var_66_1) do
		local var_66_12 = var_0_111(iter_66_6.parts or {
			iter_66_6
		}, arg_66_1, arg_66_3, arg_66_4)

		if iter_66_6.parts then
			if var_66_9 > 0 and arg_66_2 < var_66_9 + var_66_12 then
				var_66_10()
			end

			for iter_66_7, iter_66_8 in ipairs(iter_66_6.parts) do
				table.insert(var_66_8, iter_66_8)
			end

			var_66_9 = var_66_9 + var_66_12
		elseif iter_66_6.type == "text" and arg_66_2 < var_66_12 then
			for iter_66_9, iter_66_10 in ipairs(var_66_11(iter_66_6.text)) do
				local var_66_13 = {
					type = "text",
					text = iter_66_10
				}
				local var_66_14 = var_0_111({
					var_66_13
				}, arg_66_1, arg_66_3, arg_66_4)

				if var_66_9 > 0 and arg_66_2 < var_66_9 + var_66_14 then
					var_66_10()

					var_66_13.text = tostring(var_66_13.text):gsub("^%s+", "")
					var_66_14 = var_0_111({
						var_66_13
					}, arg_66_1, arg_66_3, arg_66_4)
				end

				if var_66_13.text ~= "" then
					table.insert(var_66_8, var_66_13)

					var_66_9 = var_66_9 + var_66_14
				end
			end
		else
			if var_66_9 > 0 and arg_66_2 < var_66_9 + var_66_12 then
				var_66_10()

				if iter_66_6.type == "text" then
					iter_66_6 = {
						type = "text",
						text = tostring(iter_66_6.text):gsub("^%s+", "")
					}
					var_66_12 = var_0_111({
						iter_66_6
					}, arg_66_1, arg_66_3, arg_66_4)
				end
			end

			table.insert(var_66_8, iter_66_6)

			var_66_9 = var_66_9 + var_66_12
		end
	end

	if #var_66_8 > 0 then
		table.insert(var_66_7, var_66_8)
	end

	if #var_66_7 == 0 then
		table.insert(var_66_7, {})
	end

	return var_66_7
end

_G.__slotUpgradeLazyFailed = _G.__slotUpgradeLazyFailed or {}

function _G.__slotUpgradeLoadLazyImage(arg_69_0, arg_69_1)
	local var_69_0 = _G.__slotUpgradeLazyFailed

	if var_69_0[arg_69_0] then
		return nil
	end

	local var_69_1, var_69_2 = pcall(love.graphics.newImage, arg_69_1)

	if var_69_1 and var_69_2 then
		var_69_2:setFilter("nearest", "nearest")

		return var_69_2
	end

	var_69_0[arg_69_0] = true

	return nil
end

function _G.__slotUpgradeLoadLazyShader(arg_70_0, arg_70_1)
	local var_70_0 = _G.__slotUpgradeLazyFailed

	if var_70_0[arg_70_0] then
		return nil
	end

	local var_70_1, var_70_2 = pcall(love.graphics.newShader, arg_70_1)

	if var_70_1 and var_70_2 then
		return var_70_2
	end

	var_70_0[arg_70_0] = true

	return nil
end

function var_0_0.draw(arg_71_0, arg_71_1, arg_71_2)
	local var_71_0 = arg_71_0.virtual.W
	local var_71_1 = arg_71_0.virtual.H

	var_0_52, var_0_53 = var_71_0, var_71_1

	if var_0_74 ~= var_0_75 then
		var_0_77 = nil
		var_0_75 = var_0_74

		if var_0_74 then
			require("src.runtime_diagnostics").note("upgrade description " .. tostring(var_0_74))
		end
	end

	if not var_0_42 then
		var_0_42 = __slotUpgradeLoadLazyShader("bgShader", var_0_43)
	end

	love.graphics.setColor(1, 1, 1, 1)

	if var_0_42 then
		var_0_42:send("time", love.timer.getTime() % 100)

		local var_71_2 = _G.Render2 and _G.Render2.getCurrentTargetDPIScale and _G.Render2.getCurrentTargetDPIScale() or 1

		var_0_42:send("scale", love.graphics.getHeight() / 720 * var_71_2)
		love.graphics.setShader(var_0_42)
		love.graphics.rectangle("fill", 0, 0, var_71_0 + 1, var_71_1 + 1)
		love.graphics.setShader()
	else
		love.graphics.setColor(0.1, 0.08, 0.15, 1)
		love.graphics.rectangle("fill", 0, 0, var_71_0 + 1, var_71_1 + 1)
	end

	love.graphics.setColor(1, 1, 1, 1)

	for iter_71_0, iter_71_1 in ipairs(var_0_81) do
		local var_71_3 = iter_71_1.x - math.cos(iter_71_1.angle) * iter_71_1.len
		local var_71_4 = iter_71_1.y - math.sin(iter_71_1.angle) * iter_71_1.len

		love.graphics.setLineWidth(iter_71_1.thickness)
		love.graphics.setColor(1, 1, 1, iter_71_1.life)
		love.graphics.line(iter_71_1.x, iter_71_1.y, var_71_3, var_71_4)
	end

	love.graphics.setLineWidth(1)

	local var_71_5 = love.timer.getDelta()

	for iter_71_2, iter_71_3 in ipairs(var_0_78) do
		iter_71_3.x = iter_71_3.x + iter_71_3.speedX * var_71_5
		iter_71_3.y = iter_71_3.y + iter_71_3.speedY * var_71_5
		iter_71_3.t = iter_71_3.t + var_71_5

		local var_71_6 = var_0_80

		if iter_71_3.x < -var_71_6 / 2 then
			iter_71_3.x = iter_71_3.x + var_71_6
		end

		if iter_71_3.x > var_71_6 / 2 then
			iter_71_3.x = iter_71_3.x - var_71_6
		end

		if iter_71_3.y < -var_71_6 / 2 then
			iter_71_3.y = iter_71_3.y + var_71_6
		end

		if iter_71_3.y > var_71_6 / 2 then
			iter_71_3.y = iter_71_3.y - var_71_6
		end

		local var_71_7 = var_71_0 / 2 + iter_71_3.x + var_0_44 * 0.2
		local var_71_8 = var_71_1 / 2 + iter_71_3.y + var_0_45 * 0.2

		if var_71_7 > -10 and var_71_7 < var_71_0 + 10 and var_71_8 > -10 and var_71_8 < var_71_1 + 10 then
			local var_71_9 = math.sin(iter_71_3.t * iter_71_3.blinkSpeed) * 0.3 + 0.7

			love.graphics.setColor(1, 1, 1, iter_71_3.alpha * var_71_9)
			love.graphics.rectangle("fill", math.floor(var_71_7), math.floor(var_71_8), iter_71_3.size, iter_71_3.size)
		end
	end

	love.graphics.push()
	love.graphics.translate(var_71_0 / 2 + var_0_44, var_71_1 / 2 + var_0_45)
	love.graphics.scale(var_0_46, var_0_46)
	love.graphics.translate(-var_71_0 / 2, -var_71_1 / 2)

	local var_71_10 = var_0_61
	local var_71_11 = (var_71_0 - var_71_10) / 2
	local var_71_12 = (var_71_1 - var_71_10) / 2

	for iter_71_4, iter_71_5 in pairs(var_0_8) do
		if var_0_7[iter_71_4] == nil then
			local var_71_13, var_71_14 = pcall(love.graphics.newImage, iter_71_5)

			if not var_71_13 or not var_71_14 then
				var_0_7[iter_71_4] = false
			else
				var_71_14:setFilter("nearest", "nearest")

				var_0_7[iter_71_4] = var_71_14
			end
		end
	end

	if not var_0_12 then
		var_0_12 = __slotUpgradeLoadLazyImage("originiteIcon", "src/sprites/icons/menu/originite.png")
	end

	if not var_0_13 then
		var_0_13 = __slotUpgradeLoadLazyImage("goldIcon", "src/sprites/icons/tooltip/gold.png")
	end

	var_0_0.getOriginiteFont()

	var_0_16, var_0_17 = var_0_41(var_0_16, var_0_17, "src/data/font/Galmuri9WS.fnt")

	if not var_0_18 then
		var_0_18 = __slotUpgradeLoadLazyImage("titleBg", "src/sprites/mainmenu/upgradetitle.png")
	end

	var_0_19, var_0_20 = var_0_41(var_0_19, var_0_20, "src/data/font/Galmuri9WS.fnt")

	if not var_0_21 then
		var_0_21 = __slotUpgradeLoadLazyImage("mouseRightIcon", "src/sprites/icons/menu/mouseright.png")
	end

	if not var_0_22 then
		var_0_22 = __slotUpgradeLoadLazyImage("mouseLeftIcon", "src/sprites/icons/menu/mouseleft.png")
	end

	if not var_0_23 then
		var_0_23 = __slotUpgradeLoadLazyImage("mouseWheelIcon", "src/sprites/icons/menu/mousewheel.png")
	end

	if not var_0_24 then
		var_0_24 = __slotUpgradeLoadLazyImage("backButtonImg", "src/sprites/mainmenu/backbutton.png")
	end

	if not var_0_9 then
		var_0_9 = __slotUpgradeLoadLazyShader("solidColorShader", "            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {\n                vec4 texcolor = Texel(texture, texture_coords);\n                if (texcolor.a == 0.0) discard;\n                return color;\n            }\n        ")
	end

	if not var_0_10 then
		var_0_10 = __slotUpgradeLoadLazyShader("glowShader", "            extern vec4 glowColor;\n\n            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {\n                vec2 uv = texture_coords - 0.5;\n\n                // Improved Rounded Box SDF to eliminate \"X\" artifact\n                // Box half-size 0.25, Corner radius is handled by the distance field nature\n                vec2 d = abs(uv) - 0.2;\n                float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);\n\n                // Smooth falloff from the edge of the box\n                // 0.0 is the edge of the box, 0.3 is the fade out distance\n                float alpha = 1.0 - smoothstep(0.0, 0.3, dist);\n\n                // Sharper falloff to reduce \"large area\" feel\n                alpha = pow(alpha, 2.0);\n\n                return glowColor * alpha;\n            }\n        ")
	end

	if not var_0_11 and not _G.__slotUpgradeLazyFailed.whitePixel then
		local var_71_15, var_71_16 = pcall(function()
			return love.graphics.newImage(love.image.newImageData(1, 1))
		end)

		if not var_71_15 or not var_71_16 then
			_G.__slotUpgradeLazyFailed.whitePixel = true
		else
			var_0_11 = var_71_16
		end
	end

	var_0_62 = {}

	local var_71_17 = var_71_0 / 2
	local var_71_18 = var_71_1 / 2
	local var_71_19 = {
		maxhp = {
			x = var_71_17 - 60,
			y = var_71_18 + 60
		},
		noviceshield = {
			x = var_71_17 - 60,
			y = var_71_18 + 140
		},
		startgold = {
			x = var_71_17 - 120,
			y = var_71_18 + 120
		},
		startingmerccontract = {
			x = var_71_17 - 200,
			y = var_71_18 + 120
		},
		comebackspin = {
			x = var_71_17 - 60,
			y = var_71_18 + 220
		},
		gateheal = {
			x = var_71_17 - 60,
			y = var_71_18 + 300
		},
		comebackgold = {
			x = var_71_17 - 120,
			y = var_71_18 + 200
		},
		maxhp2 = {
			x = var_71_17 - 180,
			y = var_71_18 + 260
		},
		startgold2 = {
			x = var_71_17 - 180,
			y = var_71_18 + 180
		},
		slotodds = {
			x = var_71_17,
			y = var_71_18
		},
		factionsynergy = {
			x = var_71_17 + 120,
			y = var_71_18 + 360
		},
		maxunit = {
			x = var_71_17 + 60,
			y = var_71_18 + 60
		},
		maxunit2 = {
			x = var_71_17 + 120,
			y = var_71_18 + 120
		},
		maxunit3 = {
			x = var_71_17 + 120,
			y = var_71_18 + 200
		},
		slotnudge = {
			x = var_71_17 + 140,
			y = var_71_18 + 60
		},
		interest = {
			x = var_71_17 + 60,
			y = var_71_18 + 140
		},
		dormantpower = {
			x = var_71_17 + 60,
			y = var_71_18 + 220
		},
		growthbranch = {
			x = var_71_17 + 120,
			y = var_71_18 + 280
		},
		preptime2 = {
			x = var_71_17 + 120,
			y = var_71_18 + 200
		},
		preptimerdisabled = {
			x = var_71_17 + 180,
			y = var_71_18 + 260
		},
		slotadvanced = {
			x = var_71_17,
			y = var_71_18 - 80
		},
		slotadvanced2 = {
			x = var_71_17,
			y = var_71_18 - 160
		},
		slotadvanced3 = {
			x = var_71_17,
			y = var_71_18 - 240
		},
		slotrare = {
			x = var_71_17 - 80,
			y = var_71_18 - 240
		},
		corereroll = {
			x = var_71_17 - 80,
			y = var_71_18 - 80
		},
		firstcorespin = {
			x = var_71_17 - 160,
			y = var_71_18 - 80
		},
		firstcoreuncommon = {
			x = var_71_17 - 240,
			y = var_71_18 - 80
		},
		shopreroll = {
			x = var_71_17 + 80,
			y = var_71_18 - 80
		},
		iteminventory = {
			x = var_71_17 + 140,
			y = var_71_18 - 140
		},
		itemrefund = {
			x = var_71_17 + 220,
			y = var_71_18 - 140
		},
		iteminventory2 = {
			x = var_71_17 + 200,
			y = var_71_18 - 200
		},
		itemresearch = {
			x = var_71_17 + 80,
			y = var_71_18 - 160
		},
		shoppin = {
			x = var_71_17 + 220,
			y = var_71_18 - 80
		}
	}

	for iter_71_6, iter_71_7 in pairs(var_0_91) do
		if iter_71_7.posX then
			var_71_19[iter_71_6] = {
				x = var_71_17 + iter_71_7.posX,
				y = var_71_18 + iter_71_7.posY
			}
		end
	end

	for iter_71_8, iter_71_9 in pairs(var_71_19) do
		iter_71_9.x, iter_71_9.y = var_71_17 + (iter_71_9.x - var_71_17) * var_0_0.TREE_SPREAD, var_71_18 + (iter_71_9.y - var_71_18) * var_0_0.TREE_SPREAD
	end

	local var_71_20 = var_0_91.slotodds.maxed == true
	local var_71_21 = var_0_91.maxhp and var_0_91.maxhp.maxed == true
	local var_71_22 = var_0_72("noviceshield")
	local var_71_23 = var_0_72("startgold")
	local var_71_24 = var_0_72("startingmerccontract")
	local var_71_25 = var_0_72("comebackspin")
	local var_71_26 = var_0_91.noviceshield and var_0_91.noviceshield.maxed == true
	local var_71_27 = var_0_72("gateheal")
	local var_71_28 = var_0_91.comebackspin and var_0_91.comebackspin.maxed == true
	local var_71_29 = var_0_72("comebackgold")
	local var_71_30 = var_0_91.startgold and var_0_91.startgold.maxed == true
	local var_71_31 = var_0_72("maxhp2")
	local var_71_32 = var_0_91.comebackgold and var_0_91.comebackgold.maxed == true
	local var_71_33 = var_0_72("startgold2")
	local var_71_34 = var_0_91.maxunit and var_0_91.maxunit.maxed == true
	local var_71_35 = var_0_72("maxunit2")
	local var_71_36 = var_0_72("maxunit3")
	local var_71_37 = var_0_91.maxunit2 and var_0_91.maxunit2.maxed == true
	local var_71_38 = var_0_72("preptime")
	local var_71_39 = var_0_72("preptime2")
	local var_71_40 = var_0_72("preptimerdisabled")
	local var_71_41 = var_0_72("slotadvanced2")
	local var_71_42 = var_0_91.slotadvanced and var_0_91.slotadvanced.maxed == true
	local var_71_43 = var_0_72("corereroll")
	local var_71_44 = var_0_72("firstcorespin")
	local var_71_45 = var_0_91.corereroll and var_0_91.corereroll.maxed == true
	local var_71_46 = var_0_72("firstcoreuncommon")
	local var_71_47 = var_0_91.firstcorespin and var_0_91.firstcorespin.maxed == true
	local var_71_48 = var_0_72("shopreroll")
	local var_71_49 = var_0_72("iteminventory")
	local var_71_50 = var_0_91.shopreroll and var_0_91.shopreroll.maxed == true
	local var_71_51 = var_0_91.iteminventory and var_0_91.iteminventory.maxed == true
	local var_71_52 = var_0_72("iteminventory2")
	local var_71_53 = var_0_72("itemresearch")
	local var_71_54 = var_0_72("shoppin")
	local var_71_55 = var_0_72("slotadvanced3")
	local var_71_56 = var_0_91.slotadvanced2 and var_0_91.slotadvanced2.maxed == true
	local var_71_57 = var_0_72("slotrare")
	local var_71_58 = var_0_91.slotadvanced3 and var_0_91.slotadvanced3.maxed == true
	local var_71_59 = var_0_72("maxhp")

	if var_71_20 and (var_71_59.revealed or (var_71_59.unlockLineProgress or 0) > 0) or var_71_59.isDisappearing then
		local var_71_60 = {
			1,
			1,
			1,
			1
		}
		local var_71_61 = var_0_91.maxhp
		local var_71_62 = var_71_61 and var_71_61.maxed or false
		local var_71_63 = var_71_61 and arg_71_1 >= var_71_61.cost

		if var_71_62 then
			var_71_60 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_63 then
			var_71_60 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_60 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_64 = var_71_19.slotodds.x
		local var_71_65 = var_71_19.slotodds.y
		local var_71_66 = var_71_19.maxhp.x
		local var_71_67 = var_71_19.maxhp.y
		local var_71_68 = var_71_59.unlockLineProgress or 0
		local var_71_69 = var_71_64 + (var_71_66 - var_71_64) * var_71_68
		local var_71_70 = var_71_65 + (var_71_67 - var_71_65) * var_71_68
		local var_71_71, var_71_72 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_73 = 0.18
		local var_71_74 = 0
		local var_71_75 = 0
		local var_71_76 = 6
		local var_71_77 = 10
		local var_71_78 = 2.3
		local var_71_79 = var_71_73 + var_71_74 * 1

		for iter_71_10 = 1, var_71_77 do
			local var_71_80 = (iter_71_10 - 0.5) / var_71_77
			local var_71_81 = var_71_76 * var_71_80^1.05
			local var_71_82 = var_71_79 * math.exp(-var_71_80 * var_71_78) * 0.7

			love.graphics.setColor(var_71_60[1], var_71_60[2], var_71_60[3], var_71_82)
			love.graphics.setLineWidth(2 + var_71_81 * 1.2)
			love.graphics.line(var_71_64, var_71_65, var_71_69, var_71_70)
		end

		love.graphics.setBlendMode(var_71_71 or "alpha", var_71_72 or "alphamultiply")
		love.graphics.setColor(var_71_60[1], var_71_60[2], var_71_60[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_64, var_71_65, var_71_69, var_71_70)
		love.graphics.setLineWidth(1)
	end

	if (var_71_21 or var_71_22.isDisappearing) and var_71_22.unlockLineProgress > 0 then
		local var_71_83 = {
			1,
			1,
			1,
			1
		}
		local var_71_84 = var_0_91.noviceshield
		local var_71_85 = var_71_84 and var_71_84.maxed or false
		local var_71_86 = var_71_84 and var_71_21 and arg_71_1 >= var_71_84.cost

		if var_71_85 then
			var_71_83 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_86 then
			var_71_83 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_83 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_87 = var_71_19.maxhp.x
		local var_71_88 = var_71_19.maxhp.y
		local var_71_89 = var_71_19.noviceshield.x
		local var_71_90 = var_71_19.noviceshield.y
		local var_71_91 = var_71_22.unlockLineProgress
		local var_71_92 = var_71_87 + (var_71_89 - var_71_87) * var_71_91
		local var_71_93 = var_71_88 + (var_71_90 - var_71_88) * var_71_91
		local var_71_94, var_71_95 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_96 = 0.18
		local var_71_97 = 6
		local var_71_98 = 10
		local var_71_99 = 2.3

		for iter_71_11 = 1, var_71_98 do
			local var_71_100 = (iter_71_11 - 0.5) / var_71_98
			local var_71_101 = var_71_97 * var_71_100^1.05
			local var_71_102 = var_71_96 * math.exp(-var_71_100 * var_71_99) * 0.7

			love.graphics.setColor(var_71_83[1], var_71_83[2], var_71_83[3], var_71_102)
			love.graphics.setLineWidth(2 + var_71_101 * 1.2)
			love.graphics.line(var_71_87, var_71_88, var_71_92, var_71_93)
		end

		love.graphics.setBlendMode(var_71_94 or "alpha", var_71_95 or "alphamultiply")
		love.graphics.setColor(var_71_83[1], var_71_83[2], var_71_83[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_87, var_71_88, var_71_92, var_71_93)
		love.graphics.setLineWidth(1)
	end

	if (var_71_21 or var_71_23.isDisappearing) and var_71_23.unlockLineProgress > 0 then
		local var_71_103 = {
			1,
			1,
			1,
			1
		}
		local var_71_104 = var_0_91.startgold
		local var_71_105 = var_71_104 and var_71_104.maxed or false
		local var_71_106 = var_71_104 and var_71_21 and arg_71_1 >= var_71_104.cost

		if var_71_105 then
			var_71_103 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_106 then
			var_71_103 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_103 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_107 = var_71_19.maxhp.x
		local var_71_108 = var_71_19.maxhp.y
		local var_71_109 = var_71_19.startgold.x
		local var_71_110 = var_71_19.startgold.y
		local var_71_111 = var_71_23.unlockLineProgress
		local var_71_112 = var_71_107 + (var_71_109 - var_71_107) * var_71_111
		local var_71_113 = var_71_108 + (var_71_110 - var_71_108) * var_71_111
		local var_71_114, var_71_115 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_116 = 0.18
		local var_71_117 = 6
		local var_71_118 = 10
		local var_71_119 = 2.3

		for iter_71_12 = 1, var_71_118 do
			local var_71_120 = (iter_71_12 - 0.5) / var_71_118
			local var_71_121 = var_71_117 * var_71_120^1.05
			local var_71_122 = var_71_116 * math.exp(-var_71_120 * var_71_119) * 0.7

			love.graphics.setColor(var_71_103[1], var_71_103[2], var_71_103[3], var_71_122)
			love.graphics.setLineWidth(2 + var_71_121 * 1.2)
			love.graphics.line(var_71_107, var_71_108, var_71_112, var_71_113)
		end

		love.graphics.setBlendMode(var_71_114 or "alpha", var_71_115 or "alphamultiply")
		love.graphics.setColor(var_71_103[1], var_71_103[2], var_71_103[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_107, var_71_108, var_71_112, var_71_113)
		love.graphics.setLineWidth(1)
	end

	if (var_71_30 or var_71_24.isDisappearing) and var_71_24.unlockLineProgress > 0 then
		local var_71_123 = {
			1,
			1,
			1,
			1
		}
		local var_71_124 = var_0_91.startingmerccontract
		local var_71_125 = var_71_124 and var_71_124.maxed or false
		local var_71_126 = var_71_124 and var_71_30 and arg_71_1 >= var_71_124.cost

		if var_71_125 then
			var_71_123 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_126 then
			var_71_123 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_123 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_127 = var_71_19.startgold.x
		local var_71_128 = var_71_19.startgold.y
		local var_71_129 = var_71_19.startingmerccontract.x
		local var_71_130 = var_71_19.startingmerccontract.y
		local var_71_131 = var_71_24.unlockLineProgress
		local var_71_132 = var_71_127 + (var_71_129 - var_71_127) * var_71_131
		local var_71_133 = var_71_128 + (var_71_130 - var_71_128) * var_71_131
		local var_71_134, var_71_135 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_136 = 0.18
		local var_71_137 = 6
		local var_71_138 = 10
		local var_71_139 = 2.3

		for iter_71_13 = 1, var_71_138 do
			local var_71_140 = (iter_71_13 - 0.5) / var_71_138
			local var_71_141 = var_71_137 * var_71_140^1.05
			local var_71_142 = var_71_136 * math.exp(-var_71_140 * var_71_139) * 0.7

			love.graphics.setColor(var_71_123[1], var_71_123[2], var_71_123[3], var_71_142)
			love.graphics.setLineWidth(2 + var_71_141 * 1.2)
			love.graphics.line(var_71_127, var_71_128, var_71_132, var_71_133)
		end

		love.graphics.setBlendMode(var_71_134 or "alpha", var_71_135 or "alphamultiply")
		love.graphics.setColor(var_71_123[1], var_71_123[2], var_71_123[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_127, var_71_128, var_71_132, var_71_133)
		love.graphics.setLineWidth(1)
	end

	if (var_71_26 or var_71_25.isDisappearing) and var_71_25.unlockLineProgress > 0 then
		local var_71_143 = {
			1,
			1,
			1,
			1
		}
		local var_71_144 = var_0_91.comebackspin
		local var_71_145 = var_71_144 and var_71_144.maxed or false
		local var_71_146 = var_71_144 and var_71_26 and arg_71_1 >= var_71_144.cost

		if var_71_145 then
			var_71_143 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_146 then
			var_71_143 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_143 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_147 = var_71_19.noviceshield.x
		local var_71_148 = var_71_19.noviceshield.y
		local var_71_149 = var_71_19.comebackspin.x
		local var_71_150 = var_71_19.comebackspin.y
		local var_71_151 = var_71_25.unlockLineProgress
		local var_71_152 = var_71_147 + (var_71_149 - var_71_147) * var_71_151
		local var_71_153 = var_71_148 + (var_71_150 - var_71_148) * var_71_151
		local var_71_154, var_71_155 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_156 = 0.18
		local var_71_157 = 6
		local var_71_158 = 10
		local var_71_159 = 2.3

		for iter_71_14 = 1, var_71_158 do
			local var_71_160 = (iter_71_14 - 0.5) / var_71_158
			local var_71_161 = var_71_157 * var_71_160^1.05
			local var_71_162 = var_71_156 * math.exp(-var_71_160 * var_71_159) * 0.7

			love.graphics.setColor(var_71_143[1], var_71_143[2], var_71_143[3], var_71_162)
			love.graphics.setLineWidth(2 + var_71_161 * 1.2)
			love.graphics.line(var_71_147, var_71_148, var_71_152, var_71_153)
		end

		love.graphics.setBlendMode(var_71_154 or "alpha", var_71_155 or "alphamultiply")
		love.graphics.setColor(var_71_143[1], var_71_143[2], var_71_143[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_147, var_71_148, var_71_152, var_71_153)
		love.graphics.setLineWidth(1)
	end

	if (var_71_28 or var_71_27.isDisappearing) and var_71_27.unlockLineProgress > 0 then
		local var_71_163 = {
			1,
			1,
			1,
			1
		}
		local var_71_164 = var_0_91.gateheal
		local var_71_165 = var_71_164 and var_71_164.maxed or false
		local var_71_166 = var_71_164 and var_71_28 and arg_71_1 >= var_71_164.cost

		if var_71_165 then
			var_71_163 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_166 then
			var_71_163 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_163 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_167 = var_71_19.comebackspin.x
		local var_71_168 = var_71_19.comebackspin.y
		local var_71_169 = var_71_19.gateheal.x
		local var_71_170 = var_71_19.gateheal.y
		local var_71_171 = var_71_27.unlockLineProgress
		local var_71_172 = var_71_167 + (var_71_169 - var_71_167) * var_71_171
		local var_71_173 = var_71_168 + (var_71_170 - var_71_168) * var_71_171
		local var_71_174, var_71_175 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_176 = 0.18
		local var_71_177 = 6
		local var_71_178 = 10
		local var_71_179 = 2.3

		for iter_71_15 = 1, var_71_178 do
			local var_71_180 = (iter_71_15 - 0.5) / var_71_178
			local var_71_181 = var_71_177 * var_71_180^1.05
			local var_71_182 = var_71_176 * math.exp(-var_71_180 * var_71_179) * 0.7

			love.graphics.setColor(var_71_163[1], var_71_163[2], var_71_163[3], var_71_182)
			love.graphics.setLineWidth(2 + var_71_181 * 1.2)
			love.graphics.line(var_71_167, var_71_168, var_71_172, var_71_173)
		end

		love.graphics.setBlendMode(var_71_174 or "alpha", var_71_175 or "alphamultiply")
		love.graphics.setColor(var_71_163[1], var_71_163[2], var_71_163[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_167, var_71_168, var_71_172, var_71_173)
		love.graphics.setLineWidth(1)
	end

	if (var_71_30 or var_71_29.isDisappearing) and var_71_29.unlockLineProgress > 0 then
		local var_71_183 = {
			1,
			1,
			1,
			1
		}
		local var_71_184 = var_0_91.comebackgold
		local var_71_185 = var_71_184 and var_71_184.maxed or false
		local var_71_186 = var_71_184 and var_71_30 and arg_71_1 >= var_71_184.cost

		if var_71_185 then
			var_71_183 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_186 then
			var_71_183 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_183 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_187 = var_71_19.startgold.x
		local var_71_188 = var_71_19.startgold.y
		local var_71_189 = var_71_19.comebackgold.x
		local var_71_190 = var_71_19.comebackgold.y
		local var_71_191 = var_71_29.unlockLineProgress
		local var_71_192 = var_71_187 + (var_71_189 - var_71_187) * var_71_191
		local var_71_193 = var_71_188 + (var_71_190 - var_71_188) * var_71_191
		local var_71_194, var_71_195 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_196 = 0.18
		local var_71_197 = 6
		local var_71_198 = 10
		local var_71_199 = 2.3

		for iter_71_16 = 1, var_71_198 do
			local var_71_200 = (iter_71_16 - 0.5) / var_71_198
			local var_71_201 = var_71_197 * var_71_200^1.05
			local var_71_202 = var_71_196 * math.exp(-var_71_200 * var_71_199) * 0.7

			love.graphics.setColor(var_71_183[1], var_71_183[2], var_71_183[3], var_71_202)
			love.graphics.setLineWidth(2 + var_71_201 * 1.2)
			love.graphics.line(var_71_187, var_71_188, var_71_192, var_71_193)
		end

		love.graphics.setBlendMode(var_71_194 or "alpha", var_71_195 or "alphamultiply")
		love.graphics.setColor(var_71_183[1], var_71_183[2], var_71_183[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_187, var_71_188, var_71_192, var_71_193)
		love.graphics.setLineWidth(1)
	end

	if (var_71_32 or var_71_31.isDisappearing) and var_71_31.unlockLineProgress > 0 then
		local var_71_203 = {
			1,
			1,
			1,
			1
		}
		local var_71_204 = var_0_91.maxhp2
		local var_71_205 = var_71_204 and var_71_204.maxed or false
		local var_71_206 = var_71_204 and var_71_32 and arg_71_1 >= var_71_204.cost

		if var_71_205 then
			var_71_203 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_206 then
			var_71_203 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_203 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_207 = var_71_19.comebackgold.x
		local var_71_208 = var_71_19.comebackgold.y
		local var_71_209 = var_71_19.maxhp2.x
		local var_71_210 = var_71_19.maxhp2.y
		local var_71_211 = var_71_31.unlockLineProgress
		local var_71_212 = var_71_207 + (var_71_209 - var_71_207) * var_71_211
		local var_71_213 = var_71_208 + (var_71_210 - var_71_208) * var_71_211
		local var_71_214, var_71_215 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_216 = 0.18
		local var_71_217 = 6
		local var_71_218 = 10
		local var_71_219 = 2.3

		for iter_71_17 = 1, var_71_218 do
			local var_71_220 = (iter_71_17 - 0.5) / var_71_218
			local var_71_221 = var_71_217 * var_71_220^1.05
			local var_71_222 = var_71_216 * math.exp(-var_71_220 * var_71_219) * 0.7

			love.graphics.setColor(var_71_203[1], var_71_203[2], var_71_203[3], var_71_222)
			love.graphics.setLineWidth(2 + var_71_221 * 1.2)
			love.graphics.line(var_71_207, var_71_208, var_71_212, var_71_213)
		end

		love.graphics.setBlendMode(var_71_214 or "alpha", var_71_215 or "alphamultiply")
		love.graphics.setColor(var_71_203[1], var_71_203[2], var_71_203[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_207, var_71_208, var_71_212, var_71_213)
		love.graphics.setLineWidth(1)
	end

	if (var_71_30 or var_71_33.isDisappearing) and var_71_33.unlockLineProgress > 0 then
		local var_71_223 = {
			1,
			1,
			1,
			1
		}
		local var_71_224 = var_0_91.startgold2
		local var_71_225 = var_71_224 and var_71_224.maxed or false
		local var_71_226 = var_71_224 and var_71_30 and arg_71_1 >= var_71_224.cost

		if var_71_225 then
			var_71_223 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_226 then
			var_71_223 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_223 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_227 = var_71_19.startgold.x
		local var_71_228 = var_71_19.startgold.y
		local var_71_229 = var_71_19.startgold2.x
		local var_71_230 = var_71_19.startgold2.y
		local var_71_231 = var_71_33.unlockLineProgress
		local var_71_232 = var_71_227 + (var_71_229 - var_71_227) * var_71_231
		local var_71_233 = var_71_228 + (var_71_230 - var_71_228) * var_71_231
		local var_71_234, var_71_235 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_236 = 0.18
		local var_71_237 = 6
		local var_71_238 = 10
		local var_71_239 = 2.3

		for iter_71_18 = 1, var_71_238 do
			local var_71_240 = (iter_71_18 - 0.5) / var_71_238
			local var_71_241 = var_71_237 * var_71_240^1.05
			local var_71_242 = var_71_236 * math.exp(-var_71_240 * var_71_239) * 0.7

			love.graphics.setColor(var_71_223[1], var_71_223[2], var_71_223[3], var_71_242)
			love.graphics.setLineWidth(2 + var_71_241 * 1.2)
			love.graphics.line(var_71_227, var_71_228, var_71_232, var_71_233)
		end

		love.graphics.setBlendMode(var_71_234 or "alpha", var_71_235 or "alphamultiply")
		love.graphics.setColor(var_71_223[1], var_71_223[2], var_71_223[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_227, var_71_228, var_71_232, var_71_233)
		love.graphics.setLineWidth(1)
	end

	local var_71_243 = var_0_72("maxunit")

	if (var_71_20 or var_71_243.isDisappearing) and var_71_243.unlockLineProgress > 0 then
		local var_71_244 = {
			1,
			1,
			1,
			1
		}
		local var_71_245 = var_0_91.maxunit
		local var_71_246 = var_71_245.maxed or false
		local var_71_247 = arg_71_1 >= var_71_245.cost

		if var_71_246 then
			var_71_244 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_247 then
			var_71_244 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_244 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_248 = var_71_19.slotodds.x
		local var_71_249 = var_71_19.slotodds.y
		local var_71_250 = var_71_19.maxunit.x
		local var_71_251 = var_71_19.maxunit.y
		local var_71_252 = var_71_243.unlockLineProgress
		local var_71_253 = var_71_248 + (var_71_250 - var_71_248) * var_71_252
		local var_71_254 = var_71_249 + (var_71_251 - var_71_249) * var_71_252
		local var_71_255, var_71_256 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_257 = 0.18
		local var_71_258 = 0
		local var_71_259 = 0
		local var_71_260 = 6
		local var_71_261 = 10
		local var_71_262 = 2.3
		local var_71_263 = var_71_257 + var_71_258 * 1

		for iter_71_19 = 1, var_71_261 do
			local var_71_264 = (iter_71_19 - 0.5) / var_71_261
			local var_71_265 = var_71_260 * var_71_264^1.05
			local var_71_266 = var_71_263 * math.exp(-var_71_264 * var_71_262) * 0.7

			love.graphics.setColor(var_71_244[1], var_71_244[2], var_71_244[3], var_71_266)
			love.graphics.setLineWidth(2 + var_71_265 * 1.2)
			love.graphics.line(var_71_248, var_71_249, var_71_253, var_71_254)
		end

		love.graphics.setBlendMode(var_71_255 or "alpha", var_71_256 or "alphamultiply")
		love.graphics.setColor(var_71_244[1], var_71_244[2], var_71_244[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_248, var_71_249, var_71_253, var_71_254)
		love.graphics.setLineWidth(1)
	end

	if (var_71_34 or var_71_35.isDisappearing) and var_71_35.unlockLineProgress > 0 then
		local var_71_267 = {
			1,
			1,
			1,
			1
		}
		local var_71_268 = var_0_91.maxunit2
		local var_71_269 = var_71_268 and var_71_268.maxed or false
		local var_71_270 = var_71_268 and var_71_34 and arg_71_1 >= var_71_268.cost

		if var_71_269 then
			var_71_267 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_270 then
			var_71_267 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_267 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_271 = var_71_19.maxunit.x
		local var_71_272 = var_71_19.maxunit.y
		local var_71_273 = var_71_19.maxunit2.x
		local var_71_274 = var_71_19.maxunit2.y
		local var_71_275 = var_71_35.unlockLineProgress
		local var_71_276 = var_71_271 + (var_71_273 - var_71_271) * var_71_275
		local var_71_277 = var_71_272 + (var_71_274 - var_71_272) * var_71_275
		local var_71_278, var_71_279 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_280 = 0.18
		local var_71_281 = 6
		local var_71_282 = 10
		local var_71_283 = 2.3

		for iter_71_20 = 1, var_71_282 do
			local var_71_284 = (iter_71_20 - 0.5) / var_71_282
			local var_71_285 = var_71_281 * var_71_284^1.05
			local var_71_286 = var_71_280 * math.exp(-var_71_284 * var_71_283) * 0.7

			love.graphics.setColor(var_71_267[1], var_71_267[2], var_71_267[3], var_71_286)
			love.graphics.setLineWidth(2 + var_71_285 * 1.2)
			love.graphics.line(var_71_271, var_71_272, var_71_276, var_71_277)
		end

		love.graphics.setBlendMode(var_71_278 or "alpha", var_71_279 or "alphamultiply")
		love.graphics.setColor(var_71_267[1], var_71_267[2], var_71_267[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_271, var_71_272, var_71_276, var_71_277)
		love.graphics.setLineWidth(1)
	end

	if (var_71_37 or var_71_36.isDisappearing) and var_71_36.unlockLineProgress > 0 then
		local var_71_287 = {
			1,
			1,
			1,
			1
		}
		local var_71_288 = var_0_91.maxunit3
		local var_71_289 = var_71_288 and var_71_288.maxed or false
		local var_71_290 = var_71_288 and var_71_37 and arg_71_1 >= var_71_288.cost

		if var_71_289 then
			var_71_287 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_290 then
			var_71_287 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_287 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_291 = var_71_19.maxunit2.x
		local var_71_292 = var_71_19.maxunit2.y
		local var_71_293 = var_71_19.maxunit3.x
		local var_71_294 = var_71_19.maxunit3.y
		local var_71_295 = var_71_36.unlockLineProgress
		local var_71_296 = var_71_291 + (var_71_293 - var_71_291) * var_71_295
		local var_71_297 = var_71_292 + (var_71_294 - var_71_292) * var_71_295
		local var_71_298, var_71_299 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_300 = 0.18
		local var_71_301 = 6
		local var_71_302 = 10
		local var_71_303 = 2.3

		for iter_71_21 = 1, var_71_302 do
			local var_71_304 = (iter_71_21 - 0.5) / var_71_302
			local var_71_305 = var_71_301 * var_71_304^1.05
			local var_71_306 = var_71_300 * math.exp(-var_71_304 * var_71_303) * 0.7

			love.graphics.setColor(var_71_287[1], var_71_287[2], var_71_287[3], var_71_306)
			love.graphics.setLineWidth(2 + var_71_305 * 1.2)
			love.graphics.line(var_71_291, var_71_292, var_71_296, var_71_297)
		end

		love.graphics.setBlendMode(var_71_298 or "alpha", var_71_299 or "alphamultiply")
		love.graphics.setColor(var_71_287[1], var_71_287[2], var_71_287[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_291, var_71_292, var_71_296, var_71_297)
		love.graphics.setLineWidth(1)
	end

	if false and (var_71_34 or var_71_38.isDisappearing) and var_71_38.unlockLineProgress > 0 then
		local var_71_307 = {
			1,
			1,
			1,
			1
		}
		local var_71_308 = var_0_91.preptime
		local var_71_309 = var_71_308 and var_71_308.maxed or false
		local var_71_310 = var_71_308 and var_71_34 and arg_71_1 >= var_71_308.cost

		if var_71_309 then
			var_71_307 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_310 then
			var_71_307 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_307 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_311 = var_71_19.maxunit.x
		local var_71_312 = var_71_19.maxunit.y
		local var_71_313 = var_71_19.preptime.x
		local var_71_314 = var_71_19.preptime.y
		local var_71_315 = var_71_38.unlockLineProgress
		local var_71_316 = var_71_311 + (var_71_313 - var_71_311) * var_71_315
		local var_71_317 = var_71_312 + (var_71_314 - var_71_312) * var_71_315
		local var_71_318, var_71_319 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_320 = 0.18
		local var_71_321 = 6
		local var_71_322 = 10
		local var_71_323 = 2.3

		for iter_71_22 = 1, var_71_322 do
			local var_71_324 = (iter_71_22 - 0.5) / var_71_322
			local var_71_325 = var_71_321 * var_71_324^1.05
			local var_71_326 = var_71_320 * math.exp(-var_71_324 * var_71_323) * 0.7

			love.graphics.setColor(var_71_307[1], var_71_307[2], var_71_307[3], var_71_326)
			love.graphics.setLineWidth(2 + var_71_325 * 1.2)
			love.graphics.line(var_71_311, var_71_312, var_71_316, var_71_317)
		end

		love.graphics.setBlendMode(var_71_318 or "alpha", var_71_319 or "alphamultiply")
		love.graphics.setColor(var_71_307[1], var_71_307[2], var_71_307[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_311, var_71_312, var_71_316, var_71_317)
		love.graphics.setLineWidth(1)
	end

	for iter_71_23, iter_71_24 in pairs(var_0_91) do
		local var_71_327 = iter_71_24.parent
		local var_71_328 = var_71_327 and var_0_72(iter_71_23)
		local var_71_329 = var_71_327 and var_0_91[var_71_327] and var_0_91[var_71_327].maxed == true
		local var_71_330 = var_71_327 and var_0_91[var_71_327]
		local var_71_331 = iter_71_24.maxed == true and var_71_330 ~= nil and var_71_330.parent ~= nil and var_0_91[var_71_330.parent] ~= nil and var_0_91[var_71_330.parent].maxed == true

		if var_71_328 and (var_71_329 or var_71_331 or var_71_328.isDisappearing) and var_71_328.unlockLineProgress > 0 then
			local var_71_332 = iter_71_24.maxed and "#6FAACC" or var_71_329 and var_0_102(iter_71_23) and arg_71_1 >= iter_71_24.cost and "#5FAF6F" or "#A84F5A"
			local var_71_333, var_71_334, var_71_335 = var_0_84(var_71_332)
			local var_71_336 = var_71_19[var_71_327]
			local var_71_337 = var_71_19[iter_71_23]
			local var_71_338 = var_71_328.unlockLineProgress
			local var_71_339 = var_71_336.x + (var_71_337.x - var_71_336.x) * var_71_338
			local var_71_340 = var_71_336.y + (var_71_337.y - var_71_336.y) * var_71_338
			local var_71_341, var_71_342 = love.graphics.getBlendMode()

			love.graphics.setBlendMode("add", "alphamultiply")

			for iter_71_25 = 1, 10 do
				local var_71_343 = (iter_71_25 - 0.5) / 10
				local var_71_344 = 6 * var_71_343^1.05

				love.graphics.setColor(var_71_333, var_71_334, var_71_335, 0.18 * math.exp(-var_71_343 * 2.3) * 0.7)
				love.graphics.setLineWidth(2 + var_71_344 * 1.2)
				love.graphics.line(var_71_336.x, var_71_336.y, var_71_339, var_71_340)
			end

			love.graphics.setBlendMode(var_71_341 or "alpha", var_71_342 or "alphamultiply")
			love.graphics.setColor(var_71_333, var_71_334, var_71_335, 1)
			love.graphics.setLineWidth(2)
			love.graphics.line(var_71_336.x, var_71_336.y, var_71_339, var_71_340)
			love.graphics.setLineWidth(1)
		end
	end

	if false and var_71_39.isDisappearing and var_71_39.unlockLineProgress > 0 then
		local var_71_345 = {
			1,
			1,
			1,
			1
		}
		local var_71_346 = var_0_91.preptime2
		local var_71_347 = var_71_346 and var_71_346.maxed or false
		local var_71_348 = var_71_346 and prepTimePurchased and arg_71_1 >= var_71_346.cost

		if var_71_347 then
			var_71_345 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_348 then
			var_71_345 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_345 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_349 = var_71_19.preptime.x
		local var_71_350 = var_71_19.preptime.y
		local var_71_351 = var_71_19.preptime2.x
		local var_71_352 = var_71_19.preptime2.y
		local var_71_353 = var_71_39.unlockLineProgress
		local var_71_354 = var_71_349 + (var_71_351 - var_71_349) * var_71_353
		local var_71_355 = var_71_350 + (var_71_352 - var_71_350) * var_71_353
		local var_71_356, var_71_357 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_358 = 0.18
		local var_71_359 = 6
		local var_71_360 = 10
		local var_71_361 = 2.3

		for iter_71_26 = 1, var_71_360 do
			local var_71_362 = (iter_71_26 - 0.5) / var_71_360
			local var_71_363 = var_71_359 * var_71_362^1.05
			local var_71_364 = var_71_358 * math.exp(-var_71_362 * var_71_361) * 0.7

			love.graphics.setColor(var_71_345[1], var_71_345[2], var_71_345[3], var_71_364)
			love.graphics.setLineWidth(2 + var_71_363 * 1.2)
			love.graphics.line(var_71_349, var_71_350, var_71_354, var_71_355)
		end

		love.graphics.setBlendMode(var_71_356 or "alpha", var_71_357 or "alphamultiply")
		love.graphics.setColor(var_71_345[1], var_71_345[2], var_71_345[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_349, var_71_350, var_71_354, var_71_355)
		love.graphics.setLineWidth(1)
	end

	if false and var_71_40.isDisappearing and var_71_40.unlockLineProgress > 0 then
		local var_71_365 = {
			1,
			1,
			1,
			1
		}
		local var_71_366 = var_0_91.preptimerdisabled
		local var_71_367 = var_71_366 and var_71_366.maxed or false
		local var_71_368 = var_71_366 and prepTime2Purchased and arg_71_1 >= var_71_366.cost

		if var_71_367 then
			var_71_365 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_368 then
			var_71_365 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_365 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_369 = var_71_19.preptime2.x
		local var_71_370 = var_71_19.preptime2.y
		local var_71_371 = var_71_19.preptimerdisabled.x
		local var_71_372 = var_71_19.preptimerdisabled.y
		local var_71_373 = var_71_40.unlockLineProgress
		local var_71_374 = var_71_369 + (var_71_371 - var_71_369) * var_71_373
		local var_71_375 = var_71_370 + (var_71_372 - var_71_370) * var_71_373
		local var_71_376, var_71_377 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_378 = 0.18
		local var_71_379 = 6
		local var_71_380 = 10
		local var_71_381 = 2.3

		for iter_71_27 = 1, var_71_380 do
			local var_71_382 = (iter_71_27 - 0.5) / var_71_380
			local var_71_383 = var_71_379 * var_71_382^1.05
			local var_71_384 = var_71_378 * math.exp(-var_71_382 * var_71_381) * 0.7

			love.graphics.setColor(var_71_365[1], var_71_365[2], var_71_365[3], var_71_384)
			love.graphics.setLineWidth(2 + var_71_383 * 1.2)
			love.graphics.line(var_71_369, var_71_370, var_71_374, var_71_375)
		end

		love.graphics.setBlendMode(var_71_376 or "alpha", var_71_377 or "alphamultiply")
		love.graphics.setColor(var_71_365[1], var_71_365[2], var_71_365[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_369, var_71_370, var_71_374, var_71_375)
		love.graphics.setLineWidth(1)
	end

	local var_71_385 = var_0_72("slotadvanced")
	local var_71_386 = var_71_20

	if (var_71_386 or var_71_385.isDisappearing) and var_71_385.unlockLineProgress > 0 then
		local var_71_387 = {
			1,
			1,
			1,
			1
		}
		local var_71_388 = var_0_91.slotadvanced
		local var_71_389 = var_71_388 and var_71_388.maxed or false
		local var_71_390 = var_71_388 and var_0_102("slotadvanced") and arg_71_1 >= var_71_388.cost

		if var_71_389 then
			var_71_387 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_390 then
			var_71_387 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_387 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_391 = var_71_19.slotodds.x
		local var_71_392 = var_71_19.slotodds.y
		local var_71_393 = var_71_19.slotadvanced.x
		local var_71_394 = var_71_19.slotadvanced.y
		local var_71_395 = var_71_385.unlockLineProgress
		local var_71_396 = var_71_391 + (var_71_393 - var_71_391) * var_71_395
		local var_71_397 = var_71_392 + (var_71_394 - var_71_392) * var_71_395
		local var_71_398, var_71_399 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_400 = 0.18
		local var_71_401 = 6
		local var_71_402 = 10
		local var_71_403 = 2.3

		for iter_71_28 = 1, var_71_402 do
			local var_71_404 = (iter_71_28 - 0.5) / var_71_402
			local var_71_405 = var_71_401 * var_71_404^1.05
			local var_71_406 = var_71_400 * math.exp(-var_71_404 * var_71_403) * 0.7

			love.graphics.setColor(var_71_387[1], var_71_387[2], var_71_387[3], var_71_406)
			love.graphics.setLineWidth(2 + var_71_405 * 1.2)
			love.graphics.line(var_71_391, var_71_392, var_71_396, var_71_397)
		end

		love.graphics.setBlendMode(var_71_398 or "alpha", var_71_399 or "alphamultiply")
		love.graphics.setColor(var_71_387[1], var_71_387[2], var_71_387[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_391, var_71_392, var_71_396, var_71_397)
		love.graphics.setLineWidth(1)
	end

	if (var_71_42 or var_71_43.isDisappearing) and var_71_43.unlockLineProgress > 0 then
		local var_71_407 = {
			1,
			1,
			1,
			1
		}
		local var_71_408 = var_0_91.corereroll
		local var_71_409 = var_71_408 and var_71_408.maxed or false
		local var_71_410 = var_71_408 and var_71_42 and arg_71_1 >= var_71_408.cost

		if var_71_409 then
			var_71_407 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_410 then
			var_71_407 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_407 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_411 = var_71_19.slotadvanced.x
		local var_71_412 = var_71_19.slotadvanced.y
		local var_71_413 = var_71_19.corereroll.x
		local var_71_414 = var_71_19.corereroll.y
		local var_71_415 = var_71_43.unlockLineProgress
		local var_71_416 = var_71_411 + (var_71_413 - var_71_411) * var_71_415
		local var_71_417 = var_71_412 + (var_71_414 - var_71_412) * var_71_415
		local var_71_418, var_71_419 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_420 = 0.18
		local var_71_421 = 6
		local var_71_422 = 10
		local var_71_423 = 2.3

		for iter_71_29 = 1, var_71_422 do
			local var_71_424 = (iter_71_29 - 0.5) / var_71_422
			local var_71_425 = var_71_421 * var_71_424^1.05
			local var_71_426 = var_71_420 * math.exp(-var_71_424 * var_71_423) * 0.7

			love.graphics.setColor(var_71_407[1], var_71_407[2], var_71_407[3], var_71_426)
			love.graphics.setLineWidth(2 + var_71_425 * 1.2)
			love.graphics.line(var_71_411, var_71_412, var_71_416, var_71_417)
		end

		love.graphics.setBlendMode(var_71_418 or "alpha", var_71_419 or "alphamultiply")
		love.graphics.setColor(var_71_407[1], var_71_407[2], var_71_407[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_411, var_71_412, var_71_416, var_71_417)
		love.graphics.setLineWidth(1)
	end

	if (var_71_45 or var_71_44.isDisappearing) and var_71_44.unlockLineProgress > 0 then
		local var_71_427 = {
			1,
			1,
			1,
			1
		}
		local var_71_428 = var_0_91.firstcorespin
		local var_71_429 = var_71_428 and var_71_428.maxed or false
		local var_71_430 = var_71_428 and var_71_45 and arg_71_1 >= var_71_428.cost

		if var_71_429 then
			var_71_427 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_430 then
			var_71_427 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_427 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_431 = var_71_19.corereroll.x
		local var_71_432 = var_71_19.corereroll.y
		local var_71_433 = var_71_19.firstcorespin.x
		local var_71_434 = var_71_19.firstcorespin.y
		local var_71_435 = var_71_44.unlockLineProgress
		local var_71_436 = var_71_431 + (var_71_433 - var_71_431) * var_71_435
		local var_71_437 = var_71_432 + (var_71_434 - var_71_432) * var_71_435
		local var_71_438, var_71_439 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_440 = 0.18
		local var_71_441 = 6
		local var_71_442 = 10
		local var_71_443 = 2.3

		for iter_71_30 = 1, var_71_442 do
			local var_71_444 = (iter_71_30 - 0.5) / var_71_442
			local var_71_445 = var_71_441 * var_71_444^1.05
			local var_71_446 = var_71_440 * math.exp(-var_71_444 * var_71_443) * 0.7

			love.graphics.setColor(var_71_427[1], var_71_427[2], var_71_427[3], var_71_446)
			love.graphics.setLineWidth(2 + var_71_445 * 1.2)
			love.graphics.line(var_71_431, var_71_432, var_71_436, var_71_437)
		end

		love.graphics.setBlendMode(var_71_438 or "alpha", var_71_439 or "alphamultiply")
		love.graphics.setColor(var_71_427[1], var_71_427[2], var_71_427[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_431, var_71_432, var_71_436, var_71_437)
		love.graphics.setLineWidth(1)
	end

	if (var_71_47 or var_71_46.isDisappearing) and var_71_46.unlockLineProgress > 0 then
		local var_71_447 = {
			1,
			1,
			1,
			1
		}
		local var_71_448 = var_0_91.firstcoreuncommon
		local var_71_449 = var_71_448 and var_71_448.maxed or false
		local var_71_450 = var_71_448 and var_71_47 and arg_71_1 >= var_71_448.cost

		if var_71_449 then
			var_71_447 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_450 then
			var_71_447 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_447 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_451 = var_71_19.firstcorespin.x
		local var_71_452 = var_71_19.firstcorespin.y
		local var_71_453 = var_71_19.firstcoreuncommon.x
		local var_71_454 = var_71_19.firstcoreuncommon.y
		local var_71_455 = var_71_46.unlockLineProgress
		local var_71_456 = var_71_451 + (var_71_453 - var_71_451) * var_71_455
		local var_71_457 = var_71_452 + (var_71_454 - var_71_452) * var_71_455
		local var_71_458, var_71_459 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_460 = 0.18
		local var_71_461 = 6
		local var_71_462 = 10
		local var_71_463 = 2.3

		for iter_71_31 = 1, var_71_462 do
			local var_71_464 = (iter_71_31 - 0.5) / var_71_462
			local var_71_465 = var_71_461 * var_71_464^1.05
			local var_71_466 = var_71_460 * math.exp(-var_71_464 * var_71_463) * 0.7

			love.graphics.setColor(var_71_447[1], var_71_447[2], var_71_447[3], var_71_466)
			love.graphics.setLineWidth(2 + var_71_465 * 1.2)
			love.graphics.line(var_71_451, var_71_452, var_71_456, var_71_457)
		end

		love.graphics.setBlendMode(var_71_458 or "alpha", var_71_459 or "alphamultiply")
		love.graphics.setColor(var_71_447[1], var_71_447[2], var_71_447[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_451, var_71_452, var_71_456, var_71_457)
		love.graphics.setLineWidth(1)
	end

	if (var_71_42 or var_71_48.isDisappearing) and var_71_48.unlockLineProgress > 0 then
		local var_71_467 = {
			1,
			1,
			1,
			1
		}
		local var_71_468 = var_0_91.shopreroll
		local var_71_469 = var_71_468 and var_71_468.maxed or false
		local var_71_470 = var_71_468 and var_71_42 and arg_71_1 >= var_71_468.cost

		if var_71_469 then
			var_71_467 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_470 then
			var_71_467 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_467 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_471 = var_71_19.slotadvanced.x
		local var_71_472 = var_71_19.slotadvanced.y
		local var_71_473 = var_71_19.shopreroll.x
		local var_71_474 = var_71_19.shopreroll.y
		local var_71_475 = var_71_48.unlockLineProgress
		local var_71_476 = var_71_471 + (var_71_473 - var_71_471) * var_71_475
		local var_71_477 = var_71_472 + (var_71_474 - var_71_472) * var_71_475
		local var_71_478, var_71_479 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_480 = 0.18
		local var_71_481 = 6
		local var_71_482 = 10
		local var_71_483 = 2.3

		for iter_71_32 = 1, var_71_482 do
			local var_71_484 = (iter_71_32 - 0.5) / var_71_482
			local var_71_485 = var_71_481 * var_71_484^1.05
			local var_71_486 = var_71_480 * math.exp(-var_71_484 * var_71_483) * 0.7

			love.graphics.setColor(var_71_467[1], var_71_467[2], var_71_467[3], var_71_486)
			love.graphics.setLineWidth(2 + var_71_485 * 1.2)
			love.graphics.line(var_71_471, var_71_472, var_71_476, var_71_477)
		end

		love.graphics.setBlendMode(var_71_478 or "alpha", var_71_479 or "alphamultiply")
		love.graphics.setColor(var_71_467[1], var_71_467[2], var_71_467[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_471, var_71_472, var_71_476, var_71_477)
		love.graphics.setLineWidth(1)
	end

	if false and (var_71_50 or var_71_54.isDisappearing) and var_71_54.unlockLineProgress > 0 then
		local var_71_487 = {
			1,
			1,
			1,
			1
		}
		local var_71_488 = var_0_91.shoppin
		local var_71_489 = var_71_488 and var_71_488.maxed or false
		local var_71_490 = var_71_488 and var_71_50 and var_0_102("shoppin") and arg_71_1 >= var_71_488.cost

		if var_71_489 then
			var_71_487 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_490 then
			var_71_487 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_487 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_491 = var_71_19.shopreroll.x
		local var_71_492 = var_71_19.shopreroll.y
		local var_71_493 = var_71_19.shoppin.x
		local var_71_494 = var_71_19.shoppin.y
		local var_71_495 = var_71_54.unlockLineProgress
		local var_71_496 = var_71_491 + (var_71_493 - var_71_491) * var_71_495
		local var_71_497 = var_71_492 + (var_71_494 - var_71_492) * var_71_495
		local var_71_498, var_71_499 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_500 = 0.18
		local var_71_501 = 6
		local var_71_502 = 10
		local var_71_503 = 2.3

		for iter_71_33 = 1, var_71_502 do
			local var_71_504 = (iter_71_33 - 0.5) / var_71_502
			local var_71_505 = var_71_501 * var_71_504^1.05
			local var_71_506 = var_71_500 * math.exp(-var_71_504 * var_71_503) * 0.7

			love.graphics.setColor(var_71_487[1], var_71_487[2], var_71_487[3], var_71_506)
			love.graphics.setLineWidth(2 + var_71_505 * 1.2)
			love.graphics.line(var_71_491, var_71_492, var_71_496, var_71_497)
		end

		love.graphics.setBlendMode(var_71_498 or "alpha", var_71_499 or "alphamultiply")
		love.graphics.setColor(var_71_487[1], var_71_487[2], var_71_487[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_491, var_71_492, var_71_496, var_71_497)
		love.graphics.setLineWidth(1)
	end

	if false and (var_71_50 or var_71_53.isDisappearing) and var_71_53.unlockLineProgress > 0 then
		local var_71_507 = {
			1,
			1,
			1,
			1
		}
		local var_71_508 = var_0_91.itemresearch
		local var_71_509 = var_71_508 and var_71_508.maxed or false
		local var_71_510 = var_71_508 and var_71_50 and var_0_102("itemresearch") and arg_71_1 >= var_71_508.cost

		if var_71_509 then
			var_71_507 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_510 then
			var_71_507 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_507 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_511 = var_71_19.shopreroll.x
		local var_71_512 = var_71_19.shopreroll.y
		local var_71_513 = var_71_19.itemresearch.x
		local var_71_514 = var_71_19.itemresearch.y
		local var_71_515 = var_71_53.unlockLineProgress
		local var_71_516 = var_71_511 + (var_71_513 - var_71_511) * var_71_515
		local var_71_517 = var_71_512 + (var_71_514 - var_71_512) * var_71_515
		local var_71_518, var_71_519 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_520 = 0.18
		local var_71_521 = 6
		local var_71_522 = 10
		local var_71_523 = 2.3

		for iter_71_34 = 1, var_71_522 do
			local var_71_524 = (iter_71_34 - 0.5) / var_71_522
			local var_71_525 = var_71_521 * var_71_524^1.05
			local var_71_526 = var_71_520 * math.exp(-var_71_524 * var_71_523) * 0.7

			love.graphics.setColor(var_71_507[1], var_71_507[2], var_71_507[3], var_71_526)
			love.graphics.setLineWidth(2 + var_71_525 * 1.2)
			love.graphics.line(var_71_511, var_71_512, var_71_516, var_71_517)
		end

		love.graphics.setBlendMode(var_71_518 or "alpha", var_71_519 or "alphamultiply")
		love.graphics.setColor(var_71_507[1], var_71_507[2], var_71_507[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_511, var_71_512, var_71_516, var_71_517)
		love.graphics.setLineWidth(1)
	end

	if (var_71_50 or var_71_49.isDisappearing) and var_71_49.unlockLineProgress > 0 then
		local var_71_527 = {
			1,
			1,
			1,
			1
		}
		local var_71_528 = var_0_91.iteminventory
		local var_71_529 = var_71_528 and var_71_528.maxed or false
		local var_71_530 = var_71_528 and var_71_50 and var_0_102("iteminventory") and arg_71_1 >= var_71_528.cost

		if var_71_529 then
			var_71_527 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_530 then
			var_71_527 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_527 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_531 = var_71_19.shopreroll.x
		local var_71_532 = var_71_19.shopreroll.y
		local var_71_533 = var_71_19.iteminventory.x
		local var_71_534 = var_71_19.iteminventory.y
		local var_71_535 = var_71_49.unlockLineProgress
		local var_71_536 = var_71_531 + (var_71_533 - var_71_531) * var_71_535
		local var_71_537 = var_71_532 + (var_71_534 - var_71_532) * var_71_535
		local var_71_538, var_71_539 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_540 = 0.18
		local var_71_541 = 6
		local var_71_542 = 10
		local var_71_543 = 2.3

		for iter_71_35 = 1, var_71_542 do
			local var_71_544 = (iter_71_35 - 0.5) / var_71_542
			local var_71_545 = var_71_541 * var_71_544^1.05
			local var_71_546 = var_71_540 * math.exp(-var_71_544 * var_71_543) * 0.7

			love.graphics.setColor(var_71_527[1], var_71_527[2], var_71_527[3], var_71_546)
			love.graphics.setLineWidth(2 + var_71_545 * 1.2)
			love.graphics.line(var_71_531, var_71_532, var_71_536, var_71_537)
		end

		love.graphics.setBlendMode(var_71_538 or "alpha", var_71_539 or "alphamultiply")
		love.graphics.setColor(var_71_527[1], var_71_527[2], var_71_527[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_531, var_71_532, var_71_536, var_71_537)
		love.graphics.setLineWidth(1)
	end

	if (var_71_51 or var_71_52.isDisappearing) and var_71_52.unlockLineProgress > 0 then
		local var_71_547 = {
			1,
			1,
			1,
			1
		}
		local var_71_548 = var_0_91.iteminventory2
		local var_71_549 = var_71_548 and var_71_548.maxed or false
		local var_71_550 = var_71_548 and var_71_51 and var_0_102("iteminventory2") and arg_71_1 >= var_71_548.cost

		if var_71_549 then
			var_71_547 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_550 then
			var_71_547 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_547 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_551 = var_71_19.iteminventory.x
		local var_71_552 = var_71_19.iteminventory.y
		local var_71_553 = var_71_19.iteminventory2.x
		local var_71_554 = var_71_19.iteminventory2.y
		local var_71_555 = var_71_52.unlockLineProgress
		local var_71_556 = var_71_551 + (var_71_553 - var_71_551) * var_71_555
		local var_71_557 = var_71_552 + (var_71_554 - var_71_552) * var_71_555
		local var_71_558, var_71_559 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_560 = 0.18
		local var_71_561 = 6
		local var_71_562 = 10
		local var_71_563 = 2.3

		for iter_71_36 = 1, var_71_562 do
			local var_71_564 = (iter_71_36 - 0.5) / var_71_562
			local var_71_565 = var_71_561 * var_71_564^1.05
			local var_71_566 = var_71_560 * math.exp(-var_71_564 * var_71_563) * 0.7

			love.graphics.setColor(var_71_547[1], var_71_547[2], var_71_547[3], var_71_566)
			love.graphics.setLineWidth(2 + var_71_565 * 1.2)
			love.graphics.line(var_71_551, var_71_552, var_71_556, var_71_557)
		end

		love.graphics.setBlendMode(var_71_558 or "alpha", var_71_559 or "alphamultiply")
		love.graphics.setColor(var_71_547[1], var_71_547[2], var_71_547[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_551, var_71_552, var_71_556, var_71_557)
		love.graphics.setLineWidth(1)
	end

	if (var_71_42 or var_71_41.isDisappearing) and var_71_41.unlockLineProgress > 0 then
		local var_71_567 = {
			1,
			1,
			1,
			1
		}
		local var_71_568 = var_0_91.slotadvanced2
		local var_71_569 = var_71_568 and var_71_568.maxed or false
		local var_71_570 = var_71_568 and var_71_42 and arg_71_1 >= var_71_568.cost

		if var_71_569 then
			var_71_567 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_570 then
			var_71_567 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_567 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_571 = var_71_19.slotadvanced.x
		local var_71_572 = var_71_19.slotadvanced.y
		local var_71_573 = var_71_19.slotadvanced2.x
		local var_71_574 = var_71_19.slotadvanced2.y
		local var_71_575 = var_71_41.unlockLineProgress
		local var_71_576 = var_71_571 + (var_71_573 - var_71_571) * var_71_575
		local var_71_577 = var_71_572 + (var_71_574 - var_71_572) * var_71_575
		local var_71_578, var_71_579 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_580 = 0.18
		local var_71_581 = 6
		local var_71_582 = 10
		local var_71_583 = 2.3

		for iter_71_37 = 1, var_71_582 do
			local var_71_584 = (iter_71_37 - 0.5) / var_71_582
			local var_71_585 = var_71_581 * var_71_584^1.05
			local var_71_586 = var_71_580 * math.exp(-var_71_584 * var_71_583) * 0.7

			love.graphics.setColor(var_71_567[1], var_71_567[2], var_71_567[3], var_71_586)
			love.graphics.setLineWidth(2 + var_71_585 * 1.2)
			love.graphics.line(var_71_571, var_71_572, var_71_576, var_71_577)
		end

		love.graphics.setBlendMode(var_71_578 or "alpha", var_71_579 or "alphamultiply")
		love.graphics.setColor(var_71_567[1], var_71_567[2], var_71_567[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_571, var_71_572, var_71_576, var_71_577)
		love.graphics.setLineWidth(1)
	end

	if (var_71_56 or var_71_55.isDisappearing) and var_71_55.unlockLineProgress > 0 then
		local var_71_587 = {
			1,
			1,
			1,
			1
		}
		local var_71_588 = var_0_91.slotadvanced3
		local var_71_589 = var_71_588 and var_71_588.maxed or false
		local var_71_590 = var_71_588 and var_71_56 and arg_71_1 >= var_71_588.cost

		if var_71_589 then
			var_71_587 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_590 then
			var_71_587 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_587 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_591 = var_71_19.slotadvanced2.x
		local var_71_592 = var_71_19.slotadvanced2.y
		local var_71_593 = var_71_19.slotadvanced3.x
		local var_71_594 = var_71_19.slotadvanced3.y
		local var_71_595 = var_71_55.unlockLineProgress
		local var_71_596 = var_71_591 + (var_71_593 - var_71_591) * var_71_595
		local var_71_597 = var_71_592 + (var_71_594 - var_71_592) * var_71_595
		local var_71_598, var_71_599 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_600 = 0.18
		local var_71_601 = 6
		local var_71_602 = 10
		local var_71_603 = 2.3

		for iter_71_38 = 1, var_71_602 do
			local var_71_604 = (iter_71_38 - 0.5) / var_71_602
			local var_71_605 = var_71_601 * var_71_604^1.05
			local var_71_606 = var_71_600 * math.exp(-var_71_604 * var_71_603) * 0.7

			love.graphics.setColor(var_71_587[1], var_71_587[2], var_71_587[3], var_71_606)
			love.graphics.setLineWidth(2 + var_71_605 * 1.2)
			love.graphics.line(var_71_591, var_71_592, var_71_596, var_71_597)
		end

		love.graphics.setBlendMode(var_71_598 or "alpha", var_71_599 or "alphamultiply")
		love.graphics.setColor(var_71_587[1], var_71_587[2], var_71_587[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_591, var_71_592, var_71_596, var_71_597)
		love.graphics.setLineWidth(1)
	end

	if (var_71_58 or var_71_57.isDisappearing) and var_71_57.unlockLineProgress > 0 then
		local var_71_607 = {
			1,
			1,
			1,
			1
		}
		local var_71_608 = var_0_91.slotrare
		local var_71_609 = var_71_608 and var_71_608.maxed or false
		local var_71_610 = var_71_608 and var_71_58 and var_0_102("slotrare") and arg_71_1 >= var_71_608.cost

		if var_71_609 then
			var_71_607 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_610 then
			var_71_607 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_607 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_611 = var_71_19.slotadvanced3.x
		local var_71_612 = var_71_19.slotadvanced3.y
		local var_71_613 = var_71_19.slotrare.x
		local var_71_614 = var_71_19.slotrare.y
		local var_71_615 = var_71_57.unlockLineProgress
		local var_71_616 = var_71_611 + (var_71_613 - var_71_611) * var_71_615
		local var_71_617 = var_71_612 + (var_71_614 - var_71_612) * var_71_615
		local var_71_618, var_71_619 = love.graphics.getBlendMode()

		love.graphics.setBlendMode("add", "alphamultiply")

		local var_71_620 = 0.18
		local var_71_621 = 6
		local var_71_622 = 10
		local var_71_623 = 2.3

		for iter_71_39 = 1, var_71_622 do
			local var_71_624 = (iter_71_39 - 0.5) / var_71_622
			local var_71_625 = var_71_621 * var_71_624^1.05
			local var_71_626 = var_71_620 * math.exp(-var_71_624 * var_71_623) * 0.7

			love.graphics.setColor(var_71_607[1], var_71_607[2], var_71_607[3], var_71_626)
			love.graphics.setLineWidth(2 + var_71_625 * 1.2)
			love.graphics.line(var_71_611, var_71_612, var_71_616, var_71_617)
		end

		love.graphics.setBlendMode(var_71_618 or "alpha", var_71_619 or "alphamultiply")
		love.graphics.setColor(var_71_607[1], var_71_607[2], var_71_607[3], 1)
		love.graphics.setLineWidth(2)
		love.graphics.line(var_71_611, var_71_612, var_71_616, var_71_617)
		love.graphics.setLineWidth(1)
	end

	local function var_71_627(arg_73_0, arg_73_1, arg_73_2, arg_73_3)
		local var_73_0 = var_0_72(arg_73_0)
		local var_73_1 = var_0_91[arg_73_0]
		local var_73_2 = var_73_1.maxed or false
		local var_73_3 = var_0_102(arg_73_0) and arg_71_1 >= var_73_1.cost
		local var_73_4 = {
			1,
			1,
			1,
			1
		}

		if var_73_2 then
			var_73_4 = {
				var_0_84("#6FAACC")
			}
		elseif var_73_3 then
			var_73_4 = {
				var_0_84("#5FAF6F")
			}
		else
			var_73_4 = {
				var_0_84("#A84F5A")
			}
		end

		local var_73_5, var_73_6 = arg_73_1:getDimensions()
		local var_73_7 = var_73_0.scaleX or 1
		local var_73_8 = var_73_0.scaleY or 1
		local var_73_9 = arg_73_2

		if var_73_0.shakeT > 0 then
			var_73_9 = var_73_9 + var_73_0.shakeX
		end

		local var_73_10 = math.max(var_73_7, var_73_8)
		local var_73_11 = var_73_9 - var_73_5 * var_73_10 / 2
		local var_73_12 = arg_73_3 - var_73_6 * var_73_10 / 2

		var_0_62[arg_73_0] = {
			x = var_73_11,
			y = var_73_12,
			w = var_73_5 * var_73_10,
			h = var_73_6 * var_73_10
		}

		if (var_73_3 or var_73_2) and var_0_10 and var_0_11 then
			love.graphics.setShader(var_0_10)

			local var_73_13 = 0.8 + 0.2 * math.sin(love.timer.getTime() * 3)

			var_0_10:send("glowColor", {
				var_73_4[1],
				var_73_4[2],
				var_73_4[3],
				var_73_13
			})

			local var_73_14 = math.max(var_73_5, var_73_6) * 2 * var_73_7

			love.graphics.draw(var_0_11, var_73_9, arg_73_3, 0, var_73_14, var_73_14, 0.5, 0.5)
			love.graphics.setShader()
		end

		if var_73_3 and not var_73_2 then
			local var_73_15 = love.timer.getTime()
			local var_73_16 = 1 + 0.04 * math.sin(var_73_15 * 3.5)

			var_73_7 = var_73_7 * var_73_16
			var_73_8 = var_73_8 * var_73_16

			local var_73_17 = 0.05 + 0.05 * math.sin(var_73_15 * 3.5)

			if var_0_9 then
				love.graphics.setShader(var_0_9)
				love.graphics.setColor(1, 1, 1, var_73_17)
				love.graphics.draw(arg_73_1, var_73_9, arg_73_3, 0, var_73_7, var_73_8, var_73_5 / 2, var_73_6 / 2)
				love.graphics.setShader()
			end
		end

		if var_73_3 and not var_73_2 then
			local var_73_18 = math.max(0, love.timer.getDelta() or 0)
			local var_73_19 = 1 - math.exp(-3 * var_73_18)

			if #var_73_0.energyParticles < 8 and var_73_19 > love.math.random() then
				table.insert(var_73_0.energyParticles, {
					type = "sparkle",
					life = 0.6,
					x = (love.math.random() - 0.5) * var_73_5 * var_73_7 * 1.2,
					y = (love.math.random() - 0.5) * var_73_6 * var_73_8 * 1.2,
					size = love.math.random(1, 3)
				})
			end

			for iter_73_0 = #var_73_0.energyParticles, 1, -1 do
				local var_73_20 = var_73_0.energyParticles[iter_73_0]

				if var_73_20.type == "sparkle" then
					var_73_20.life = var_73_20.life - var_73_18

					if var_73_20.life <= 0 then
						table.remove(var_73_0.energyParticles, iter_73_0)
					else
						local var_73_21 = math.sin(var_73_20.life / 0.6 * math.pi)

						love.graphics.setColor(1, 1, 1, var_73_21)

						local var_73_22 = math.floor(var_73_20.size)

						if var_73_22 < 2 then
							love.graphics.rectangle("fill", math.floor(var_73_9 + var_73_20.x), math.floor(arg_73_3 + var_73_20.y), 1, 1)
						else
							local var_73_23 = math.floor(var_73_9 + var_73_20.x)
							local var_73_24 = math.floor(arg_73_3 + var_73_20.y)
							local var_73_25 = math.floor(var_73_22 / 2)

							love.graphics.rectangle("fill", var_73_23 - var_73_25, var_73_24, var_73_22, 1)
							love.graphics.rectangle("fill", var_73_23, var_73_24 - var_73_25, 1, var_73_22)
						end
					end
				end
			end
		end

		if var_0_9 then
			love.graphics.setShader(var_0_9)

			local var_73_26 = {
				var_73_4[1],
				var_73_4[2],
				var_73_4[3],
				var_73_4[4]
			}

			if var_73_3 and not var_73_2 then
				local var_73_27 = 0.5 + 0.5 * math.sin(var_73_0.pulseT * 2)

				for iter_73_1 = 1, 3 do
					var_73_26[iter_73_1] = var_73_26[iter_73_1] + (1 - var_73_26[iter_73_1]) * var_73_27 * 0.5
				end
			end

			love.graphics.setColor(var_73_26)

			local var_73_28 = 0.5
			local var_73_29 = 1.5

			for iter_73_2 = -var_73_29, var_73_29, var_73_28 do
				for iter_73_3 = -var_73_29, var_73_29, var_73_28 do
					if iter_73_2 ~= 0 or iter_73_3 ~= 0 then
						love.graphics.draw(arg_73_1, var_73_9 + iter_73_2 * var_73_7, arg_73_3 + iter_73_3 * var_73_8, 0, var_73_7, var_73_8, var_73_5 / 2, var_73_6 / 2)
					end
				end
			end

			love.graphics.setShader()
		end

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(arg_73_1, var_73_9, arg_73_3, 0, var_73_7, var_73_8, var_73_5 / 2, var_73_6 / 2)

		if var_0_69 and var_73_1.nodeId then
			local var_73_30 = var_0_16 or love.graphics.getFont()
			local var_73_31 = love.graphics.getFont()

			love.graphics.setFont(var_73_30)

			local var_73_32 = tostring(var_73_1.nodeId)
			local var_73_33 = 0.75
			local var_73_34 = var_73_30:getWidth(var_73_32) * var_73_33
			local var_73_35 = math.floor(var_73_9 - var_73_34 / 2)
			local var_73_36 = math.floor(arg_73_3 - var_73_6 * var_73_8 / 2 - 12)

			love.graphics.setColor(0, 0, 0, 0.85)
			love.graphics.print(var_73_32, var_73_35 + 1, var_73_36 + 1, 0, var_73_33, var_73_33)
			love.graphics.setColor(1, 0.92, 0.35, 1)
			love.graphics.print(var_73_32, var_73_35, var_73_36, 0, var_73_33, var_73_33)
			love.graphics.setFont(var_73_31)
		end

		if var_73_0.flashT > 0 and var_0_9 then
			love.graphics.setShader(var_0_9)
			love.graphics.setColor(1, 1, 1, var_73_0.flashT / 0.2)
			love.graphics.draw(arg_73_1, var_73_9, arg_73_3, 0, var_73_7, var_73_8, var_73_5 / 2, var_73_6 / 2)
			love.graphics.setShader()
		end

		if var_73_3 or var_73_2 then
			local var_73_37 = 0.6

			if var_73_37 > var_73_0.shineT then
				local var_73_38 = var_73_0.shineT / var_73_37

				love.graphics.stencil(function()
					love.graphics.draw(arg_73_1, var_73_9, arg_73_3, 0, var_73_7, var_73_8, var_73_5 / 2, var_73_6 / 2)
				end, "replace", 1)
				love.graphics.setStencilTest("greater", 0)
				love.graphics.setColor(1, 1, 1, 0.6 * (1 - math.abs(var_73_38 - 0.5) * 2))

				local var_73_39 = 20 * var_73_7
				local var_73_40 = var_73_9 - var_73_5 * var_73_7 / 2
				local var_73_41 = var_73_5 * var_73_7
				local var_73_42 = var_73_40 - var_73_39
				local var_73_43 = var_73_42 + (var_73_40 + var_73_41 + var_73_39 - var_73_42) * var_73_38

				love.graphics.push()
				love.graphics.translate(var_73_43, arg_73_3)
				love.graphics.rotate(-0.5)

				local var_73_44 = var_73_6 * var_73_8 * 4

				love.graphics.rectangle("fill", -var_73_39 / 2, -var_73_44 / 2, var_73_39, var_73_44)
				love.graphics.pop()
				love.graphics.setStencilTest()
			end
		end

		if var_0_74 == arg_73_0 then
			local var_73_45 = 2 * var_73_7
			local var_73_46 = 6 * var_73_7
			local var_73_47 = 2
			local var_73_48 = var_73_5 * var_73_7
			local var_73_49 = var_73_6 * var_73_8
			local var_73_50 = var_73_48 / 2 + var_73_45
			local var_73_51 = var_73_49 / 2 + var_73_45
			local var_73_52 = var_73_9 - var_73_50
			local var_73_53 = arg_73_3 - var_73_51
			local var_73_54 = var_73_9 + var_73_50
			local var_73_55 = arg_73_3 + var_73_51

			love.graphics.setColor(0, 0, 0, 1)

			local var_73_56 = var_73_47 + 2
			local var_73_57 = var_73_46 + 2
			local var_73_58 = var_73_52 - 1
			local var_73_59 = var_73_53 - 1
			local var_73_60 = var_73_54 + 1
			local var_73_61 = var_73_55 + 1

			love.graphics.rectangle("fill", var_73_58 + 1, var_73_59, var_73_57 - 1, var_73_56)
			love.graphics.rectangle("fill", var_73_58, var_73_59 + 1, var_73_56, var_73_57 - 1)
			love.graphics.rectangle("fill", var_73_60 - var_73_57, var_73_59, var_73_57 - 1, var_73_56)
			love.graphics.rectangle("fill", var_73_60 - var_73_56, var_73_59 + 1, var_73_56, var_73_57 - 1)
			love.graphics.rectangle("fill", var_73_58 + 1, var_73_61 - var_73_56, var_73_57 - 1, var_73_56)
			love.graphics.rectangle("fill", var_73_58, var_73_61 - var_73_57, var_73_56, var_73_57 - 1)
			love.graphics.rectangle("fill", var_73_60 - var_73_57, var_73_61 - var_73_56, var_73_57 - 1, var_73_56)
			love.graphics.rectangle("fill", var_73_60 - var_73_56, var_73_61 - var_73_57, var_73_56, var_73_57 - 1)
			love.graphics.setColor(1, 1, 1, 1)

			local var_73_62 = var_73_52
			local var_73_63 = var_73_53
			local var_73_64 = var_73_54
			local var_73_65 = var_73_55

			love.graphics.rectangle("fill", var_73_62 + 1, var_73_63, var_73_46 - 1, var_73_47)
			love.graphics.rectangle("fill", var_73_62, var_73_63 + 1, var_73_47, var_73_46 - 1)
			love.graphics.rectangle("fill", var_73_64 - var_73_46, var_73_63, var_73_46 - 1, var_73_47)
			love.graphics.rectangle("fill", var_73_64 - var_73_47, var_73_63 + 1, var_73_47, var_73_46 - 1)
			love.graphics.rectangle("fill", var_73_62 + 1, var_73_65 - var_73_47, var_73_46 - 1, var_73_47)
			love.graphics.rectangle("fill", var_73_62, var_73_65 - var_73_46, var_73_47, var_73_46 - 1)
			love.graphics.rectangle("fill", var_73_64 - var_73_46, var_73_65 - var_73_47, var_73_46 - 1, var_73_47)
			love.graphics.rectangle("fill", var_73_64 - var_73_47, var_73_65 - var_73_46, var_73_47, var_73_46 - 1)
		end
	end

	local var_71_628 = require("src.ui.effects").upgrade_keystone
	local var_71_629 = {}

	for iter_71_40 in pairs(var_71_628.seen or {}) do
		local var_71_630 = var_71_19[iter_71_40]
		local var_71_631 = var_0_91[iter_71_40]

		if var_71_630 and var_71_631 and var_71_628.IDS[iter_71_40] then
			local var_71_632 = var_71_631.maxed and "maxed" or var_0_102(iter_71_40) and arg_71_1 >= var_71_631.cost and "ready" or "locked"
			local var_71_633 = var_0_7[iter_71_40]
			local var_71_634 = var_71_633 and var_71_633:getWidth() or 32

			var_71_629[#var_71_629 + 1] = {
				x = var_71_630.x - var_71_634 / 2,
				y = var_71_630.y - var_71_634 / 2,
				w = var_71_634,
				h = var_71_634,
				state = var_71_632,
				id = iter_71_40,
				size = var_71_634
			}
		end
	end

	var_71_628.draw(var_71_629, nil, love.timer.getTime())

	local var_71_635 = var_0_72("maxhp")

	if var_0_7.maxhp and (var_71_20 and var_71_635.revealed or var_71_635.isDisappearing) then
		var_71_627("maxhp", var_0_7.maxhp, var_71_19.maxhp.x, var_71_19.maxhp.y)
	end

	if var_0_7.noviceshield and (var_71_21 and var_71_22.revealed or var_71_22.isDisappearing) then
		var_71_627("noviceshield", var_0_7.noviceshield, var_71_19.noviceshield.x, var_71_19.noviceshield.y)
	end

	if var_0_7.startgold and (var_71_21 and var_71_23.revealed or var_71_23.isDisappearing) then
		var_71_627("startgold", var_0_7.startgold, var_71_19.startgold.x, var_71_19.startgold.y)
	end

	if var_0_7.startingmerccontract and (var_71_30 and var_71_24.revealed or var_71_24.isDisappearing) then
		var_71_627("startingmerccontract", var_0_7.startingmerccontract, var_71_19.startingmerccontract.x, var_71_19.startingmerccontract.y)
	end

	if var_0_7.comebackspin and (var_71_26 and var_71_25.revealed or var_71_25.isDisappearing) then
		var_71_627("comebackspin", var_0_7.comebackspin, var_71_19.comebackspin.x, var_71_19.comebackspin.y)
	end

	if var_0_7.gateheal and (var_71_28 and var_71_27.revealed or var_71_27.isDisappearing) then
		var_71_627("gateheal", var_0_7.gateheal, var_71_19.gateheal.x, var_71_19.gateheal.y)
	end

	if var_0_7.comebackgold and (var_71_30 and var_71_29.revealed or var_71_29.isDisappearing) then
		var_71_627("comebackgold", var_0_7.comebackgold, var_71_19.comebackgold.x, var_71_19.comebackgold.y)
	end

	if var_0_7.maxhp2 and (var_71_32 and var_71_31.revealed or var_71_31.isDisappearing) then
		var_71_627("maxhp2", var_0_7.maxhp2, var_71_19.maxhp2.x, var_71_19.maxhp2.y)
	end

	if var_0_7.startgold2 and (var_71_30 and var_71_33.revealed or var_71_33.isDisappearing) then
		var_71_627("startgold2", var_0_7.startgold2, var_71_19.startgold2.x, var_71_19.startgold2.y)
	end

	if var_0_7.slotodds then
		var_71_627("slotodds", var_0_7.slotodds, var_71_19.slotodds.x, var_71_19.slotodds.y)
	end

	for iter_71_41, iter_71_42 in pairs(var_0_91) do
		local var_71_636 = iter_71_42.parent

		if var_71_636 and var_0_7[iter_71_41] and var_71_19[iter_71_41] then
			local var_71_637 = var_0_72(iter_71_41)

			if (var_0_91[var_71_636].maxed or iter_71_42.maxed) and var_71_637.revealed or var_71_637.isDisappearing then
				var_71_627(iter_71_41, var_0_7[iter_71_41], var_71_19[iter_71_41].x, var_71_19[iter_71_41].y)
			end
		end
	end

	if var_0_7.slotadvanced and (var_71_386 and var_71_385.revealed or var_71_385.isDisappearing) then
		var_71_627("slotadvanced", var_0_7.slotadvanced, var_71_19.slotadvanced.x, var_71_19.slotadvanced.y)
	end

	if var_0_7.corereroll and (var_71_42 and var_71_43.revealed or var_71_43.isDisappearing) then
		var_71_627("corereroll", var_0_7.corereroll, var_71_19.corereroll.x, var_71_19.corereroll.y)
	end

	if var_0_7.firstcorespin and (var_71_45 and var_71_44.revealed or var_71_44.isDisappearing) then
		var_71_627("firstcorespin", var_0_7.firstcorespin, var_71_19.firstcorespin.x, var_71_19.firstcorespin.y)
	end

	if var_0_7.firstcoreuncommon and (var_71_47 and var_71_46.revealed or var_71_46.isDisappearing) then
		var_71_627("firstcoreuncommon", var_0_7.firstcoreuncommon, var_71_19.firstcoreuncommon.x, var_71_19.firstcoreuncommon.y)
	end

	if var_0_7.shopreroll and (var_71_42 and var_71_48.revealed or var_71_48.isDisappearing) then
		var_71_627("shopreroll", var_0_7.shopreroll, var_71_19.shopreroll.x, var_71_19.shopreroll.y)
	end

	if var_0_7.iteminventory and (var_71_50 and var_71_49.revealed or var_71_49.isDisappearing) then
		var_71_627("iteminventory", var_0_7.iteminventory, var_71_19.iteminventory.x, var_71_19.iteminventory.y)
	end

	if var_0_7.iteminventory2 and (var_71_51 and var_71_52.revealed or var_71_52.isDisappearing) then
		var_71_627("iteminventory2", var_0_7.iteminventory2, var_71_19.iteminventory2.x, var_71_19.iteminventory2.y)
	end

	if false and var_0_7.itemresearch and (var_71_50 and var_71_53.revealed or var_71_53.isDisappearing) then
		var_71_627("itemresearch", var_0_7.itemresearch, var_71_19.itemresearch.x, var_71_19.itemresearch.y)
	end

	if false and var_0_7.shoppin and (var_71_50 and var_71_54.revealed or var_71_54.isDisappearing) then
		var_71_627("shoppin", var_0_7.shoppin, var_71_19.shoppin.x, var_71_19.shoppin.y)
	end

	if var_0_7.slotadvanced2 and (var_71_42 and var_71_41.revealed or var_71_41.isDisappearing) then
		var_71_627("slotadvanced2", var_0_7.slotadvanced2, var_71_19.slotadvanced2.x, var_71_19.slotadvanced2.y)
	end

	if var_0_7.slotadvanced3 and (var_71_56 and var_71_55.revealed or var_71_55.isDisappearing) then
		var_71_627("slotadvanced3", var_0_7.slotadvanced3, var_71_19.slotadvanced3.x, var_71_19.slotadvanced3.y)
	end

	if var_0_7.slotrare and (var_71_58 and var_71_57.revealed or var_71_57.isDisappearing) then
		var_71_627("slotrare", var_0_7.slotrare, var_71_19.slotrare.x, var_71_19.slotrare.y)
	end

	if var_0_7.maxunit and (var_71_20 and var_71_243.revealed or var_71_243.isDisappearing) then
		var_71_627("maxunit", var_0_7.maxunit, var_71_19.maxunit.x, var_71_19.maxunit.y)
	end

	if var_0_7.maxunit2 and (var_71_34 and var_71_35.revealed or var_71_35.isDisappearing) then
		var_71_627("maxunit2", var_0_7.maxunit2, var_71_19.maxunit2.x, var_71_19.maxunit2.y)
	end

	if var_0_7.maxunit3 and (var_71_37 and var_71_36.revealed or var_71_36.isDisappearing) then
		var_71_627("maxunit3", var_0_7.maxunit3, var_71_19.maxunit3.x, var_71_19.maxunit3.y)
	end

	local var_71_638 = require("src.ui.effects").upgrade_keystone
	local var_71_639 = {}

	for iter_71_43 in pairs(var_71_638.IDS) do
		if var_0_62[iter_71_43] then
			var_71_639[iter_71_43] = true
		end
	end

	var_71_638.seen = var_71_639

	love.graphics.pop()
	love.graphics.setColor(0, 0, 0, 0.4)

	local var_71_640 = 100

	for iter_71_44 = 0, var_71_640 do
		local var_71_641 = 0.6 * (1 - iter_71_44 / var_71_640)

		love.graphics.setColor(0, 0, 0, var_71_641)
		love.graphics.rectangle("fill", 0, iter_71_44, var_71_0, 1)
		love.graphics.rectangle("fill", 0, var_71_1 - 1 - iter_71_44, var_71_0, 1)
		love.graphics.rectangle("fill", iter_71_44, 0, 1, var_71_1)
		love.graphics.rectangle("fill", var_71_0 - 1 - iter_71_44, 0, 1, var_71_1)
	end

	var_0_0.drawSectionTitles(arg_71_0, var_71_19, var_71_0, var_71_1)

	if var_0_12 then
		local var_71_642, var_71_643 = var_0_12:getDimensions()
		local var_71_644 = 1.5
		local var_71_645 = 20
		local var_71_646 = 10
		local var_71_647 = tostring(arg_71_1 or 0)
		local var_71_648 = var_0_14 or love.graphics.getFont()

		love.graphics.setFont(var_71_648)

		local var_71_649 = var_0_37(var_71_648)
		local var_71_650 = 1.1
		local var_71_651 = var_0_110(var_71_647, var_71_648, var_71_650)
		local var_71_652 = var_71_649:getHeight() * var_71_650

		var_0_6.track(var_0_34, arg_71_1, arg_71_0)

		local var_71_653, var_71_654, var_71_655 = var_0_6.getPunch(var_0_34)
		local var_71_656 = var_71_650 * var_71_653
		local var_71_657 = var_71_650 * var_71_654
		local var_71_658 = var_71_642 * var_71_644 + var_71_646 + var_71_651
		local var_71_659 = var_71_0 - var_71_645 - var_71_658
		local var_71_660 = var_71_645

		if not arg_71_2 then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(var_0_12, math.floor(var_71_659), math.floor(var_71_660), 0, var_71_644, var_71_644)

			local var_71_661 = var_71_660 + (var_71_643 * var_71_644 - var_71_652) / 2
			local var_71_662 = var_71_659 + var_71_642 * var_71_644 + var_71_646
			local var_71_663 = var_0_110(var_71_647, var_71_648, var_71_656)
			local var_71_664 = var_71_649:getHeight() * var_71_657
			local var_71_665 = var_71_662 + (var_71_651 - var_71_663) * 0.5 + var_71_655
			local var_71_666 = var_71_661 + (var_71_652 - var_71_664) * 0.5

			love.graphics.print(var_71_647, math.floor(var_71_665), math.floor(var_71_666), 0, var_71_656, var_71_657)
		end

		if not var_0_69 then
			var_0_70 = {}
		else
			local var_71_667 = 20
			local var_71_668 = 5
			local var_71_669 = var_71_660 + (var_71_643 * var_71_644 - var_71_667) / 2
			local var_71_670 = var_71_659 - var_71_667 - var_71_668

			love.graphics.setColor(0.2, 0.8, 0.2, 1)
			love.graphics.rectangle("fill", var_71_670, var_71_669, var_71_667, var_71_667)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print("+", var_71_670 + 5, var_71_669 + 2)

			var_0_70.plus = {
				x = var_71_670,
				y = var_71_669,
				w = var_71_667,
				h = var_71_667
			}

			local var_71_671 = var_71_670 - var_71_667 - var_71_668

			love.graphics.setColor(0.8, 0.2, 0.2, 1)
			love.graphics.rectangle("fill", var_71_671, var_71_669, var_71_667, var_71_667)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print("-", var_71_671 + 7, var_71_669 + 2)

			var_0_70.minus = {
				x = var_71_671,
				y = var_71_669,
				w = var_71_667,
				h = var_71_667
			}
		end
	end

	var_0_0.drawSandboxUnlockAll(arg_71_0, 32 + (var_0_12 and var_0_12:getHeight() * 1.5 or 32))
	love.graphics.setColor(1, 1, 1, 1)

	if var_0_24 then
		local var_71_672 = var_0_25.scale
		local var_71_673, var_71_674 = var_0_24:getDimensions()
		local var_71_675 = 60
		local var_71_676 = 60
		local var_71_677 = var_71_673 * var_71_672
		local var_71_678 = var_71_674 * var_71_672

		var_0_25.rect = {
			x = var_71_675 - var_71_677 / 2,
			y = var_71_676 - var_71_678 / 2,
			w = var_71_677,
			h = var_71_678
		}

		love.graphics.draw(var_0_24, var_71_675, var_71_676, 0, var_71_672, var_71_672, var_71_673 / 2, var_71_674 / 2)
	end

	if var_0_18 then
		local var_71_679, var_71_680 = var_0_18:getDimensions()
		local var_71_681 = 1.15
		local var_71_682 = math.floor((var_71_0 - var_71_679 * var_71_681) / 2)
		local var_71_683 = 25

		love.graphics.draw(var_0_18, var_71_682, var_71_683, 0, var_71_681, var_71_681)
	else
		local var_71_684 = arg_71_0.fontTitle or love.graphics.getFont()

		love.graphics.setFont(var_71_684)

		local var_71_685 = arg_71_0 and arg_71_0.menuSettings and arg_71_0.menuSettings.language or "ko"
		local var_71_686 = var_0_3.getText("upgrade_title", var_71_685)
		local var_71_687 = 2
		local var_71_688 = var_71_684:getWidth(var_71_686) * var_71_687
		local var_71_689 = var_71_684:getHeight() * var_71_687

		love.graphics.print(var_71_686, (var_71_0 - var_71_688) / 2, 50, 0, var_71_687, var_71_687)
	end

	if var_0_21 and var_0_22 and var_0_23 then
		local var_71_690 = var_0_19 or arg_71_0.fontTitle or love.graphics.getFont()

		love.graphics.setFont(var_71_690)
		love.graphics.setColor(1, 1, 1, 1)

		local var_71_691 = 1
		local var_71_692 = 1.2
		local var_71_693 = 10
		local var_71_694 = 20
		local var_71_695 = 10
		local var_71_696 = arg_71_0 and arg_71_0.menuSettings and arg_71_0.menuSettings.language or "ko"
		local var_71_697 = rawget(_G, "Controller")

		if not var_71_697 or not var_71_697.isPad or not var_71_697.isPad() or not var_71_697.glyphRowSize then
			var_71_697 = nil
		end

		local function var_71_698(arg_75_0, arg_75_1)
			if var_71_697 then
				return var_71_697.glyphRowSize(arg_75_1)
			end

			local var_75_0, var_75_1 = arg_75_0:getDimensions()

			return var_75_0 * var_71_692, var_75_1 * var_71_692
		end

		local function var_71_699(arg_76_0, arg_76_1, arg_76_2, arg_76_3, arg_76_4)
			if var_71_697 then
				local var_76_0, var_76_1 = var_71_697.glyphRowSize(arg_76_1)

				var_71_697.drawGlyphRow(arg_76_1, math.floor(arg_76_2), math.floor(arg_76_3 + (arg_76_4 - var_76_1) / 2))
				love.graphics.setColor(1, 1, 1, 1)

				return
			end

			love.graphics.draw(arg_76_0, math.floor(arg_76_2), math.floor(arg_76_3), 0, var_71_692, var_71_692)
		end

		local var_71_700 = var_0_3.getText("upgrade_action_select_move", var_71_696)
		local var_71_701 = var_71_690:getWidth(var_71_700) * var_71_691
		local var_71_702 = var_71_690:getHeight() * var_71_691
		local var_71_703, var_71_704 = var_71_698(var_0_21, {
			"rstick"
		})
		local var_71_705 = math.max(var_71_702, var_71_704)
		local var_71_706 = var_71_701 + var_71_693 + var_71_703
		local var_71_707 = var_71_0 - var_71_694 - var_71_706
		local var_71_708 = var_0_3.getText("upgrade_action_zoom", var_71_696)
		local var_71_709 = var_71_690:getWidth(var_71_708) * var_71_691
		local var_71_710 = var_71_690:getHeight() * var_71_691
		local var_71_711, var_71_712 = var_71_698(var_0_23, {
			"leftshoulder",
			"rightshoulder"
		})
		local var_71_713 = math.max(var_71_710, var_71_712)
		local var_71_714 = var_71_709 + var_71_693 + var_71_711
		local var_71_715 = var_71_0 - var_71_694 - var_71_714
		local var_71_716 = var_71_1 - var_71_694 - var_71_713
		local var_71_717 = var_71_716 - var_71_695 - var_71_705
		local var_71_718 = var_71_717 + (var_71_704 - var_71_702) / 2

		love.graphics.print(var_71_700, math.floor(var_71_707), math.floor(var_71_718), 0, var_71_691, var_71_691)
		var_71_699(var_0_21, {
			"rstick"
		}, var_71_707 + var_71_701 + var_71_693, var_71_717, var_71_704)

		local var_71_719 = var_0_3.getText("upgrade_action_upgrade", var_71_696)
		local var_71_720 = var_71_690:getWidth(var_71_719) * var_71_691
		local var_71_721 = var_71_690:getHeight() * var_71_691
		local var_71_722, var_71_723 = var_71_698(var_0_22, {
			"@confirm"
		})
		local var_71_724 = math.max(var_71_721, var_71_723)
		local var_71_725 = var_71_720 + var_71_693 + var_71_722
		local var_71_726 = var_71_0 - var_71_694 - var_71_725
		local var_71_727 = var_71_717 - var_71_695 - var_71_724
		local var_71_728 = var_71_727 + (var_71_723 - var_71_721) / 2

		love.graphics.print(var_71_719, math.floor(var_71_726), math.floor(var_71_728), 0, var_71_691, var_71_691)
		var_71_699(var_0_22, {
			"@confirm"
		}, var_71_726 + var_71_720 + var_71_693, var_71_727, var_71_723)

		local var_71_729 = var_71_716 + (var_71_712 - var_71_710) / 2

		love.graphics.print(var_71_708, math.floor(var_71_715), math.floor(var_71_729), 0, var_71_691, var_71_691)
		var_71_699(var_0_23, {
			"leftshoulder",
			"rightshoulder"
		}, var_71_715 + var_71_709 + var_71_693, var_71_716, var_71_712)

		if var_71_697 then
			local var_71_730 = var_0_3.getText("pad_hint_back", var_71_696)
			local var_71_731 = var_71_690:getWidth(var_71_730) * var_71_691
			local var_71_732 = var_71_690:getHeight() * var_71_691
			local var_71_733, var_71_734 = var_71_698(nil, {
				"@back"
			})
			local var_71_735 = math.max(var_71_732, var_71_734)
			local var_71_736 = var_71_0 - var_71_694 - (var_71_731 + var_71_693 + var_71_733)
			local var_71_737 = var_71_727 - var_71_695 - var_71_735

			love.graphics.print(var_71_730, math.floor(var_71_736), math.floor(var_71_737 + (var_71_734 - var_71_732) / 2), 0, var_71_691, var_71_691)
			var_71_699(nil, {
				"@back"
			}, var_71_736 + var_71_731 + var_71_693, var_71_737, var_71_734)
		end
	end

	if var_0_74 and var_0_91[var_0_74] then
		local var_71_738 = var_0_91[var_0_74]
		local var_71_739 = var_71_738.maxed or false
		local var_71_740 = arg_71_1 >= var_71_738.cost
		local var_71_741 = var_0_102(var_0_74) and var_71_740
		local var_71_742 = {
			1,
			1,
			1,
			1
		}

		if var_71_739 then
			var_71_742 = {
				var_0_84("#6FAACC")
			}
		elseif var_71_741 then
			var_71_742 = {
				var_0_84("#5FAF6F")
			}
		else
			var_71_742 = {
				var_0_84("#A84F5A")
			}
		end

		local var_71_743 = var_71_742

		if not var_71_739 then
			var_71_743 = var_71_740 and {
				var_0_84("#5FAF6F")
			} or {
				var_0_84("#A84F5A")
			}
		end

		local var_71_744 = var_0_16 or font or arg_71_0 and arg_71_0.font or love.graphics.getFont()

		if not var_71_744 then
			return
		end

		local var_71_745 = var_0_37(var_71_744)
		local var_71_746 = var_71_744:getLineHeight()

		var_71_744:setLineHeight(1)
		love.graphics.setFont(var_71_744)

		local var_71_747 = 6
		local var_71_748 = 3
		local var_71_749 = 1
		local var_71_750 = 1
		local var_71_751 = 1.05
		local var_71_752 = arg_71_0 and arg_71_0.menuSettings and arg_71_0.menuSettings.language or "ko"
		local var_71_753 = var_0_3.getText(var_71_738.nameKey, var_71_752)
		local var_71_754 = var_0_3.getText(var_71_738.descKey, var_71_752)
		local var_71_755 = var_71_738.descNameKey and var_0_3.getText(var_71_738.descNameKey, var_71_752) or var_71_753

		if var_71_738.descNamed then
			var_71_754 = var_71_754:gsub("{faction}", (tostring(var_71_755):gsub("%%", "%%%%")))
		end

		local var_71_756, var_71_757, var_71_758, var_71_759, var_71_760 = var_0_0.unlockSectionText(var_71_738, var_71_752)
		local var_71_761 = var_71_756 ~= nil
		local var_71_762 = var_0_0.statKeyOf(var_0_74, var_71_738)
		local var_71_763 = var_71_762 and var_0_3.getText(var_71_762, var_71_752) or var_71_738.stat

		if var_71_739 then
			if var_0_74 == "slotadvanced" then
				var_71_763 = var_0_3.getGradeLabel("advanced", "Advanced", var_71_752) .. " 5%"
			elseif var_0_74 == "slotadvanced2" then
				var_71_763 = var_0_3.getGradeLabel("advanced", "Advanced", var_71_752) .. " 10%"
			elseif var_0_74 == "slotadvanced3" then
				var_71_763 = var_0_3.getGradeLabel("advanced", "Advanced", var_71_752) .. " 15%"
			elseif var_0_74 == "slotrare" then
				var_71_763 = var_0_3.getGradeLabel("rare", "Rare", var_71_752) .. " 2%"
			elseif var_71_738.maxedGrade then
				var_71_763 = var_0_3.getGradeLabel(var_71_738.maxedGrade, var_71_738.maxedGrade, var_71_752) .. " " .. tostring(var_71_738.maxedValue or "")
			else
				local var_71_764 = tostring(var_71_763):match("{[%w_]+%.png}")
				local var_71_765 = var_71_763:match("%->%s*(.+)$")

				if var_71_765 then
					var_71_763 = var_71_764 and var_71_764 .. " " .. var_71_765 or var_71_765
				end
			end
		end

		local var_71_766 = tostring(var_71_738.cost)

		if var_71_739 then
			var_71_766 = var_0_3.getText("upgrade_maxed", var_71_752)
		end

		local var_71_767 = (var_71_761 or var_71_738.wideTooltip) and 190 or 150
		local var_71_768 = var_0_110(var_71_753, var_71_744, var_71_750)

		var_71_744:setLineHeight(1.4)

		local var_71_769 = var_0_110(var_71_754, var_71_744, var_71_750)
		local var_71_770 = math.min(var_71_769, var_71_767)
		local var_71_771 = math.max(var_71_767, var_71_768)

		if var_71_738.descNamed then
			var_71_771 = math.max(var_71_771, math.min(var_71_769 + 6, (var_71_0 or 640) - 20 - var_71_747 * 2))
			var_71_770 = math.min(var_71_769, var_71_771)
		end

		local var_71_772 = (var_71_771 - 5) / var_71_750
		local var_71_773 = var_0_114(var_71_754, var_71_744, var_71_772, var_71_750, var_71_751)
		local var_71_774 = #var_71_773 * var_71_745:getHeight() * var_71_744:getLineHeight() * var_71_750

		var_71_744:setLineHeight(1)

		local var_71_775
		local var_71_776 = 0
		local var_71_777 = 0
		local var_71_778 = 0
		local var_71_779 = 0
		local var_71_780 = 0

		if var_71_761 then
			var_71_777 = var_0_110(var_71_756, var_71_744, var_71_750)
			var_71_778 = var_0_110(var_71_757, var_71_744, var_71_750)

			if var_71_759 then
				var_71_780 = var_0_110(var_71_759, var_71_744, var_71_750)
			end

			var_71_779 = math.min(var_0_110(var_71_758, var_71_744, var_71_750), var_71_767)

			var_71_744:setLineHeight(1.4)

			var_71_775 = var_0_114(var_71_758, var_71_744, var_71_772, var_71_750, var_71_751)
			var_71_776 = #var_71_775 * var_71_745:getHeight() * var_71_744:getLineHeight() * var_71_750

			var_71_744:setLineHeight(1)
		end

		local var_71_781 = var_0_110(var_71_763, var_71_744, var_71_750)

		if var_0_109(var_71_763) then
			local var_71_782, var_71_783 = var_71_763:match("^(.*%->%s*)(.*)$")

			if not var_71_782 or not var_71_783 then
				local var_71_784 = var_0_108(var_71_763, var_71_744, var_71_750, var_71_751)

				var_71_781 = var_0_111(var_71_784, var_71_744, var_71_750, var_71_751)
			else
				local var_71_785 = var_0_108(var_71_782, var_71_744, var_71_750, var_71_751)
				local var_71_786 = var_0_111(var_71_785, var_71_744, var_71_750, var_71_751)
				local var_71_787 = var_0_108(var_71_783, var_71_744, var_71_750, var_71_751)

				var_71_781 = var_71_786 + var_0_111(var_71_787, var_71_744, var_71_750, var_71_751)
			end
		end

		local var_71_788 = var_71_781

		if var_71_752 == "ja" then
			var_71_781 = var_71_781 + math.floor(18 * var_71_750 + 0.5)
		end

		local var_71_789 = 1
		local var_71_790 = 0
		local var_71_791 = 0

		if var_0_12 and not var_71_739 then
			var_71_790, var_71_791 = var_0_12:getDimensions()
		end

		local var_71_792 = 4
		local var_71_793 = 0

		if not var_71_739 then
			var_71_793 = var_71_790 * var_71_789 + var_71_792 + var_0_110(var_71_766, var_71_744, var_71_750)
		else
			var_71_793 = var_0_110(var_71_766, var_71_744, var_71_750)
		end

		local var_71_794
		local var_71_795
		local var_71_796 = true
		local var_71_797 = 0
		local var_71_798 = 0
		local var_71_799 = var_0_4.isChinese(var_71_752) and 32 or 0
		local var_71_800 = 9 * var_71_750
		local var_71_801 = 4 * var_71_750
		local var_71_802 = var_0_74 ~= "itemresearch" and var_0_74 ~= "shoppin" and (not var_71_738.reqFull or _G.GameEditionMode == "full") and not var_0_0.isEditionLocked(var_71_738)

		if var_0_103(var_0_74) then
			var_71_794 = var_0_105(var_0_74, var_71_752)
			var_71_795 = var_0_106(var_0_74, var_71_752)
			var_71_796 = var_0_101(var_0_74)

			if var_71_794 then
				local var_71_803 = 0

				if var_71_795 then
					local var_71_804 = var_0_110(" ", var_71_744, var_71_750)

					for iter_71_45, iter_71_46 in ipairs(var_71_795) do
						var_71_803 = var_71_803 + var_0_110(iter_71_46.text, var_71_744, var_71_750)

						if iter_71_45 < #var_71_795 then
							var_71_803 = var_71_803 + var_71_804
						end
					end
				else
					var_71_803 = var_0_110(var_71_794, var_71_744, var_71_750)
				end

				var_71_798 = var_71_803

				if var_71_802 then
					var_71_798 = var_71_798 + var_71_800 + var_71_801
				end

				var_71_797 = var_71_798 + var_71_799 * 2
			end
		end

		local var_71_805
		local var_71_806, var_71_807, var_71_808 = var_0_0.sectionRequirement(var_0_74)

		if var_71_806 then
			var_71_805 = {
				label = var_0_3.getText(var_71_808, var_71_752),
				count = var_71_806 .. "/" .. var_71_807,
				met = var_71_807 <= var_71_806
			}
			var_71_805.w = var_0_0.requirementRowWidth(var_71_805.label, var_71_805.count, var_71_744, var_71_750, var_71_800, var_71_801)
		end

		local var_71_809 = math.max(var_71_768, var_71_770, var_71_781, var_71_793, var_71_797, var_71_805 and var_71_805.w or 0, var_71_777, var_71_778, var_71_779, var_71_780)
		local var_71_810 = math.max(var_71_767, (var_71_0 or 640) - 20 - var_71_747 * 2)

		if var_71_810 < var_71_809 then
			var_71_809 = var_71_810
		end

		local var_71_811 = var_71_745:getHeight() * var_71_750
		local var_71_812 = 3
		local var_71_813 = 2
		local var_71_814 = var_71_811 + 4
		local var_71_815 = 0
		local var_71_816 = (var_71_794 and var_71_813 + var_71_814 + var_71_815 or 0) + (var_71_805 and var_71_813 + var_71_814 + var_71_815 or 0)
		local var_71_817 = 1
		local var_71_818 = 7
		local var_71_819 = 2
		local var_71_820 = var_71_818
		local var_71_821 = var_71_819
		local var_71_822 = var_71_811

		if var_71_761 then
			var_71_822 = var_71_811 * 2 + var_71_776 + var_71_818 + var_71_749 + var_71_819 + var_71_820 + var_71_749 + var_71_821 - var_71_817 + (var_71_759 and math.floor(var_71_811 * 1.4 + 0.5) or 0)
		end

		local var_71_823 = var_71_811 * 2 + var_71_774 + var_71_822 + (var_71_748 * 2 + var_71_749) * 3 + var_71_747 * 2 + var_71_812 + var_71_816
		local var_71_824 = var_71_809 + var_71_747 * 2
		local var_71_825 = var_0_62[var_0_74]
		local var_71_826 = var_71_825.x + var_71_825.w / 2
		local var_71_827 = var_71_825.y + var_71_825.h / 2
		local var_71_828 = var_71_0 / 2 + var_0_44 + (var_71_826 - var_71_0 / 2) * var_0_46
		local var_71_829 = var_71_1 / 2 + var_0_45 + (var_71_827 - var_71_1 / 2) * var_0_46
		local var_71_830 = var_71_825.w * var_0_46
		local var_71_831 = var_71_825.h * var_0_46
		local var_71_832 = var_71_828 - var_71_830 / 2
		local var_71_833 = var_71_829 - var_71_831 / 2

		if not var_0_77 then
			if not (var_71_828 > var_71_0 / 2) then
				var_0_77 = "right"
			else
				var_0_77 = "left"
			end
		end

		local var_71_834
		local var_71_835

		if var_0_77 ~= "left" then
			var_71_834 = var_71_832 + var_71_830 + 10
		else
			var_71_834 = var_71_832 - var_71_824 - 10
		end

		local var_71_836 = var_71_833 + (var_71_831 - var_71_823) / 2

		if var_71_836 < 10 then
			var_71_836 = 10
		end

		if var_0_18 then
			local var_71_837 = var_0_18:getWidth() * 1.15
			local var_71_838 = var_0_18:getHeight() * 1.15
			local var_71_839 = (var_71_0 - var_71_837) / 2

			if var_71_834 < var_71_839 + var_71_837 and var_71_839 < var_71_834 + var_71_824 and var_71_836 < 25 + var_71_838 + 4 then
				var_71_836 = 25 + var_71_838 + 4
			end
		end

		if var_71_836 + var_71_823 > var_71_1 - 10 then
			var_71_836 = var_71_1 - 10 - var_71_823
		end

		if var_71_834 < 10 then
			var_71_834 = 10
		end

		if var_71_834 + var_71_824 > var_71_0 - 10 then
			var_71_834 = var_71_0 - 10 - var_71_824
		end

		if var_71_834 < 10 then
			var_71_834 = 10
		end

		local var_71_840 = math.floor(var_71_834)
		local var_71_841 = math.floor(var_71_836)

		var_0_89(var_71_840, var_71_841, var_71_824, var_71_823, {
			0.05,
			0.05,
			0.05,
			1
		}, var_71_742)

		local var_71_842 = arg_71_0 and arg_71_0.upgrade and arg_71_0.upgrade.tooltip or {}
		local var_71_843 = var_71_842.nameOffsetY or 0
		local var_71_844 = var_71_842.descOffsetY or 0
		local var_71_845 = var_71_842.statOffsetY or 0
		local var_71_846 = var_71_842.costOffsetY or 0
		local var_71_847 = var_71_842.costTextOffsetY or 0
		local var_71_848 = var_71_841 + var_71_747
		local var_71_849 = var_71_840 + var_71_747
		local var_71_850 = var_71_809

		require("src.ui.widgets").text_color.drawRich(var_71_753, var_71_840 + var_71_747, math.floor(var_71_848 + var_71_843), {
			font = var_71_744,
			scale = var_71_750,
			color = {
				1,
				0.8,
				0.2,
				1
			},
			lang = var_71_752,
			measure = function(arg_77_0)
				return var_0_110(arg_77_0, var_71_744, var_71_750)
			end
		})

		local var_71_851 = var_71_848 + var_71_811 + var_71_748 + var_71_812

		love.graphics.setColor(var_0_86.separator)
		love.graphics.rectangle("fill", var_71_849, math.floor(var_71_851), var_71_850, var_71_749)

		local var_71_852 = var_71_851 + var_71_749 + var_71_748

		love.graphics.setColor(0.9, 0.9, 0.9, 1)
		var_71_744:setLineHeight(1.4)

		if not var_71_773 then
			love.graphics.printf(var_71_754, var_71_840 + var_71_747, math.floor(var_71_852 + var_71_844), var_71_772, "left", 0, var_71_750, var_71_750)
		else
			local var_71_853 = var_71_745:getHeight() * var_71_744:getLineHeight() * var_71_750

			for iter_71_47, iter_71_48 in ipairs(var_71_773) do
				var_0_113(iter_71_48, var_71_840 + var_71_747, math.floor(var_71_852 + var_71_844 + (iter_71_47 - 1) * var_71_853), var_71_744, var_71_750, var_71_751, {
					0.9,
					0.9,
					0.9,
					1
				}, {
					1,
					1,
					1,
					1
				}, {
					0.45,
					0.82,
					1,
					1
				}, {
					terms = true,
					lang = var_71_752,
					extra = var_71_738.descNamed and {
						var_71_755
					} or nil
				})
			end
		end

		var_71_744:setLineHeight(1)

		local var_71_854 = var_71_852 + var_71_774 + var_71_748

		love.graphics.setColor(var_0_86.separator)
		love.graphics.rectangle("fill", var_71_849, math.floor(var_71_854), var_71_850, var_71_749)

		local var_71_855 = var_71_854 + var_71_749 + var_71_748

		if not var_71_761 then
			local var_71_856 = var_71_840 + var_71_747 + (var_71_809 - var_71_788) / 2

			if var_71_856 < var_71_840 + var_71_747 then
				var_71_856 = var_71_840 + var_71_747
			end

			local var_71_857, var_71_858 = var_71_763:match("^(.*%->%s*)(.*)$")

			if not var_71_857 or not var_71_858 then
				if var_0_109(var_71_763) then
					local var_71_859 = var_0_108(var_71_763, var_71_744, var_71_750, var_71_751)

					var_0_113(var_71_859, math.floor(var_71_856), math.floor(var_71_855 + var_71_845) - 2, var_71_744, var_71_750, var_71_751, {
						0.2,
						1,
						0.2,
						1
					}, {
						1,
						1,
						1,
						1
					}, nil, {
						lang = var_71_752
					})
				else
					love.graphics.setColor(0.2, 1, 0.2, 1)
					require("src.ui.widgets").text_color.drawRich(var_71_763, math.floor(var_71_856), math.floor(var_71_855 + var_71_845) - 2, {
						font = var_71_744,
						scale = var_71_750,
						color = {
							0.2,
							1,
							0.2,
							1
						},
						lang = var_71_752,
						measure = function(arg_78_0)
							return var_0_110(arg_78_0, var_71_744, var_71_750)
						end
					})
				end
			else
				local var_71_860 = var_0_110(var_71_857, var_71_744, var_71_750)

				if var_0_109(var_71_857) then
					local var_71_861 = var_0_108(var_71_857, var_71_744, var_71_750, var_71_751)

					var_71_860 = var_0_111(var_71_861, var_71_744, var_71_750, var_71_751)

					var_0_113(var_71_861, math.floor(var_71_856), math.floor(var_71_855 + var_71_845) - 2, var_71_744, var_71_750, var_71_751, {
						1,
						1,
						1,
						1
					}, {
						1,
						1,
						1,
						1
					}, nil, {
						lang = var_71_752
					})
				else
					love.graphics.setColor(1, 1, 1, 1)
					require("src.ui.widgets").text_color.drawRich(var_71_857, math.floor(var_71_856), math.floor(var_71_855 + var_71_845) - 2, {
						font = var_71_744,
						scale = var_71_750,
						color = {
							1,
							1,
							1,
							1
						},
						lang = var_71_752,
						measure = function(arg_79_0)
							return var_0_110(arg_79_0, var_71_744, var_71_750)
						end
					})
				end

				if var_0_109(var_71_858) then
					local var_71_862 = var_0_108(var_71_858, var_71_744, var_71_750, var_71_751)

					var_0_113(var_71_862, math.floor(var_71_856 + var_71_860), math.floor(var_71_855 + var_71_845) - 2, var_71_744, var_71_750, var_71_751, {
						0.2,
						1,
						0.2,
						1
					}, {
						1,
						1,
						1,
						1
					}, nil, {
						lang = var_71_752
					})
				else
					love.graphics.setColor(0.2, 1, 0.2, 1)
					require("src.ui.widgets").text_color.drawRich(var_71_858, math.floor(var_71_856 + var_71_860), math.floor(var_71_855 + var_71_845) - 2, {
						font = var_71_744,
						scale = var_71_750,
						color = {
							0.2,
							1,
							0.2,
							1
						},
						lang = var_71_752,
						measure = function(arg_80_0)
							return var_0_110(arg_80_0, var_71_744, var_71_750)
						end
					})
				end
			end

			var_71_855 = var_71_855 + var_71_811 + var_71_748
		else
			var_71_855 = var_71_855 - var_71_817

			love.graphics.setColor(0.2, 1, 0.2, 1)
			love.graphics.print(var_71_756, var_71_840 + var_71_747, math.floor(var_71_855 + var_71_845), 0, var_71_750, var_71_750)

			var_71_855 = var_71_855 + var_71_811 + var_71_818

			love.graphics.setColor(var_0_86.separator)
			love.graphics.rectangle("fill", var_71_849, math.floor(var_71_855), var_71_850, var_71_749)

			var_71_855 = var_71_855 + var_71_749 + var_71_819

			love.graphics.setColor(1, 0.8, 0.2, 1)

			local var_71_863 = var_71_840 + var_71_747 + (var_71_809 - var_71_778) / 2

			love.graphics.print(var_71_757, math.floor(var_71_863), math.floor(var_71_855 + var_71_845), 0, var_71_750, var_71_750)

			if var_71_759 then
				var_71_855 = var_71_855 + math.floor(var_71_811 * 1.4 + 0.5)

				if var_71_760 == "blast" then
					love.graphics.setColor(1, 0.62, 0.36, 1)
				else
					love.graphics.setColor(0.58, 0.86, 1, 1)
				end

				love.graphics.print(var_71_759, math.floor(var_71_840 + var_71_747 + (var_71_809 - var_71_780) / 2), math.floor(var_71_855 + var_71_845), 0, var_71_750, var_71_750)
			end

			var_71_855 = var_71_855 + var_71_811 + var_71_820

			love.graphics.setColor(var_0_86.separator)
			love.graphics.rectangle("fill", var_71_849, math.floor(var_71_855), var_71_850, var_71_749)

			var_71_855 = var_71_855 + var_71_749 + var_71_821

			var_71_744:setLineHeight(1.4)

			local var_71_864 = var_71_745:getHeight() * var_71_744:getLineHeight() * var_71_750

			for iter_71_49, iter_71_50 in ipairs(var_71_775 or {}) do
				local var_71_865 = var_0_111(iter_71_50, var_71_744, var_71_750, var_71_751)
				local var_71_866 = var_71_840 + var_71_747 + (var_71_809 - var_71_865) / 2

				var_0_113(iter_71_50, math.floor(var_71_866), math.floor(var_71_855 + var_71_845 + (iter_71_49 - 1) * var_71_864), var_71_744, var_71_750, var_71_751, {
					0.9,
					0.9,
					0.9,
					1
				}, {
					1,
					1,
					1,
					1
				}, {
					0.45,
					0.82,
					1,
					1
				}, {
					lang = var_71_752
				})
			end

			var_71_744:setLineHeight(1)

			var_71_855 = var_71_855 + var_71_776 + var_71_748
		end

		love.graphics.setColor(var_0_86.separator)
		love.graphics.rectangle("fill", var_71_849, math.floor(var_71_855), var_71_850, var_71_749)

		local var_71_867 = var_71_855 + var_71_749 + var_71_748
		local var_71_868 = var_71_793
		local var_71_869 = var_71_840 + var_71_747 + (var_71_809 - var_71_868) / 2
		local var_71_870 = {
			var_71_743[1] * 0.25,
			var_71_743[2] * 0.25,
			var_71_743[3] * 0.25,
			1
		}
		local var_71_871 = var_71_811 + 4
		local var_71_872 = var_71_867 - 1 + var_71_846
		local var_71_873 = var_71_849
		local var_71_874 = var_71_850

		var_0_89(math.floor(var_71_873), math.floor(var_71_872), math.floor(var_71_874), math.floor(var_71_871), var_71_870, nil)

		local var_71_875 = var_71_745:getHeight() * var_71_750
		local var_71_876 = var_71_872 + math.floor((var_71_871 - var_71_875) / 2) - 1
		local var_71_877 = var_71_872 + math.floor((var_71_871 - var_71_791 * var_71_789) / 2) - 1

		if not var_71_739 then
			love.graphics.setColor(1, 1, 1, 1)

			if var_0_12 then
				love.graphics.draw(var_0_12, math.floor(var_71_869), math.floor(var_71_877), 0, var_71_789, var_71_789)
			end

			love.graphics.setColor(var_71_743)
			love.graphics.print(var_71_766, math.floor(var_71_869 + var_71_790 * var_71_789 + var_71_792), math.floor(var_71_876 + var_71_847), 0, var_71_750, var_71_750)
		else
			love.graphics.setColor(var_71_743)
			love.graphics.print(var_71_766, math.floor(var_71_869), math.floor(var_71_876 + var_71_847), 0, var_71_750, var_71_750)
		end

		if var_71_794 then
			var_71_867 = var_71_867 + var_71_871 + var_71_813

			local var_71_878 = var_71_739 and {
				var_0_84("#6FAACC")
			} or var_71_796 and {
				var_0_84("#5FAF6F")
			} or {
				var_0_84("#A84F5A")
			}
			local var_71_879 = var_0_107(var_71_739, var_71_796)
			local var_71_880 = var_71_840 + var_71_747 + (var_71_809 - var_71_798) / 2
			local var_71_881 = {
				var_71_878[1] * 0.25,
				var_71_878[2] * 0.25,
				var_71_878[3] * 0.25,
				1
			}
			local var_71_882 = var_71_867 - 1
			local var_71_883 = var_71_882 + math.floor((var_71_814 - var_71_800) / 2)
			local var_71_884 = var_71_882 + math.floor((var_71_814 - var_71_875) / 2) - 2

			var_0_89(math.floor(var_71_849), math.floor(var_71_882), math.floor(var_71_850), math.floor(var_71_814), var_71_881, nil)

			if var_71_802 then
				local var_71_885 = var_0_88()
				local var_71_886 = math.floor(var_71_880)
				local var_71_887 = math.floor(var_71_883)
				local var_71_888 = math.floor(var_71_800)

				local function var_71_889(arg_81_0, arg_81_1)
					love.graphics.rectangle("fill", var_71_886 + arg_81_0, var_71_887 + arg_81_1, var_71_888, var_71_885)
					love.graphics.rectangle("fill", var_71_886 + arg_81_0, var_71_887 + arg_81_1 + var_71_888 - var_71_885, var_71_888, var_71_885)
					love.graphics.rectangle("fill", var_71_886 + arg_81_0, var_71_887 + arg_81_1, var_71_885, var_71_888)
					love.graphics.rectangle("fill", var_71_886 + arg_81_0 + var_71_888 - var_71_885, var_71_887 + arg_81_1, var_71_885, var_71_888)

					if var_71_796 then
						local var_81_0 = {
							{
								2,
								5
							},
							{
								3,
								6
							},
							{
								4,
								5
							},
							{
								5,
								4
							},
							{
								6,
								3
							},
							{
								7,
								2
							}
						}

						for iter_81_0, iter_81_1 in ipairs(var_81_0) do
							love.graphics.rectangle("fill", var_71_886 + arg_81_0 + iter_81_1[1] * var_71_885, var_71_887 + arg_81_1 + iter_81_1[2] * var_71_885, var_71_885, var_71_885)
						end
					end
				end

				love.graphics.setColor(0, 0, 0, 0.45)
				var_71_889(0, var_71_885)
				love.graphics.setColor(var_71_878[1], var_71_878[2], var_71_878[3], 1)
				var_71_889(0, 0)
			end

			local var_71_890 = var_71_880

			if var_71_802 then
				var_71_890 = var_71_890 + var_71_800 + var_71_801
			end

			if not var_71_795 then
				love.graphics.setColor(var_71_878[1], var_71_878[2], var_71_878[3], 1)
				love.graphics.print(var_71_794, math.floor(var_71_890), math.floor(var_71_884), 0, var_71_750, var_71_750)
			else
				local var_71_891 = var_0_110(" ", var_71_744, var_71_750)

				for iter_71_51, iter_71_52 in ipairs(var_71_795) do
					local var_71_892 = var_71_879[iter_71_52.kind] or var_71_878

					love.graphics.setColor(var_71_892[1], var_71_892[2], var_71_892[3], 1)
					love.graphics.print(iter_71_52.text, math.floor(var_71_890), math.floor(var_71_884), 0, var_71_750, var_71_750)

					var_71_890 = var_71_890 + var_0_110(iter_71_52.text, var_71_744, var_71_750)

					if iter_71_51 < #var_71_795 then
						var_71_890 = var_71_890 + var_71_891
					end
				end
			end
		end

		if var_71_805 then
			local var_71_893 = var_71_867 + (var_71_794 and var_71_814 or var_71_871) + var_71_813

			var_0_0.drawRequirementRow({
				label = var_71_805.label,
				count = var_71_805.count,
				met = var_71_805.met,
				maxed = var_71_739,
				barX = var_71_849,
				barW = var_71_850,
				y = var_71_893 - 1,
				h = var_71_814,
				x = var_71_840 + var_71_747 + (var_71_809 - var_71_805.w) / 2,
				box = var_71_800,
				gap = var_71_801,
				textH = var_71_875,
				scale = var_71_750,
				font = var_71_744
			})
		end

		var_71_744:setLineHeight(var_71_746)
	end
end

function var_0_0.update(arg_82_0, arg_82_1, arg_82_2)
	var_0_76()

	local var_82_0 = ui and ui.menuSettings and ui.menuSettings.sfxVolume or 1

	if var_0_26 and var_0_26.setVolume then
		var_0_26:setVolume(var_82_0 * 1.6)
	end

	if var_0_27 and var_0_27.setVolume then
		var_0_27:setVolume(var_82_0 * 1.6)
	end

	if var_0_51 and not var_0_54 then
		local var_82_1 = 1 - math.exp(-math.max(0, arg_82_0) * 11)

		var_0_46 = var_0_46 + (var_0_48 - var_0_46) * var_82_1
		var_0_44 = var_0_44 + (var_0_49 - var_0_44) * var_82_1
		var_0_45 = var_0_45 + (var_0_50 - var_0_45) * var_82_1

		if math.abs(var_0_48 - var_0_46) < 0.001 and math.abs(var_0_49 - var_0_44) < 0.05 and math.abs(var_0_50 - var_0_45) < 0.05 then
			var_0_46 = var_0_48
			var_0_44, var_0_45 = var_0_49, var_0_50
			var_0_51 = false
		end
	end

	local var_82_2 = 0
	local var_82_3 = 0

	if love.keyboard and love.keyboard.isDown then
		if love.keyboard.isDown("a", "left") then
			var_82_2 = var_82_2 + 1
		end

		if love.keyboard.isDown("d", "right") then
			var_82_2 = var_82_2 - 1
		end

		if love.keyboard.isDown("w", "up") then
			var_82_3 = var_82_3 + 1
		end

		if love.keyboard.isDown("s", "down") then
			var_82_3 = var_82_3 - 1
		end
	end

	local var_82_4 = var_82_2 + (var_0_0._padPanX or 0)
	local var_82_5 = var_82_3 + (var_0_0._padPanY or 0)
	local var_82_6 = var_82_4 ~= 0 or var_82_5 ~= 0
	local var_82_7 = 0
	local var_82_8 = 0

	if var_82_6 then
		local var_82_9 = math.sqrt(var_82_4 * var_82_4 + var_82_5 * var_82_5)
		local var_82_10 = 250 * math.min(1, var_82_9)

		var_82_7 = var_82_4 / var_82_9 * var_82_10
		var_82_8 = var_82_5 / var_82_9 * var_82_10
	end

	local var_82_11 = math.min(math.max(arg_82_0, 0), 0.05)
	local var_82_12 = var_82_6 and 11 or 7.5
	local var_82_13 = 1 - math.exp(-var_82_12 * var_82_11)

	var_0_55 = var_0_55 + (var_82_7 - var_0_55) * var_82_13
	var_0_56 = var_0_56 + (var_82_8 - var_0_56) * var_82_13

	if not var_82_6 then
		if math.abs(var_0_55) < 0.5 then
			var_0_55 = 0
		end

		if math.abs(var_0_56) < 0.5 then
			var_0_56 = 0
		end
	end

	if var_0_55 ~= 0 or var_0_56 ~= 0 then
		local var_82_14 = var_0_44
		local var_82_15 = var_0_45
		local var_82_16 = var_82_14 + var_0_55 * var_82_11
		local var_82_17 = var_82_15 + var_0_56 * var_82_11

		var_0_44, var_0_45 = var_0_66(var_82_16, var_82_17, var_0_46, var_82_14, var_82_15)

		local var_82_18 = var_0_44 - var_82_14
		local var_82_19 = var_0_45 - var_82_15

		if math.abs(var_0_44 - var_82_16) > 0.001 then
			var_0_55 = 0
		end

		if math.abs(var_0_45 - var_82_17) > 0.001 then
			var_0_56 = 0
		end

		if not var_0_51 then
			var_0_49, var_0_50 = var_0_44, var_0_45
		else
			var_0_49, var_0_50 = var_0_66(var_0_49 + var_82_18, var_0_50 + var_82_19, var_0_48)
		end
	end

	var_0_82 = var_0_82 + arg_82_0

	if var_0_82 > var_0_83 then
		var_0_82 = 0
		var_0_83 = love.math.random(2, 6)

		local var_82_20 = love.math.random(-200, 1480)
		local var_82_21 = love.math.random(-200, 500)

		table.insert(var_0_81, {
			life = 1,
			x = var_82_20,
			y = var_82_21,
			len = love.math.random(50, 150),
			speed = love.math.random(600, 1000),
			angle = math.pi / 4,
			thickness = love.math.random(1, 2)
		})
	end

	for iter_82_0 = #var_0_81, 1, -1 do
		local var_82_22 = var_0_81[iter_82_0]

		var_82_22.x = var_82_22.x + math.cos(var_82_22.angle) * var_82_22.speed * arg_82_0
		var_82_22.y = var_82_22.y + math.sin(var_82_22.angle) * var_82_22.speed * arg_82_0
		var_82_22.life = var_82_22.life - arg_82_0 * 1.5

		if var_82_22.life <= 0 then
			table.remove(var_0_81, iter_82_0)
		end
	end

	if var_0_32 then
		var_0_33 = var_0_33 - arg_82_0

		if var_0_33 <= 0 then
			local var_82_23 = var_0_32

			var_0_32 = nil

			return var_82_23
		end
	end

	if var_0_25 and var_0_25.rect then
		local var_82_24 = arg_82_1 or -9999
		local var_82_25 = arg_82_2 or -9999
		local var_82_26 = var_0_25.rect
		local var_82_27 = var_82_24 >= var_82_26.x and var_82_24 <= var_82_26.x + var_82_26.w and var_82_25 >= var_82_26.y and var_82_25 <= var_82_26.y + var_82_26.h

		if var_82_27 and not var_0_25._hovered and var_0_26 then
			if var_0_26:isPlaying() then
				var_0_26:stop()
			end

			var_0_26:play()
		end

		var_0_25._hovered = var_82_27

		local var_82_28 = 0.9
		local var_82_29 = var_82_28

		if var_0_25.pressed then
			local var_82_30 = var_82_28 * 0.9

			var_0_25.scale = var_0_25.scale + (var_82_30 - var_0_25.scale) * math.min(1, arg_82_0 * 20)
		elseif var_82_27 then
			local var_82_31 = var_82_28 * 1.15

			var_0_25.scale = var_0_25.scale + (var_82_31 - var_0_25.scale) * math.min(1, arg_82_0 * 12)
		else
			local var_82_32 = var_82_28

			var_0_25.scale = var_0_25.scale + (var_82_32 - var_0_25.scale) * math.min(1, arg_82_0 * 10)
		end
	end

	var_0_74 = nil

	local var_82_33 = false
	local var_82_34 = false

	if ui and ui._coreSelect and ui._coreSelect.active then
		var_82_34 = true
	end

	if var_0_0.sandboxUnlockHover(arg_82_1, arg_82_2) then
		var_82_34 = true
	end

	if arg_82_1 and arg_82_2 and not var_82_34 then
		local var_82_35 = var_0_52 / 2 + (arg_82_1 - var_0_52 / 2 - var_0_44) / var_0_46
		local var_82_36 = var_0_53 / 2 + (arg_82_2 - var_0_53 / 2 - var_0_45) / var_0_46

		for iter_82_1, iter_82_2 in pairs(var_0_62) do
			if var_82_35 >= iter_82_2.x and var_82_35 <= iter_82_2.x + iter_82_2.w and var_82_36 >= iter_82_2.y and var_82_36 <= iter_82_2.y + iter_82_2.h then
				var_0_74 = iter_82_1

				local var_82_37 = true

				break
			end
		end
	end

	for iter_82_3, iter_82_4 in pairs(var_0_71) do
		iter_82_4.shakeX = 0

		if iter_82_4.shakeT > 0 then
			iter_82_4.shakeT = iter_82_4.shakeT - arg_82_0

			if iter_82_4.shakeT < 0 then
				iter_82_4.shakeT = 0
			end

			local var_82_38 = 1 - iter_82_4.shakeT / iter_82_4.shakeDur
			local var_82_39 = 1 - var_82_38

			iter_82_4.shakeX = math.sin(var_82_38 * math.pi * 8) * iter_82_4.shakeAmp * var_82_39
		end

		iter_82_4.pulseT = (iter_82_4.pulseT or 0) + arg_82_0 * 4
		iter_82_4.shineT = (iter_82_4.shineT or 0) + arg_82_0

		if iter_82_4.shineT > 3 then
			iter_82_4.shineT = love.math.random() * -1
		end

		if iter_82_4.flashT > 0 then
			iter_82_4.flashT = iter_82_4.flashT - arg_82_0

			if iter_82_4.flashT < 0 then
				iter_82_4.flashT = 0
			end
		end

		local var_82_40 = false

		if iter_82_4.isDisappearing then
			iter_82_4.disappearTimer = iter_82_4.disappearTimer + arg_82_0

			local var_82_41 = iter_82_4.disappearTimer

			if var_82_41 < 0.1 then
				local var_82_42 = var_82_41 / 0.1

				iter_82_4.scaleX = 1 - var_82_42 * 0.1
				iter_82_4.scaleY = 1 - var_82_42 * 0.1
				iter_82_4.unlockLineProgress = math.max(0, 1 - var_82_41 / 0.4)
				var_82_40 = true
			elseif var_82_41 < 0.2 then
				local var_82_43 = (var_82_41 - 0.1) / 0.1

				iter_82_4.scaleX = 0.9 + var_82_43 * 0.4
				iter_82_4.scaleY = 0.9 + var_82_43 * 0.4
				iter_82_4.unlockLineProgress = math.max(0, 1 - var_82_41 / 0.4)
				var_82_40 = true
			elseif var_82_41 < 0.4 then
				local var_82_44 = (var_82_41 - 0.2) / 0.2

				iter_82_4.scaleX = 1.3 * (1 - var_82_44)
				iter_82_4.scaleY = 1.3 * (1 - var_82_44)
				iter_82_4.unlockLineProgress = math.max(0, 1 - var_82_41 / 0.4)
				var_82_40 = true
			else
				iter_82_4.isDisappearing = false
				iter_82_4.revealed = false
				iter_82_4.unlockLineProgress = 0
				iter_82_4.scaleX = 0
				iter_82_4.scaleY = 0
				var_82_40 = true
			end
		end

		if not var_82_40 then
			if iter_82_3 == "maxunit" or iter_82_3 == "maxunit2" or iter_82_3 == "maxunit3" or iter_82_3 == "maxhp" or iter_82_3 == "maxhp2" or iter_82_3 == "noviceshield" or iter_82_3 == "startgold" or iter_82_3 == "startingmerccontract" or iter_82_3 == "startgold2" or iter_82_3 == "comebackspin" or iter_82_3 == "gateheal" or iter_82_3 == "comebackgold" or iter_82_3 == "slotnudge" or iter_82_3 == "slotadvanced" or iter_82_3 == "slotadvanced2" or iter_82_3 == "slotadvanced3" or iter_82_3 == "slotrare" or iter_82_3 == "corereroll" or iter_82_3 == "firstcorespin" or iter_82_3 == "firstcoreuncommon" or iter_82_3 == "shopreroll" or iter_82_3 == "iteminventory" or iter_82_3 == "itemrefund" or iter_82_3 == "iteminventory2" or iter_82_3 == "itemresearch" or iter_82_3 == "shoppin" or iter_82_3 == "interest" or iter_82_3 == "dormantpower" or iter_82_3 == "growthbranch" or iter_82_3 == "factionsynergy" or var_0_91[iter_82_3] ~= nil and var_0_91[iter_82_3].parent ~= nil then
				local var_82_45 = var_0_91.slotodds.maxed

				if iter_82_3 == "maxunit2" then
					var_82_45 = var_0_91.maxunit and var_0_91.maxunit.maxed == true
				elseif iter_82_3 == "maxunit3" then
					var_82_45 = var_0_91.maxunit2 and var_0_91.maxunit2.maxed == true
				elseif iter_82_3 == "noviceshield" then
					var_82_45 = var_0_91.maxhp and var_0_91.maxhp.maxed == true
				elseif iter_82_3 == "startgold" then
					var_82_45 = var_0_91.maxhp and var_0_91.maxhp.maxed == true
				elseif iter_82_3 == "startingmerccontract" then
					var_82_45 = var_0_91.startgold and var_0_91.startgold.maxed == true
				elseif iter_82_3 == "comebackspin" then
					var_82_45 = var_0_91.noviceshield and var_0_91.noviceshield.maxed == true
				elseif iter_82_3 == "gateheal" then
					var_82_45 = var_0_91.comebackspin and var_0_91.comebackspin.maxed == true
				elseif iter_82_3 == "comebackgold" then
					var_82_45 = var_0_91.startgold and var_0_91.startgold.maxed == true
				elseif iter_82_3 == "maxhp2" then
					var_82_45 = var_0_91.comebackgold and var_0_91.comebackgold.maxed == true
				elseif iter_82_3 == "startgold2" then
					var_82_45 = var_0_91.startgold and var_0_91.startgold.maxed == true
				elseif iter_82_3 == "slotadvanced2" then
					var_82_45 = var_0_91.slotadvanced and var_0_91.slotadvanced.maxed == true
				elseif iter_82_3 == "corereroll" then
					var_82_45 = var_0_91.slotadvanced and var_0_91.slotadvanced.maxed == true
				elseif iter_82_3 == "firstcorespin" then
					var_82_45 = var_0_91.corereroll and var_0_91.corereroll.maxed == true
				elseif iter_82_3 == "firstcoreuncommon" then
					var_82_45 = var_0_91.firstcorespin and var_0_91.firstcorespin.maxed == true
				elseif iter_82_3 == "shopreroll" then
					var_82_45 = var_0_91.slotadvanced and var_0_91.slotadvanced.maxed == true
				elseif iter_82_3 == "iteminventory" then
					var_82_45 = var_0_91.shopreroll and var_0_91.shopreroll.maxed == true
				elseif iter_82_3 == "iteminventory2" then
					var_82_45 = var_0_91.iteminventory and var_0_91.iteminventory.maxed == true
				elseif iter_82_3 == "itemresearch" then
					var_82_45 = var_0_91.shopreroll and var_0_91.shopreroll.maxed == true
				elseif iter_82_3 == "shoppin" then
					var_82_45 = var_0_91.shopreroll and var_0_91.shopreroll.maxed == true
				elseif iter_82_3 == "slotadvanced3" then
					var_82_45 = var_0_91.slotadvanced2 and var_0_91.slotadvanced2.maxed == true
				elseif iter_82_3 == "slotrare" then
					var_82_45 = var_0_91.slotadvanced3 and var_0_91.slotadvanced3.maxed == true
				elseif var_0_91[iter_82_3] and var_0_91[iter_82_3].parent then
					local var_82_46 = var_0_91[var_0_91[iter_82_3].parent]

					var_82_45 = var_0_91.slotodds.maxed == true and var_82_46 ~= nil and var_82_46.maxed == true
				end

				if var_82_45 then
					if iter_82_3 == "maxhp" then
						local var_82_47 = var_0_72("maxunit")

						if var_82_47 and var_82_47.unlockLineProgress then
							iter_82_4.unlockLineProgress = var_82_47.unlockLineProgress
						end
					end

					if iter_82_4.unlockLineProgress < 1 then
						iter_82_4.unlockLineProgress = iter_82_4.unlockLineProgress + arg_82_0 * 4

						if iter_82_4.unlockLineProgress >= 1 then
							iter_82_4.unlockLineProgress = 1

							if not iter_82_4.revealed then
								iter_82_4.revealed = true
								iter_82_4.isAppearing = true
								iter_82_4.appearTimer = 0
								iter_82_4.scaleX = 0
								iter_82_4.scaleY = 0
							end
						end
					elseif not iter_82_4.revealed then
						iter_82_4.unlockLineProgress = 1
						iter_82_4.revealed = true
					end
				end

				if iter_82_4.isAppearing then
					iter_82_4.appearTimer = iter_82_4.appearTimer + arg_82_0

					local var_82_48 = iter_82_4.appearTimer

					if var_82_48 < 0.2 then
						local var_82_49 = var_82_48 / 0.2

						targetX = var_82_49 * 1.3
						targetY = var_82_49 * 1.3
						iter_82_4.scaleX = targetX
						iter_82_4.scaleY = targetY
						var_82_40 = true
					elseif var_82_48 < 0.3 then
						local var_82_50 = (var_82_48 - 0.2) / 0.1

						targetX = 1.3 - var_82_50 * 0.4
						targetY = 1.3 - var_82_50 * 0.4
						iter_82_4.scaleX = targetX
						iter_82_4.scaleY = targetY
						var_82_40 = true
					elseif var_82_48 < 0.4 then
						local var_82_51 = (var_82_48 - 0.3) / 0.1

						targetX = 0.9 + var_82_51 * 0.1
						targetY = 0.9 + var_82_51 * 0.1
						iter_82_4.scaleX = targetX
						iter_82_4.scaleY = targetY
						var_82_40 = true
					else
						iter_82_4.isAppearing = false
						iter_82_4.scaleX = 1
						iter_82_4.scaleY = 1
					end
				end
			end

			if not var_82_40 then
				local var_82_52 = 1
				local var_82_53 = var_82_52
				local var_82_54 = var_82_52

				if iter_82_4.isPopping then
					iter_82_4.popTimer = iter_82_4.popTimer + arg_82_0

					if iter_82_4.popTimer < 0.08 then
						local var_82_55 = 1.15
						local var_82_56 = 0.85

						iter_82_4.scaleX = iter_82_4.scaleX + (var_82_55 - iter_82_4.scaleX) * math.min(1, arg_82_0 * 30)
						iter_82_4.scaleY = iter_82_4.scaleY + (var_82_56 - iter_82_4.scaleY) * math.min(1, arg_82_0 * 30)
					elseif iter_82_4.popTimer < 0.22 then
						local var_82_57 = 0.9
						local var_82_58 = 1.1

						iter_82_4.scaleX = iter_82_4.scaleX + (var_82_57 - iter_82_4.scaleX) * math.min(1, arg_82_0 * 18)
						iter_82_4.scaleY = iter_82_4.scaleY + (var_82_58 - iter_82_4.scaleY) * math.min(1, arg_82_0 * 18)
					elseif iter_82_4.popTimer < 0.35 then
						local var_82_59 = 1.05
						local var_82_60 = 0.95

						iter_82_4.scaleX = iter_82_4.scaleX + (var_82_59 - iter_82_4.scaleX) * math.min(1, arg_82_0 * 15)
						iter_82_4.scaleY = iter_82_4.scaleY + (var_82_60 - iter_82_4.scaleY) * math.min(1, arg_82_0 * 15)
					elseif iter_82_4.popTimer < 0.48 then
						local var_82_61 = 0.98
						local var_82_62 = 1.02

						iter_82_4.scaleX = iter_82_4.scaleX + (var_82_61 - iter_82_4.scaleX) * math.min(1, arg_82_0 * 12)
						iter_82_4.scaleY = iter_82_4.scaleY + (var_82_62 - iter_82_4.scaleY) * math.min(1, arg_82_0 * 12)
					else
						local var_82_63 = 1
						local var_82_64 = 1

						iter_82_4.scaleX = iter_82_4.scaleX + (var_82_63 - iter_82_4.scaleX) * math.min(1, arg_82_0 * 8)
						iter_82_4.scaleY = iter_82_4.scaleY + (var_82_64 - iter_82_4.scaleY) * math.min(1, arg_82_0 * 8)

						if math.abs(iter_82_4.scaleY - 1) < 0.005 and iter_82_4.popTimer > 0.6 then
							iter_82_4.isPopping = false
						end
					end
				elseif iter_82_4.pressed then
					local var_82_65 = var_82_52 * 0.9
					local var_82_66 = var_82_52 * 0.9

					iter_82_4.scaleX = iter_82_4.scaleX + (var_82_65 - iter_82_4.scaleX) * math.min(1, arg_82_0 * 20)
					iter_82_4.scaleY = iter_82_4.scaleY + (var_82_66 - iter_82_4.scaleY) * math.min(1, arg_82_0 * 20)
					iter_82_4.pressTimer = (iter_82_4.pressTimer or 0) + arg_82_0

					if iter_82_4.pressTimer > 0.1 then
						iter_82_4.pressed = false
						iter_82_4.pressTimer = 0
					end
				elseif var_0_74 == iter_82_3 and iter_82_4.revealed ~= false then
					local var_82_67 = var_82_52 * 1.15
					local var_82_68 = var_82_52 * 1.15

					iter_82_4.scaleX = iter_82_4.scaleX + (var_82_67 - iter_82_4.scaleX) * math.min(1, arg_82_0 * 12)
					iter_82_4.scaleY = iter_82_4.scaleY + (var_82_68 - iter_82_4.scaleY) * math.min(1, arg_82_0 * 12)
				else
					local var_82_69 = var_82_52
					local var_82_70 = var_82_52

					iter_82_4.scaleX = iter_82_4.scaleX + (var_82_69 - iter_82_4.scaleX) * math.min(1, arg_82_0 * 10)
					iter_82_4.scaleY = iter_82_4.scaleY + (var_82_70 - iter_82_4.scaleY) * math.min(1, arg_82_0 * 10)
				end
			end
		end
	end
end

function var_0_0.mousepressed(arg_83_0, arg_83_1, arg_83_2)
	var_0_76()

	if var_0_0.sandboxUnlockHover(arg_83_0, arg_83_1) then
		if arg_83_2 == 1 and var_0_0.toggleSandboxUnlockAll() then
			if var_0_27 then
				if var_0_27:isPlaying() then
					var_0_27:stop()
				end

				var_0_27:play()
			end

			return {
				action = "sandbox_unlock_all"
			}
		end

		return nil
	end

	if var_0_69 and arg_83_2 == 2 and var_0_74 and var_0_91[var_0_74] and var_0_91[var_0_74].maxed then
		local var_83_0 = var_0_74
		local var_83_1 = var_0_91.maxhp and var_0_91.maxhp.maxed and true or false

		var_0_0._sandboxUnlockRestore = nil
		var_0_91[var_83_0].maxed = false

		if var_83_0 == "slotodds" then
			if var_0_91.maxunit then
				var_0_91.maxunit.maxed = false
			end

			if var_0_91.maxunit2 then
				var_0_91.maxunit2.maxed = false
			end

			if var_0_91.maxunit3 then
				var_0_91.maxunit3.maxed = false
			end

			if var_0_91.maxhp then
				var_0_91.maxhp.maxed = false
			end

			if var_0_91.maxhp2 then
				var_0_91.maxhp2.maxed = false
			end

			if var_0_91.noviceshield then
				var_0_91.noviceshield.maxed = false
			end

			if var_0_91.comebackspin then
				var_0_91.comebackspin.maxed = false
			end

			if var_0_91.gateheal then
				var_0_91.gateheal.maxed = false
			end

			if var_0_91.startgold then
				var_0_91.startgold.maxed = false
			end

			if var_0_91.startingmerccontract then
				var_0_91.startingmerccontract.maxed = false
			end

			if var_0_91.startgold2 then
				var_0_91.startgold2.maxed = false
			end

			if var_0_91.comebackgold then
				var_0_91.comebackgold.maxed = false
			end

			if var_0_91.slotnudge then
				var_0_91.slotnudge.maxed = false
			end

			if var_0_91.preptime then
				var_0_91.preptime.maxed = false
			end

			if var_0_91.interest then
				var_0_91.interest.maxed = false
			end

			if var_0_91.dormantpower then
				var_0_91.dormantpower.maxed = false
			end

			if var_0_91.growthbranch then
				var_0_91.growthbranch.maxed = false
			end

			if var_0_91.factionsynergy then
				var_0_91.factionsynergy.maxed = false
			end

			if var_0_91.preptime2 then
				var_0_91.preptime2.maxed = false
			end

			if var_0_91.preptimerdisabled then
				var_0_91.preptimerdisabled.maxed = false
			end

			if var_0_91.slotadvanced then
				var_0_91.slotadvanced.maxed = false
			end

			if var_0_91.slotadvanced2 then
				var_0_91.slotadvanced2.maxed = false
			end

			if var_0_91.slotadvanced3 then
				var_0_91.slotadvanced3.maxed = false
			end

			if var_0_91.slotrare then
				var_0_91.slotrare.maxed = false
			end

			if var_0_91.corereroll then
				var_0_91.corereroll.maxed = false
			end

			if var_0_91.firstcorespin then
				var_0_91.firstcorespin.maxed = false
			end

			if var_0_91.firstcoreuncommon then
				var_0_91.firstcoreuncommon.maxed = false
			end

			if var_0_91.shopreroll then
				var_0_91.shopreroll.maxed = false
			end

			if var_0_91.iteminventory then
				var_0_91.iteminventory.maxed = false
			end

			if var_0_91.itemrefund then
				var_0_91.itemrefund.maxed = false
			end

			if var_0_91.iteminventory2 then
				var_0_91.iteminventory2.maxed = false
			end

			if var_0_91.itemresearch then
				var_0_91.itemresearch.maxed = false
			end

			if var_0_91.shoppin then
				var_0_91.shoppin.maxed = false
			end

			var_0_73(var_0_72("maxunit"))
			var_0_73(var_0_72("maxunit2"))
			var_0_73(var_0_72("maxunit3"))
			var_0_73(var_0_72("maxhp"))
			var_0_73(var_0_72("maxhp2"))
			var_0_73(var_0_72("noviceshield"))
			var_0_73(var_0_72("comebackspin"))
			var_0_73(var_0_72("gateheal"))
			var_0_73(var_0_72("startgold"))
			var_0_73(var_0_72("startingmerccontract"))
			var_0_73(var_0_72("startgold2"))
			var_0_73(var_0_72("comebackgold"))
			var_0_73(var_0_72("slotnudge"))
			var_0_73(var_0_72("preptime"))
			var_0_73(var_0_72("interest"))
			var_0_73(var_0_72("dormantpower"))
			var_0_73(var_0_72("growthbranch"))
			var_0_73(var_0_72("factionsynergy"))
			var_0_73(var_0_72("preptime2"))
			var_0_73(var_0_72("preptimerdisabled"))
			var_0_73(var_0_72("slotadvanced"))
			var_0_73(var_0_72("slotadvanced2"))
			var_0_73(var_0_72("slotadvanced3"))
			var_0_73(var_0_72("slotrare"))
			var_0_73(var_0_72("corereroll"))
			var_0_73(var_0_72("firstcorespin"))
			var_0_73(var_0_72("firstcoreuncommon"))
			var_0_73(var_0_72("shopreroll"))
			var_0_73(var_0_72("iteminventory"))
			var_0_73(var_0_72("itemrefund"))
			var_0_73(var_0_72("iteminventory2"))
			var_0_73(var_0_72("itemresearch"))
			var_0_73(var_0_72("shoppin"))
		elseif var_83_0 == "slotadvanced" then
			if var_0_91.slotadvanced2 then
				var_0_91.slotadvanced2.maxed = false
			end

			if var_0_91.slotadvanced3 then
				var_0_91.slotadvanced3.maxed = false
			end

			if var_0_91.slotrare then
				var_0_91.slotrare.maxed = false
			end

			if var_0_91.corereroll then
				var_0_91.corereroll.maxed = false
			end

			if var_0_91.firstcorespin then
				var_0_91.firstcorespin.maxed = false
			end

			if var_0_91.firstcoreuncommon then
				var_0_91.firstcoreuncommon.maxed = false
			end

			if var_0_91.shopreroll then
				var_0_91.shopreroll.maxed = false
			end

			if var_0_91.iteminventory then
				var_0_91.iteminventory.maxed = false
			end

			if var_0_91.itemrefund then
				var_0_91.itemrefund.maxed = false
			end

			if var_0_91.iteminventory2 then
				var_0_91.iteminventory2.maxed = false
			end

			if var_0_91.itemresearch then
				var_0_91.itemresearch.maxed = false
			end

			if var_0_91.shoppin then
				var_0_91.shoppin.maxed = false
			end

			var_0_73(var_0_72("slotadvanced2"))
			var_0_73(var_0_72("slotadvanced3"))
			var_0_73(var_0_72("slotrare"))
			var_0_73(var_0_72("corereroll"))
			var_0_73(var_0_72("firstcorespin"))
			var_0_73(var_0_72("firstcoreuncommon"))
			var_0_73(var_0_72("shopreroll"))
			var_0_73(var_0_72("iteminventory"))
			var_0_73(var_0_72("itemrefund"))
			var_0_73(var_0_72("iteminventory2"))
			var_0_73(var_0_72("itemresearch"))
			var_0_73(var_0_72("shoppin"))
		elseif var_83_0 == "corereroll" then
			if var_0_91.firstcorespin then
				var_0_91.firstcorespin.maxed = false
			end

			if var_0_91.firstcoreuncommon then
				var_0_91.firstcoreuncommon.maxed = false
			end

			var_0_73(var_0_72("firstcorespin"))
			var_0_73(var_0_72("firstcoreuncommon"))
		elseif var_83_0 == "firstcorespin" then
			if var_0_91.firstcoreuncommon then
				var_0_91.firstcoreuncommon.maxed = false
			end

			var_0_73(var_0_72("firstcoreuncommon"))
		elseif var_83_0 == "shopreroll" then
			if var_0_91.iteminventory then
				var_0_91.iteminventory.maxed = false
			end

			if var_0_91.itemrefund then
				var_0_91.itemrefund.maxed = false
			end

			if var_0_91.iteminventory2 then
				var_0_91.iteminventory2.maxed = false
			end

			if var_0_91.itemresearch then
				var_0_91.itemresearch.maxed = false
			end

			if var_0_91.shoppin then
				var_0_91.shoppin.maxed = false
			end

			var_0_73(var_0_72("iteminventory"))
			var_0_73(var_0_72("itemrefund"))
			var_0_73(var_0_72("iteminventory2"))
			var_0_73(var_0_72("itemresearch"))
			var_0_73(var_0_72("shoppin"))
		elseif var_83_0 == "iteminventory" then
			if var_0_91.iteminventory2 then
				var_0_91.iteminventory2.maxed = false
			end

			var_0_73(var_0_72("iteminventory2"))
		elseif var_83_0 == "slotadvanced2" then
			if var_0_91.slotadvanced3 then
				var_0_91.slotadvanced3.maxed = false
			end

			if var_0_91.slotrare then
				var_0_91.slotrare.maxed = false
			end

			var_0_73(var_0_72("slotadvanced3"))
			var_0_73(var_0_72("slotrare"))
		elseif var_83_0 == "slotadvanced3" then
			if var_0_91.slotrare then
				var_0_91.slotrare.maxed = false
			end

			var_0_73(var_0_72("slotrare"))
		elseif var_83_0 == "maxhp" then
			if var_0_91.noviceshield then
				var_0_91.noviceshield.maxed = false
			end

			if var_0_91.comebackspin then
				var_0_91.comebackspin.maxed = false
			end

			if var_0_91.gateheal then
				var_0_91.gateheal.maxed = false
			end

			if var_0_91.startgold then
				var_0_91.startgold.maxed = false
			end

			if var_0_91.startingmerccontract then
				var_0_91.startingmerccontract.maxed = false
			end

			if var_0_91.startgold2 then
				var_0_91.startgold2.maxed = false
			end

			if var_0_91.comebackgold then
				var_0_91.comebackgold.maxed = false
			end

			if var_0_91.maxhp2 then
				var_0_91.maxhp2.maxed = false
			end

			var_0_73(var_0_72("noviceshield"))
			var_0_73(var_0_72("comebackspin"))
			var_0_73(var_0_72("gateheal"))
			var_0_73(var_0_72("startgold"))
			var_0_73(var_0_72("startingmerccontract"))
			var_0_73(var_0_72("startgold2"))
			var_0_73(var_0_72("comebackgold"))
			var_0_73(var_0_72("maxhp2"))
		elseif var_83_0 == "noviceshield" then
			if var_0_91.comebackspin then
				var_0_91.comebackspin.maxed = false
			end

			if var_0_91.gateheal then
				var_0_91.gateheal.maxed = false
			end

			var_0_73(var_0_72("comebackspin"))
			var_0_73(var_0_72("gateheal"))
		elseif var_83_0 == "comebackspin" then
			if var_0_91.gateheal then
				var_0_91.gateheal.maxed = false
			end

			var_0_73(var_0_72("gateheal"))
		elseif var_83_0 == "startgold" then
			if var_0_91.startingmerccontract then
				var_0_91.startingmerccontract.maxed = false
			end

			if var_0_91.comebackgold then
				var_0_91.comebackgold.maxed = false
			end

			if var_0_91.startgold2 then
				var_0_91.startgold2.maxed = false
			end

			if var_0_91.maxhp2 then
				var_0_91.maxhp2.maxed = false
			end

			var_0_73(var_0_72("startingmerccontract"))
			var_0_73(var_0_72("comebackgold"))
			var_0_73(var_0_72("startgold2"))
			var_0_73(var_0_72("maxhp2"))
		elseif var_83_0 == "comebackgold" then
			if var_0_91.maxhp2 then
				var_0_91.maxhp2.maxed = false
			end

			var_0_73(var_0_72("maxhp2"))
		elseif var_83_0 == "maxunit" then
			if var_0_91.maxunit2 then
				var_0_91.maxunit2.maxed = false
			end

			if var_0_91.maxunit3 then
				var_0_91.maxunit3.maxed = false
			end

			if var_0_91.preptime then
				var_0_91.preptime.maxed = false
			end

			if var_0_91.preptime2 then
				var_0_91.preptime2.maxed = false
			end

			if var_0_91.preptimerdisabled then
				var_0_91.preptimerdisabled.maxed = false
			end

			var_0_73(var_0_72("maxunit2"))
			var_0_73(var_0_72("maxunit3"))
			var_0_73(var_0_72("preptime"))
			var_0_73(var_0_72("preptime2"))
			var_0_73(var_0_72("preptimerdisabled"))
		elseif var_83_0 == "maxunit2" then
			if var_0_91.maxunit3 then
				var_0_91.maxunit3.maxed = false
			end

			var_0_73(var_0_72("maxunit3"))
		elseif var_83_0 == "preptime" then
			if var_0_91.interest then
				var_0_91.interest.maxed = false
			end

			if var_0_91.preptime2 then
				var_0_91.preptime2.maxed = false
			end

			if var_0_91.preptimerdisabled then
				var_0_91.preptimerdisabled.maxed = false
			end

			var_0_73(var_0_72("interest"))
			var_0_73(var_0_72("preptime2"))
			var_0_73(var_0_72("preptimerdisabled"))
		elseif var_83_0 == "preptime2" then
			if var_0_91.preptimerdisabled then
				var_0_91.preptimerdisabled.maxed = false
			end

			var_0_73(var_0_72("preptimerdisabled"))
		end

		local var_83_2 = true

		while var_83_2 do
			var_83_2 = false

			for iter_83_0, iter_83_1 in pairs(var_0_91) do
				local var_83_3 = iter_83_1.parent and var_0_91[iter_83_1.parent]

				if var_83_3 and iter_83_1.maxed and not var_83_3.maxed then
					iter_83_1.maxed = false
					var_83_2 = true
				end
			end
		end

		for iter_83_2, iter_83_3 in pairs(var_0_91) do
			local var_83_4 = iter_83_3.parent and var_0_91[iter_83_3.parent]

			if var_83_4 and not var_83_4.maxed then
				local var_83_5 = var_0_72(iter_83_2)

				if (var_83_5.revealed or (var_83_5.unlockLineProgress or 0) > 0) and not var_83_5.isDisappearing then
					var_0_73(var_83_5)
				end
			end
		end

		var_0_0.applyUpgradeEffects()

		if var_83_0 == "maxhp" or var_83_0 == "slotodds" and var_83_1 then
			return {
				action = "downgrade_maxhp"
			}
		end

		return
	end

	if arg_83_2 == 1 then
		if var_0_25 and var_0_25.rect then
			local var_83_6 = var_0_25.rect

			if arg_83_0 >= var_83_6.x and arg_83_0 <= var_83_6.x + var_83_6.w and arg_83_1 >= var_83_6.y and arg_83_1 <= var_83_6.y + var_83_6.h then
				if var_0_27 then
					if var_0_27:isPlaying() then
						var_0_27:stop()
					end

					var_0_27:play()
				end

				var_0_25.pressed = true
				var_0_32 = "back"
				var_0_33 = 0.15

				return nil
			end
		end

		if var_0_74 and var_0_91[var_0_74] then
			local var_83_7 = var_0_74
			local var_83_8 = var_0_91[var_83_7]
			local var_83_9 = var_0_72(var_83_7)

			if var_83_9.revealed == false then
				return
			end

			local var_83_10 = var_0_1.getOriginiteAmount and var_0_1.getOriginiteAmount() or 0
			local var_83_11 = var_0_102(var_83_7) and var_83_10 >= var_83_8.cost
			local var_83_12 = var_83_8.maxed or false

			if not var_83_11 and not var_83_12 then
				var_83_9.shakeT = 0.3
				var_83_9.shakeDur = 0.4
				var_83_9.shakeAmp = 2
			elseif not var_83_12 and var_0_1.spendOriginite(var_83_8.cost) then
				var_0_0._sandboxUnlockRestore = nil
				var_83_9.scaleX = 1.2
				var_83_9.scaleY = 0.8
				var_83_9.popTimer = 0
				var_83_9.isPopping = true
				var_83_9.flashT = 0.2
				var_83_8.maxed = true

				var_0_0.applyUpgradeEffects()

				if var_83_7 == "corefav" or var_83_7 == "corefav2" then
					var_0_0.fillNewCoreFavorite()
				end

				if var_83_7 == "slotodds" then
					local var_83_13 = var_0_72("slotadvanced")

					var_83_13.revealed = false
					var_83_13.unlockLineProgress = 0
					var_83_13.isAppearing = false
					var_83_13.appearTimer = 0
					var_83_13.scaleX = 0
					var_83_13.scaleY = 0

					local var_83_14 = var_0_72("slotadvanced2")

					var_83_14.revealed = false
					var_83_14.unlockLineProgress = 0
					var_83_14.isAppearing = false
					var_83_14.appearTimer = 0
					var_83_14.scaleX = 0
					var_83_14.scaleY = 0

					local var_83_15 = var_0_72("corereroll")

					var_83_15.revealed = false
					var_83_15.unlockLineProgress = 0
					var_83_15.isAppearing = false
					var_83_15.appearTimer = 0
					var_83_15.scaleX = 0
					var_83_15.scaleY = 0

					local var_83_16 = var_0_72("firstcorespin")

					var_83_16.revealed = false
					var_83_16.unlockLineProgress = 0
					var_83_16.isAppearing = false
					var_83_16.appearTimer = 0
					var_83_16.scaleX = 0
					var_83_16.scaleY = 0

					local var_83_17 = var_0_72("firstcoreuncommon")

					var_83_17.revealed = false
					var_83_17.unlockLineProgress = 0
					var_83_17.isAppearing = false
					var_83_17.appearTimer = 0
					var_83_17.scaleX = 0
					var_83_17.scaleY = 0

					local var_83_18 = var_0_72("shopreroll")

					var_83_18.revealed = false
					var_83_18.unlockLineProgress = 0
					var_83_18.isAppearing = false
					var_83_18.appearTimer = 0
					var_83_18.scaleX = 0
					var_83_18.scaleY = 0

					local var_83_19 = var_0_72("iteminventory")

					var_83_19.revealed = false
					var_83_19.unlockLineProgress = 0
					var_83_19.isAppearing = false
					var_83_19.appearTimer = 0
					var_83_19.scaleX = 0
					var_83_19.scaleY = 0

					local var_83_20 = var_0_72("itemrefund")

					var_83_20.revealed = false
					var_83_20.unlockLineProgress = 0
					var_83_20.isAppearing = false
					var_83_20.appearTimer = 0
					var_83_20.scaleX = 0
					var_83_20.scaleY = 0

					local var_83_21 = var_0_72("iteminventory2")

					var_83_21.revealed = false
					var_83_21.unlockLineProgress = 0
					var_83_21.isAppearing = false
					var_83_21.appearTimer = 0
					var_83_21.scaleX = 0
					var_83_21.scaleY = 0

					local var_83_22 = var_0_72("itemresearch")

					var_83_22.revealed = false
					var_83_22.unlockLineProgress = 0
					var_83_22.isAppearing = false
					var_83_22.appearTimer = 0
					var_83_22.scaleX = 0
					var_83_22.scaleY = 0

					local var_83_23 = var_0_72("shoppin")

					var_83_23.revealed = false
					var_83_23.unlockLineProgress = 0
					var_83_23.isAppearing = false
					var_83_23.appearTimer = 0
					var_83_23.scaleX = 0
					var_83_23.scaleY = 0

					local var_83_24 = var_0_72("slotadvanced3")

					var_83_24.revealed = false
					var_83_24.unlockLineProgress = 0
					var_83_24.isAppearing = false
					var_83_24.appearTimer = 0
					var_83_24.scaleX = 0
					var_83_24.scaleY = 0

					local var_83_25 = var_0_72("slotrare")

					var_83_25.revealed = false
					var_83_25.unlockLineProgress = 0
					var_83_25.isAppearing = false
					var_83_25.appearTimer = 0
					var_83_25.scaleX = 0
					var_83_25.scaleY = 0

					local var_83_26 = var_0_72("preptime")

					var_83_26.revealed = false
					var_83_26.unlockLineProgress = 0
					var_83_26.isAppearing = false
					var_83_26.appearTimer = 0
					var_83_26.scaleX = 0
					var_83_26.scaleY = 0

					local var_83_27 = var_0_72("interest")

					var_83_27.revealed = false
					var_83_27.unlockLineProgress = 0
					var_83_27.isAppearing = false
					var_83_27.appearTimer = 0
					var_83_27.scaleX = 0
					var_83_27.scaleY = 0

					local var_83_28 = var_0_72("preptime2")

					var_83_28.revealed = false
					var_83_28.unlockLineProgress = 0
					var_83_28.isAppearing = false
					var_83_28.appearTimer = 0
					var_83_28.scaleX = 0
					var_83_28.scaleY = 0

					local var_83_29 = var_0_72("preptimerdisabled")

					var_83_29.revealed = false
					var_83_29.unlockLineProgress = 0
					var_83_29.isAppearing = false
					var_83_29.appearTimer = 0
					var_83_29.scaleX = 0
					var_83_29.scaleY = 0

					local var_83_30 = var_0_72("maxhp2")

					var_83_30.revealed = false
					var_83_30.unlockLineProgress = 0
					var_83_30.isAppearing = false
					var_83_30.appearTimer = 0
					var_83_30.scaleX = 0
					var_83_30.scaleY = 0
				elseif var_83_7 == "slotadvanced" then
					local var_83_31 = var_0_72("slotadvanced2")

					var_83_31.revealed = false
					var_83_31.unlockLineProgress = 0
					var_83_31.isAppearing = false
					var_83_31.appearTimer = 0
					var_83_31.scaleX = 0
					var_83_31.scaleY = 0

					local var_83_32 = var_0_72("corereroll")

					var_83_32.revealed = false
					var_83_32.unlockLineProgress = 0
					var_83_32.isAppearing = false
					var_83_32.appearTimer = 0
					var_83_32.scaleX = 0
					var_83_32.scaleY = 0

					local var_83_33 = var_0_72("firstcorespin")

					var_83_33.revealed = false
					var_83_33.unlockLineProgress = 0
					var_83_33.isAppearing = false
					var_83_33.appearTimer = 0
					var_83_33.scaleX = 0
					var_83_33.scaleY = 0

					local var_83_34 = var_0_72("firstcoreuncommon")

					var_83_34.revealed = false
					var_83_34.unlockLineProgress = 0
					var_83_34.isAppearing = false
					var_83_34.appearTimer = 0
					var_83_34.scaleX = 0
					var_83_34.scaleY = 0

					local var_83_35 = var_0_72("shopreroll")

					var_83_35.revealed = false
					var_83_35.unlockLineProgress = 0
					var_83_35.isAppearing = false
					var_83_35.appearTimer = 0
					var_83_35.scaleX = 0
					var_83_35.scaleY = 0

					local var_83_36 = var_0_72("iteminventory")

					var_83_36.revealed = false
					var_83_36.unlockLineProgress = 0
					var_83_36.isAppearing = false
					var_83_36.appearTimer = 0
					var_83_36.scaleX = 0
					var_83_36.scaleY = 0

					local var_83_37 = var_0_72("itemrefund")

					var_83_37.revealed = false
					var_83_37.unlockLineProgress = 0
					var_83_37.isAppearing = false
					var_83_37.appearTimer = 0
					var_83_37.scaleX = 0
					var_83_37.scaleY = 0

					local var_83_38 = var_0_72("iteminventory2")

					var_83_38.revealed = false
					var_83_38.unlockLineProgress = 0
					var_83_38.isAppearing = false
					var_83_38.appearTimer = 0
					var_83_38.scaleX = 0
					var_83_38.scaleY = 0

					local var_83_39 = var_0_72("itemresearch")

					var_83_39.revealed = false
					var_83_39.unlockLineProgress = 0
					var_83_39.isAppearing = false
					var_83_39.appearTimer = 0
					var_83_39.scaleX = 0
					var_83_39.scaleY = 0

					local var_83_40 = var_0_72("shoppin")

					var_83_40.revealed = false
					var_83_40.unlockLineProgress = 0
					var_83_40.isAppearing = false
					var_83_40.appearTimer = 0
					var_83_40.scaleX = 0
					var_83_40.scaleY = 0

					local var_83_41 = var_0_72("slotadvanced3")

					var_83_41.revealed = false
					var_83_41.unlockLineProgress = 0
					var_83_41.isAppearing = false
					var_83_41.appearTimer = 0
					var_83_41.scaleX = 0
					var_83_41.scaleY = 0

					local var_83_42 = var_0_72("slotrare")

					var_83_42.revealed = false
					var_83_42.unlockLineProgress = 0
					var_83_42.isAppearing = false
					var_83_42.appearTimer = 0
					var_83_42.scaleX = 0
					var_83_42.scaleY = 0
				elseif var_83_7 == "iteminventory" then
					local var_83_43 = var_0_72("iteminventory2")

					var_83_43.revealed = false
					var_83_43.unlockLineProgress = 0
					var_83_43.isAppearing = false
					var_83_43.appearTimer = 0
					var_83_43.scaleX = 0
					var_83_43.scaleY = 0
				elseif var_83_7 == "slotadvanced2" then
					local var_83_44 = var_0_72("slotadvanced3")

					var_83_44.revealed = false
					var_83_44.unlockLineProgress = 0
					var_83_44.isAppearing = false
					var_83_44.appearTimer = 0
					var_83_44.scaleX = 0
					var_83_44.scaleY = 0

					local var_83_45 = var_0_72("slotrare")

					var_83_45.revealed = false
					var_83_45.unlockLineProgress = 0
					var_83_45.isAppearing = false
					var_83_45.appearTimer = 0
					var_83_45.scaleX = 0
					var_83_45.scaleY = 0
				elseif var_83_7 == "slotadvanced3" then
					local var_83_46 = var_0_72("slotrare")

					var_83_46.revealed = false
					var_83_46.unlockLineProgress = 0
					var_83_46.isAppearing = false
					var_83_46.appearTimer = 0
					var_83_46.scaleX = 0
					var_83_46.scaleY = 0
				elseif var_83_7 == "maxhp" then
					local var_83_47 = var_0_72("noviceshield")

					var_83_47.revealed = false
					var_83_47.unlockLineProgress = 0
					var_83_47.isAppearing = false
					var_83_47.appearTimer = 0
					var_83_47.scaleX = 0
					var_83_47.scaleY = 0

					local var_83_48 = var_0_72("startgold")

					var_83_48.revealed = false
					var_83_48.unlockLineProgress = 0
					var_83_48.isAppearing = false
					var_83_48.appearTimer = 0
					var_83_48.scaleX = 0
					var_83_48.scaleY = 0
				elseif var_83_7 == "noviceshield" then
					local var_83_49 = var_0_72("comebackspin")

					var_83_49.revealed = false
					var_83_49.unlockLineProgress = 0
					var_83_49.isAppearing = false
					var_83_49.appearTimer = 0
					var_83_49.scaleX = 0
					var_83_49.scaleY = 0
				elseif var_83_7 == "startgold" then
					local var_83_50 = var_0_72("comebackgold")

					var_83_50.revealed = false
					var_83_50.unlockLineProgress = 0
					var_83_50.isAppearing = false
					var_83_50.appearTimer = 0
					var_83_50.scaleX = 0
					var_83_50.scaleY = 0

					local var_83_51 = var_0_72("startgold2")

					var_83_51.revealed = false
					var_83_51.unlockLineProgress = 0
					var_83_51.isAppearing = false
					var_83_51.appearTimer = 0
					var_83_51.scaleX = 0
					var_83_51.scaleY = 0

					local var_83_52 = var_0_72("maxhp2")

					var_83_52.revealed = false
					var_83_52.unlockLineProgress = 0
					var_83_52.isAppearing = false
					var_83_52.appearTimer = 0
					var_83_52.scaleX = 0
					var_83_52.scaleY = 0
				elseif var_83_7 == "comebackgold" then
					local var_83_53 = var_0_72("maxhp2")

					var_83_53.revealed = false
					var_83_53.unlockLineProgress = 0
					var_83_53.isAppearing = false
					var_83_53.appearTimer = 0
					var_83_53.scaleX = 0
					var_83_53.scaleY = 0
				elseif var_83_7 == "comebackspin" then
					local var_83_54 = var_0_72("gateheal")

					var_83_54.revealed = false
					var_83_54.unlockLineProgress = 0
					var_83_54.isAppearing = false
					var_83_54.appearTimer = 0
					var_83_54.scaleX = 0
					var_83_54.scaleY = 0
				elseif var_83_7 == "maxunit" then
					local var_83_55 = var_0_72("maxunit2")

					var_83_55.revealed = false
					var_83_55.unlockLineProgress = 0
					var_83_55.isAppearing = false
					var_83_55.appearTimer = 0
					var_83_55.scaleX = 0
					var_83_55.scaleY = 0

					local var_83_56 = var_0_72("maxunit3")

					var_83_56.revealed = false
					var_83_56.unlockLineProgress = 0
					var_83_56.isAppearing = false
					var_83_56.appearTimer = 0
					var_83_56.scaleX = 0
					var_83_56.scaleY = 0

					local var_83_57 = var_0_72("preptime")

					var_83_57.revealed = false
					var_83_57.unlockLineProgress = 0
					var_83_57.isAppearing = false
					var_83_57.appearTimer = 0
					var_83_57.scaleX = 0
					var_83_57.scaleY = 0

					local var_83_58 = var_0_72("preptimerdisabled")

					var_83_58.revealed = false
					var_83_58.unlockLineProgress = 0
					var_83_58.isAppearing = false
					var_83_58.appearTimer = 0
					var_83_58.scaleX = 0
					var_83_58.scaleY = 0
				elseif var_83_7 == "maxunit2" then
					local var_83_59 = var_0_72("maxunit3")

					var_83_59.revealed = false
					var_83_59.unlockLineProgress = 0
					var_83_59.isAppearing = false
					var_83_59.appearTimer = 0
					var_83_59.scaleX = 0
					var_83_59.scaleY = 0
				elseif var_83_7 == "preptime" then
					local var_83_60 = var_0_72("interest")

					var_83_60.revealed = false
					var_83_60.unlockLineProgress = 0
					var_83_60.isAppearing = false
					var_83_60.appearTimer = 0
					var_83_60.scaleX = 0
					var_83_60.scaleY = 0

					local var_83_61 = var_0_72("preptime2")

					var_83_61.revealed = false
					var_83_61.unlockLineProgress = 0
					var_83_61.isAppearing = false
					var_83_61.appearTimer = 0
					var_83_61.scaleX = 0
					var_83_61.scaleY = 0

					local var_83_62 = var_0_72("preptimerdisabled")

					var_83_62.revealed = false
					var_83_62.unlockLineProgress = 0
					var_83_62.isAppearing = false
					var_83_62.appearTimer = 0
					var_83_62.scaleX = 0
					var_83_62.scaleY = 0
				elseif var_83_7 == "preptime2" then
					local var_83_63 = var_0_72("preptimerdisabled")

					var_83_63.revealed = false
					var_83_63.unlockLineProgress = 0
					var_83_63.isAppearing = false
					var_83_63.appearTimer = 0
					var_83_63.scaleX = 0
					var_83_63.scaleY = 0
				end

				return {
					action = "upgrade_" .. var_83_7
				}
			end
		end
	end

	if arg_83_2 == 1 and var_0_69 then
		if var_0_70.plus then
			local var_83_64 = var_0_70.plus

			if arg_83_0 >= var_83_64.x and arg_83_0 <= var_83_64.x + var_83_64.w and arg_83_1 >= var_83_64.y and arg_83_1 <= var_83_64.y + var_83_64.h then
				return {
					amount = 10,
					action = "add_originite"
				}
			end
		end

		if var_0_70.minus then
			local var_83_65 = var_0_70.minus

			if arg_83_0 >= var_83_65.x and arg_83_0 <= var_83_65.x + var_83_65.w and arg_83_1 >= var_83_65.y and arg_83_1 <= var_83_65.y + var_83_65.h then
				return {
					amount = -10,
					action = "add_originite"
				}
			end
		end
	end

	if arg_83_2 == 2 then
		var_0_54 = true
		var_0_55, var_0_56 = 0, 0
		var_0_57 = arg_83_0
		var_0_58 = arg_83_1
		var_0_59 = var_0_44
		var_0_60 = var_0_45
	end
end

function var_0_0.keypressed(arg_84_0)
	if arg_84_0 == "f2" then
		local var_84_0 = love and love.filesystem

		if var_84_0 and var_84_0.getInfo and (var_84_0.getInfo("release.flag", "file") or var_84_0.getInfo("build_release.flag", "file")) then
			return
		end

		var_0_69 = not var_0_69
		var_0_70 = {}
		var_0_0._sandboxAllHover = false

		return
	end

	if arg_84_0 == "escape" then
		return "back"
	end

	return nil
end

function var_0_0.wheelmoved(arg_85_0, arg_85_1, arg_85_2, arg_85_3)
	local var_85_0 = tonumber(arg_85_1) or 0

	if var_85_0 == 0 then
		var_85_0 = tonumber(arg_85_0) or 0
	end

	if var_85_0 == 0 then
		return false
	end

	local var_85_1 = 1
	local var_85_2 = math.huge

	for iter_85_0, iter_85_1 in ipairs(var_0_47) do
		local var_85_3 = math.abs(iter_85_1 - var_0_48)

		if var_85_3 < var_85_2 then
			var_85_2 = var_85_3
			var_85_1 = iter_85_0
		end
	end

	if not (var_85_0 > 0) then
		var_85_1 = math.max(1, var_85_1 - 1)
	else
		var_85_1 = math.min(#var_0_47, var_85_1 + 1)
	end

	local var_85_4 = var_0_47[var_85_1]

	if math.abs(var_85_4 - var_0_48) < 0.0001 then
		return true
	end

	local var_85_5 = tonumber(arg_85_2) or var_0_52 / 2
	local var_85_6 = tonumber(arg_85_3) or var_0_53 / 2
	local var_85_7 = var_0_52 / 2 + (var_85_5 - var_0_52 / 2 - var_0_44) / var_0_46
	local var_85_8 = var_0_53 / 2 + (var_85_6 - var_0_53 / 2 - var_0_45) / var_0_46

	var_0_49 = var_85_5 - var_0_52 / 2 - (var_85_7 - var_0_52 / 2) * var_85_4
	var_0_50 = var_85_6 - var_0_53 / 2 - (var_85_8 - var_0_53 / 2) * var_85_4
	var_0_49, var_0_50 = var_0_66(var_0_49, var_0_50, var_85_4)
	var_0_48 = var_85_4
	var_0_51 = true

	return true
end

function var_0_0.mousereleased(arg_86_0, arg_86_1, arg_86_2)
	if arg_86_2 == 1 and var_0_25 then
		var_0_25.pressed = false
	end

	if arg_86_2 == 2 then
		var_0_54 = false

		if not var_0_51 then
			local var_86_0, var_86_1 = var_0_66(var_0_44, var_0_45, var_0_46)

			if var_86_0 ~= var_0_44 or var_86_1 ~= var_0_45 then
				var_0_49, var_0_50 = var_86_0, var_86_1
				var_0_51 = true
			end
		else
			local var_86_2 = var_0_48 / math.max(0.0001, var_0_46)

			var_0_49, var_0_50 = var_0_66(var_0_44 * var_86_2, var_0_45 * var_86_2, var_0_48)
		end
	end
end

function var_0_0.mousemoved(arg_87_0, arg_87_1, arg_87_2, arg_87_3)
	if var_0_54 then
		var_0_44, var_0_45 = var_0_68(var_0_59, var_0_60, arg_87_0 - var_0_57, arg_87_1 - var_0_58, var_0_46)
	end
end

function var_0_0.getBattleSpeedMultiplier()
	return 1
end

function var_0_0.getSpinLuckForceWinProb()
	return 0
end

function var_0_0.getSpinLuckSuppressDelta()
	return 0
end

function var_0_0.getMaxUnitBonus()
	local var_91_0 = rawget(_G, "Tutorial")

	if var_91_0 and var_91_0.isUnderway and var_91_0.isUnderway() then
		return 0
	end

	if var_0_91.maxunit3 and var_0_91.maxunit3.maxed then
		return 3
	end

	if var_0_91.maxunit2 and var_0_91.maxunit2.maxed then
		return 2
	end

	if var_0_91.maxunit.maxed then
		return 1
	end

	return 0
end

function var_0_0.getBaseHPBonus()
	if var_0_91.maxhp2 and var_0_91.maxhp2.maxed then
		return 2
	end

	if var_0_91.maxhp and var_0_91.maxhp.maxed then
		return 1
	end

	return 0
end

function var_0_0.getEarlyBaseShieldEnabled()
	return (var_0_91.noviceshield and var_0_91.noviceshield.maxed) == true
end

function var_0_0.getStartGoldBonus()
	if var_0_91.startgold2 and var_0_91.startgold2.maxed then
		return 100
	end

	return var_0_91.startgold and var_0_91.startgold.maxed and 50 or 0
end

function var_0_0.getComebackGuaranteedSpinEnabled()
	return (var_0_91.comebackspin and var_0_91.comebackspin.maxed) == true
end

function var_0_0.getGateRecoveryEnabled()
	return (var_0_91.gateheal and var_0_91.gateheal.maxed) == true
end

function var_0_0.getComebackGoldBonus()
	if not var_0_91.comebackgold or not var_0_91.comebackgold.maxed then
		return 0
	end

	return var_0_91.comebackgold2 and var_0_91.comebackgold2.maxed and 150 or 100
end

function var_0_0.getNudgeEnabled()
	local var_98_0 = package.loaded["src.game.machines"]

	return not var_98_0 or var_98_0.assist() == "nudge"
end

function var_0_0.getNudgeMissDiscountEnabled()
	return (var_0_91.slotnudge and var_0_91.slotnudge.maxed) == true
end

function var_0_0.getPrepTimeBonusSec()
	return 0
end

function var_0_0.getStartingMercContractCount()
	return var_0_91.startingmerccontract and var_0_91.startingmerccontract.maxed and 1 or 0
end

function var_0_0.isPrepTimerDisabled()
	return false
end

function var_0_0.getMaxInterestBonus()
	return var_0_91.interest and var_0_91.interest.maxed and 50 or 0
end

function var_0_0.getFactionSynergyUnlocked()
	return var_0_91.factionsynergy and var_0_91.factionsynergy.maxed == true
end

function var_0_0.getAwakeningUnlocked()
	return var_0_91.dormantpower and var_0_91.dormantpower.maxed == true
end

function var_0_0.getPromotionTraitChoiceUnlocked()
	return var_0_91.growthbranch and var_0_91.growthbranch.maxed == true
end

function var_0_0.getCoreFreeRerollBonus()
	local var_107_0 = var_0_91.corereroll and var_0_91.corereroll.maxed and 1 or 0

	if var_0_91.corereroll2 and var_0_91.corereroll2.maxed then
		var_107_0 = var_107_0 + 1
	end

	return var_107_0
end

function var_0_0.getFirstCoreSpinReqDelta()
	return var_0_91.firstcorespin and var_0_91.firstcorespin.maxed and -1 or 0
end

function var_0_0.getFirstCoreUncommonGuarantee()
	if not var_0_91.firstcoreuncommon or not var_0_91.firstcoreuncommon.maxed then
		return 0
	end

	return var_0_91.secondcoreuncommon and var_0_91.secondcoreuncommon.maxed and 2 or 1
end

function var_0_0.getShopFirstRerollDiscount()
	return var_0_91.shopreroll and var_0_91.shopreroll.maxed and 1 or 0
end

function var_0_0.getItemInventoryAdd()
	if var_0_91.iteminventory2 and var_0_91.iteminventory2.maxed then
		return 2
	end

	return var_0_91.iteminventory and var_0_91.iteminventory.maxed and 1 or 0
end

function var_0_0.getItemRefundRate()
	return var_0_91.itemrefund and var_0_91.itemrefund.maxed and 0.8 or 0.5
end

function var_0_0.getItemResearchTier()
	return var_0_91.itemresearch and var_0_91.itemresearch.maxed and 1 or 0
end

function var_0_0.getShopPinCount()
	return var_0_91.shoppin and var_0_91.shoppin.maxed and 1 or 0
end

function var_0_0.isOwned(arg_115_0)
	return var_0_91[arg_115_0] ~= nil and var_0_91[arg_115_0].maxed == true
end

function var_0_0.boughtCount()
	local var_116_0 = 0
	local var_116_1 = 0

	for iter_116_0, iter_116_1 in pairs(var_0_91) do
		if not iter_116_1.hidden and not var_0_0.isEditionLocked(iter_116_1) and (not iter_116_1.reqFull or _G.GameEditionMode == "full") then
			var_116_1 = var_116_1 + 1

			if iter_116_1.maxed == true then
				var_116_0 = var_116_0 + 1
			end
		end
	end

	return var_116_0, var_116_1
end

function var_0_0.isContentUnlocked(arg_117_0, arg_117_1)
	local var_117_0 = var_0_0._unlockNodeFor and var_0_0._unlockNodeFor[arg_117_0]
	local var_117_1 = var_117_0 and var_117_0[tostring(arg_117_1)]

	if not var_117_1 then
		return true
	end

	return var_0_91[var_117_1] ~= nil and var_0_91[var_117_1].maxed == true
end

local function var_0_115(arg_118_0, ...)
	local var_118_0 = {}

	for iter_118_0, iter_118_1 in ipairs({
		...
	}) do
		var_118_0[#var_118_0 + 1] = arg_118_0 .. iter_118_1
	end

	return var_118_0
end

local function var_0_116(...)
	local var_119_0 = {}

	for iter_119_0, iter_119_1 in ipairs({
		...
	}) do
		for iter_119_2, iter_119_3 in ipairs(iter_119_1) do
			var_119_0[#var_119_0 + 1] = iter_119_3
		end
	end

	return var_119_0
end

local var_0_117 = var_0_115("unlock_core_", 31, 27, 28, 29, 19, 20, 21, 24, 30, 25, 26, 22, 23, 32, 38, 36, 37, 35, 39, 40)
local var_0_118 = var_0_116({
	"shopreroll",
	"itemrefund",
	"shopdiscount"
}, var_0_115("unlock_item_", "07", "08", "37", "17", "27", "28", "11", "40", "24", "45", "23", "48"))
local var_0_119 = var_0_116({
	"slotadvanced",
	"slotadvanced2",
	"slotadvanced3",
	"slotrare",
	"slotrare2",
	"slotrare3",
	"slotlegend",
	"slotlegend2",
	"slotlegend3",
	"slotprism",
	"slotprism2",
	"slotprism3"
}, {
	"fatestone",
	"stonetwin",
	"stonebreeze",
	"stoneomen",
	"stonespecial",
	"stonemastery",
	"stonerift",
	"stoneconstellation",
	"stonesanctum",
	"stonegambit",
	"questreroll"
})

var_0_0.SECTION_REWARDS = {
	corefav = {
		labelKey = "corefav_req_cores",
		need = 5,
		nodes = var_0_117
	},
	corefav2 = {
		labelKey = "upgrade_section_req_blast",
		nodes = var_0_116({
			"blastmachine",
			"blastmastery"
		}, var_0_115("unlock_core_", 43, 44, 45, 46, 47, 48))
	},
	iteminventory = {
		labelKey = "upgrade_section_req_shop_progress",
		need = 8,
		nodes = var_0_118
	},
	iteminventory2 = {
		labelKey = "upgrade_section_req_shop",
		nodes = var_0_118
	},
	growthbranch = {
		labelKey = "upgrade_section_req_units",
		nodes = var_0_116({
			"maxunit",
			"maxunit2",
			"maxunit3",
			"dormantpower"
		}, var_0_115("unlock_trait_", 23, 11, 25, 28, 26, 29, 32))
	},
	startessence = {
		labelKey = "upgrade_section_req_supply",
		nodes = {
			"maxhp",
			"maxhp2",
			"noviceshield",
			"comebackspin",
			"gateheal",
			"startgold",
			"startgold2",
			"startingmerccontract",
			"mercextend",
			"comebackgold",
			"comebackgold2",
			"interest",
			"wingold",
			"lastspin"
		}
	},
	stoneshop = {
		labelKey = "upgrade_section_req_stones_progress",
		need = 16,
		nodes = var_0_119
	},
	stoneshop2 = {
		labelKey = "upgrade_section_req_stones",
		nodes = var_0_119
	}
}

function var_0_0.sectionRequirement(arg_120_0)
	local var_120_0 = var_0_0.SECTION_REWARDS[arg_120_0]

	if not var_120_0 then
		return nil
	end

	local var_120_1 = 0
	local var_120_2 = 0

	for iter_120_0, iter_120_1 in ipairs(var_120_0.nodes) do
		local var_120_3 = var_0_91[iter_120_1]

		if var_120_3 and not var_0_0.isEditionLocked(var_120_3) and (not var_120_3.reqFull or _G.GameEditionMode == "full") then
			var_120_2 = var_120_2 + 1

			if var_120_3.maxed == true then
				var_120_1 = var_120_1 + 1
			end
		end
	end

	if var_120_0.need then
		local var_120_4 = var_120_0.need

		if var_120_2 <= var_120_4 and var_120_2 < #var_120_0.nodes then
			var_120_4 = math.max(1, math.floor(var_120_4 * var_120_2 / #var_120_0.nodes + 0.5))
		end

		var_120_2 = math.min(var_120_4, var_120_2)
		var_120_1 = math.min(var_120_1, var_120_2)
	end

	return var_120_1, var_120_2, var_120_0.labelKey
end

function var_0_0.sectionRewardMet(arg_121_0)
	local var_121_0, var_121_1 = var_0_0.sectionRequirement(arg_121_0)

	return var_121_0 == nil or var_121_1 <= var_121_0
end

local var_0_120 = "src/sprites/mainmenu/upgrade_sections/"
local var_0_121 = {
	it = "italian",
	ko = "korean",
	fr = "french",
	pt = "portuguese_brazil",
	["zh-Hant"] = "chinese_traditional",
	tr = "turkish",
	zh = "chinese",
	pl = "polish",
	en = "english",
	ru = "russian",
	es = "spanish",
	de = "german",
	ja = "japanese"
}
local var_0_122 = {
	"research",
	"core",
	"shop",
	"blast",
	"units",
	"supply"
}
local var_0_123 = {
	units = "maxunit",
	blast = "blastmachine",
	core = "corereroll",
	research = "slotadvanced",
	shop = "shopreroll",
	supply = "maxhp"
}
local var_0_124 = {
	"blastmachine",
	"blastmastery",
	"unlock_core_43",
	"unlock_core_44",
	"unlock_core_45",
	"unlock_core_46",
	"unlock_core_47",
	"unlock_core_48"
}
local var_0_125 = {
	startgold = "maxhp",
	corereroll = "slotadvanced",
	noviceshield = "maxhp",
	comebackspin = "noviceshield",
	slotadvanced2 = "slotadvanced",
	maxhp = "slotodds",
	slotadvanced = "slotodds",
	firstcoreuncommon = "firstcorespin",
	maxunit3 = "maxunit2",
	slotrare = "slotadvanced3",
	maxunit2 = "maxunit",
	startgold2 = "startgold",
	maxunit = "slotodds",
	maxhp2 = "comebackgold",
	comebackgold = "startgold",
	slotadvanced3 = "slotadvanced2",
	iteminventory2 = "iteminventory",
	iteminventory = "shopreroll",
	shopreroll = "slotadvanced",
	gateheal = "comebackspin",
	firstcorespin = "corereroll",
	startingmerccontract = "startgold"
}
local var_0_126 = 6
local var_0_127 = 1
local var_0_128 = 0.3
local var_0_129 = 0.44
local var_0_130 = {
	{
		"core",
		"shop"
	},
	{
		"blast"
	},
	{
		"supply",
		"units"
	}
}
local var_0_131 = 0.51
local var_0_132 = 536
local var_0_133 = 430
local var_0_134 = {
	{
		254,
		26,
		132,
		26
	},
	{
		40,
		38,
		40,
		42
	},
	{
		575,
		20,
		60,
		28
	}
}
local var_0_135 = 258
local var_0_136 = 92
local var_0_137 = 5.5

var_0_0.SECTION_TITLE_FOLDERS, var_0_0.SECTION_TITLE_IDS = var_0_121, var_0_122

local var_0_138 = {}

local function var_0_139(arg_122_0)
	local var_122_0 = var_0_121[arg_122_0] or var_0_121.en
	local var_122_1 = var_0_138[var_122_0]

	if var_122_1 ~= nil then
		return var_122_1
	end

	local var_122_2 = {
		height = 0
	}

	for iter_122_0, iter_122_1 in ipairs(var_0_122) do
		local var_122_3, var_122_4 = pcall(love.graphics.newImage, var_0_120 .. var_122_0 .. "/" .. iter_122_1 .. ".png")

		if not var_122_3 or not var_122_4 then
			var_0_138[var_122_0] = false

			return false
		end

		var_122_4:setFilter("nearest", "nearest")

		local var_122_5, var_122_6 = var_122_4:getDimensions()

		var_122_2[iter_122_1] = {
			img = var_122_4,
			w = var_122_5
		}
		var_122_2.height = math.max(var_122_2.height, var_122_6)
	end

	var_0_138[var_122_0] = var_122_2

	return var_122_2
end

local function var_0_140(arg_123_0, arg_123_1, arg_123_2)
	local var_123_0 = math.ceil(arg_123_0 - arg_123_1 / 2)

	if arg_123_2 > 0 then
		return var_123_0
	end

	return -var_123_0 - arg_123_1
end

local function var_0_141(arg_124_0, arg_124_1, arg_124_2)
	local var_124_0 = var_0_139(arg_124_1)

	if not var_124_0 then
		return nil
	end

	local var_124_1 = var_124_0.height
	local var_124_2 = {}

	for iter_124_0, iter_124_1 in pairs(arg_124_0) do
		local var_124_3 = var_0_125[iter_124_0] or var_0_91[iter_124_0] and var_0_91[iter_124_0].parent
		local var_124_4 = var_124_3 and arg_124_0[var_124_3]

		if var_124_4 then
			var_124_2[#var_124_2 + 1] = {
				iter_124_1.x,
				iter_124_1.y,
				var_124_4.x,
				var_124_4.y
			}
		end
	end

	local function var_124_5(arg_125_0, arg_125_1, arg_125_2, arg_125_3)
		local var_125_0 = 16 * arg_125_0 + 1
		local var_125_1 = arg_125_1 * arg_125_0 - arg_125_3 / 2 - var_0_127
		local var_125_2 = arg_125_2 * arg_125_0 - var_124_1 / 2 - var_0_127
		local var_125_3 = arg_125_1 * arg_125_0 + arg_125_3 / 2 + var_0_127
		local var_125_4 = arg_125_2 * arg_125_0 + var_124_1 / 2 + var_0_127

		for iter_125_0, iter_125_1 in pairs(arg_124_0) do
			local var_125_5 = iter_125_1.x * arg_125_0
			local var_125_6 = iter_125_1.y * arg_125_0

			if var_125_3 > var_125_5 - var_125_0 and var_125_1 < var_125_5 + var_125_0 and var_125_4 > var_125_6 - var_125_0 and var_125_2 < var_125_6 + var_125_0 then
				return false
			end
		end

		for iter_125_2, iter_125_3 in ipairs(var_124_2) do
			local var_125_7 = iter_125_3[1] * arg_125_0
			local var_125_8 = iter_125_3[2] * arg_125_0
			local var_125_9 = iter_125_3[3] * arg_125_0
			local var_125_10 = iter_125_3[4] * arg_125_0

			if var_125_3 >= math.min(var_125_7, var_125_9) and var_125_1 <= math.max(var_125_7, var_125_9) and var_125_4 >= math.min(var_125_8, var_125_10) and var_125_2 <= math.max(var_125_8, var_125_10) then
				local var_125_11 = math.ceil(math.max(math.abs(var_125_7 - var_125_9), math.abs(var_125_8 - var_125_10)))

				for iter_125_4 = 0, var_125_11 do
					local var_125_12 = iter_125_4 / math.max(var_125_11, 1)
					local var_125_13 = var_125_7 + (var_125_9 - var_125_7) * var_125_12
					local var_125_14 = var_125_8 + (var_125_10 - var_125_8) * var_125_12

					if var_125_1 <= var_125_13 and var_125_13 <= var_125_3 and var_125_2 <= var_125_14 and var_125_14 <= var_125_4 then
						return false
					end
				end
			end
		end

		return true
	end

	local function var_124_6(arg_126_0, arg_126_1)
		local var_126_0

		for iter_126_0 = #var_0_47, 1, -1 do
			local var_126_1 = var_0_47[iter_126_0]
			local var_126_2 = true

			if var_126_1 < var_0_129 then
				break
			end

			for iter_126_1, iter_126_2 in ipairs(arg_126_0) do
				local var_126_3 = arg_126_1[iter_126_2]

				if arg_124_0[var_0_123[iter_126_2]] and not var_124_5(var_126_1, var_126_3.x, var_126_3.y, var_124_0[iter_126_2].w) then
					var_126_2 = false
				end
			end

			if not var_126_2 then
				break
			end

			var_126_0 = var_126_1
		end

		return var_126_0
	end

	local var_124_7 = {
		core = {
			x = -72,
			y = -60
		},
		shop = {
			x = 72,
			y = -60
		},
		blast = {
			x = 210,
			y = 36
		},
		research = {
			x = 62,
			y = -150
		}
	}
	local var_124_8 = {
		"supply",
		"units"
	}

	local function var_124_9(arg_127_0, arg_127_1)
		return {
			supply = {
				x = -arg_127_0,
				y = arg_127_1
			},
			units = {
				x = arg_127_0,
				y = arg_127_1
			}
		}
	end

	local var_124_10 = var_124_9(math.max(84, 46 + math.max(var_124_0.supply.w, var_124_0.units.w) / 2), 36)
	local var_124_11 = var_124_6(var_124_8, var_124_10)

	if not var_124_11 or var_124_11 > var_0_131 then
		for iter_124_2 = 160, 300, 4 do
			local var_124_12 = var_124_9(iter_124_2, 104)
			local var_124_13 = var_124_6(var_124_8, var_124_12)

			if var_124_13 and var_124_13 <= var_0_131 then
				var_124_10 = var_124_12

				break
			end
		end
	end

	var_124_7.supply, var_124_7.units = var_124_10.supply, var_124_10.units

	local var_124_14 = var_0_129

	for iter_124_3, iter_124_4 in ipairs(var_0_130) do
		var_124_14 = math.max(var_124_14, var_124_6(iter_124_4, var_124_7) or var_0_47[#var_0_47])
	end

	local var_124_15 = var_124_14 / 1.15

	for iter_124_5, iter_124_6 in ipairs(var_0_47) do
		if iter_124_6 >= var_124_14 - 0.001 then
			var_124_14, var_124_15 = iter_124_6, var_0_47[iter_124_5 - 1] or iter_124_6 / 1.15

			break
		end
	end

	local var_124_16 = var_124_6({
		"research"
	}, var_124_7)

	if not var_124_16 or var_124_14 < var_124_16 then
		var_124_7.research = nil
	end

	local var_124_17 = {}
	local var_124_18 = var_0_128
	local var_124_19 = 16 * var_0_128 + 1

	local function var_124_20(arg_128_0, arg_128_1, arg_128_2)
		var_124_17[arg_128_0] = {
			x = (arg_128_1 + var_124_0[arg_128_0].w / 2) / var_124_18,
			y = (arg_128_2 + var_124_1 / 2) / var_124_18
		}
	end

	local var_124_21 = math.floor(-96 * var_124_18 + 0.5)
	local var_124_22 = 0

	for iter_124_7, iter_124_8 in pairs(arg_124_0) do
		if math.abs(iter_124_8.y * var_124_18 - var_124_21) <= var_124_1 / 2 + var_0_127 + var_124_19 then
			var_124_22 = math.max(var_124_22, math.abs(iter_124_8.x * var_124_18) + var_124_19)
		end
	end

	for iter_124_9, iter_124_10 in ipairs(var_124_2) do
		local var_124_23 = math.ceil(math.max(math.abs(iter_124_10[1] - iter_124_10[3]), math.abs(iter_124_10[2] - iter_124_10[4])) * var_124_18)

		for iter_124_11 = 0, var_124_23 do
			local var_124_24 = iter_124_11 / math.max(var_124_23, 1)

			if math.abs((iter_124_10[2] + (iter_124_10[4] - iter_124_10[2]) * var_124_24) * var_124_18 - var_124_21) <= var_124_1 / 2 + var_0_127 then
				var_124_22 = math.max(var_124_22, math.abs(iter_124_10[1] + (iter_124_10[3] - iter_124_10[1]) * var_124_24) * var_124_18)
			end
		end
	end

	local var_124_25 = math.ceil(var_124_22 + var_0_126) + math.ceil(math.max(var_124_0.core.w, var_124_0.shop.w) / 2)
	local var_124_26 = var_124_21 - math.floor(var_124_1 / 2)

	if arg_124_0[var_0_123.core] then
		var_124_20("core", var_0_140(var_124_25, var_124_0.core.w, -1), var_124_26)
	end

	if arg_124_0[var_0_123.shop] then
		var_124_20("shop", var_0_140(var_124_25, var_124_0.shop.w, 1), var_124_26)
	end

	if arg_124_0[var_0_123.blast] then
		local var_124_27 = 0
		local var_124_28 = 0

		for iter_124_12, iter_124_13 in ipairs(var_0_124) do
			if arg_124_0[iter_124_13] then
				var_124_27 = math.max(var_124_27, arg_124_0[iter_124_13].y)
			end
		end

		for iter_124_14, iter_124_15 in ipairs(var_0_124) do
			if arg_124_0[iter_124_15] and arg_124_0[iter_124_15].y == var_124_27 then
				var_124_28 = math.max(var_124_28, arg_124_0[iter_124_15].x)
			end
		end

		var_124_20("blast", math.ceil(var_124_28 * var_124_18 + var_124_19 + var_0_126), math.floor(var_124_27 * var_124_18 + 0.5) - math.floor(var_124_1 / 2))
	end

	local var_124_29 = math.max(var_124_0.supply.w, var_124_0.units.w)
	local var_124_30 = arg_124_1 == "ko" and var_0_132 or var_0_133
	local var_124_31 = math.min(math.floor(264 * var_124_18 + 0.5), var_124_30 - var_0_127 - arg_124_2 / 2 - math.ceil(var_124_29 / 2))

	local function var_124_32(arg_129_0, arg_129_1)
		local var_129_0

		for iter_129_0, iter_129_1 in pairs(arg_124_0) do
			local var_129_1

			if not arg_129_1 then
				var_129_1 = iter_129_1.x ~= 0 and math.abs(math.abs(iter_129_1.x * var_124_18) - arg_129_0) <= var_124_29 / 2 + var_0_127 + var_124_19
			else
				var_129_1 = math.abs(iter_129_1.x) == 72
			end

			if var_129_1 then
				local var_129_2 = iter_129_1.y * var_124_18 + var_124_19

				if not var_129_0 or var_129_0 < var_129_2 then
					var_129_0 = var_129_2
				end
			end
		end

		return var_129_0 and math.ceil(var_129_0 + var_0_126)
	end

	local var_124_33
	local var_124_34 = math.floor(72 * var_124_18 + 0.5)

	if not arg_124_0.comebackspin and var_124_34 - var_124_29 / 2 >= var_0_127 + 1 then
		local var_124_35 = var_124_32(var_124_34, true)
		local var_124_36 = var_0_140(var_124_34, var_124_0.supply.w, -1)
		local var_124_37 = var_0_140(var_124_34, var_124_0.units.w, 1)

		if var_124_35 and (not arg_124_0[var_0_123.supply] or var_124_5(var_124_18, (var_124_36 + var_124_0.supply.w / 2) / var_124_18, (var_124_35 + var_124_1 / 2) / var_124_18, var_124_0.supply.w)) and (not arg_124_0[var_0_123.units] or var_124_5(var_124_18, (var_124_37 + var_124_0.units.w / 2) / var_124_18, (var_124_35 + var_124_1 / 2) / var_124_18, var_124_0.units.w)) then
			var_124_31, var_124_33 = var_124_34, var_124_35
		end
	end

	var_124_33 = var_124_33 or var_124_32(var_124_31, false) or var_124_32(var_124_31, true)

	if var_124_33 then
		if arg_124_0[var_0_123.supply] then
			var_124_20("supply", var_0_140(var_124_31, var_124_0.supply.w, -1), var_124_33)
		end

		if arg_124_0[var_0_123.units] then
			var_124_20("units", var_0_140(var_124_31, var_124_0.units.w, 1), var_124_33)
		end
	end

	local var_124_38 = arg_124_0.slotadvanced3 or arg_124_0.slotadvanced2 or arg_124_0.slotadvanced

	if var_124_38 then
		local var_124_39 = -math.floor(var_124_0.research.w / 2)
		local var_124_40 = math.floor(var_124_38.y * var_124_18 - var_124_19 - var_0_126 - var_124_1)

		if arg_124_0.slotrare then
			local var_124_41 = var_124_40 < (arg_124_0.slotlegend and arg_124_0.slotlegend.y * var_124_18 + var_124_19 + var_0_127 or -math.huge) and var_124_19 or 1

			if var_124_39 < -math.floor(96 * var_124_18 - var_124_41 - var_0_127) then
				var_124_39 = -math.floor(96 * var_124_18 - var_124_41 - var_0_126)
			end
		end

		var_124_20("research", var_124_39, var_124_40)
	end

	local var_124_42 = {}

	for iter_124_16, iter_124_17 in ipairs(var_0_122) do
		if arg_124_0[var_0_123[iter_124_17]] then
			var_124_42[iter_124_17] = {
				near = var_124_7[iter_124_17],
				far = var_124_17[iter_124_17],
				from = var_124_15,
				to = var_124_14,
				w = var_124_0[iter_124_17].w,
				h = var_124_1,
				img = var_124_0[iter_124_17].img
			}
		end
	end

	return var_124_42
end

var_0_0.sectionTitlePlaces = var_0_141

local function var_0_142(arg_130_0, arg_130_1)
	if not arg_130_0.near then
		return false
	end

	return not arg_130_0.far or arg_130_1 >= math.sqrt(arg_130_0.from * arg_130_0.to)
end

local function var_0_143(arg_131_0, arg_131_1, arg_131_2, arg_131_3, arg_131_4)
	local function var_131_0(arg_132_0, arg_132_1, arg_132_2, arg_132_3)
		return arg_131_0 < arg_132_0 + arg_132_2 and arg_132_0 < arg_131_0 + arg_131_2 and arg_131_1 < arg_132_1 + arg_132_3 and arg_132_1 < arg_131_1 + arg_131_3
	end

	for iter_131_0, iter_131_1 in ipairs(var_0_134) do
		if var_131_0(iter_131_1[1], iter_131_1[2], iter_131_1[3], iter_131_1[4]) then
			return true
		end
	end

	local var_131_1 = arg_131_4 == "ko" and var_0_132 or var_0_133

	return var_131_0(var_131_1, var_0_135, 640 - var_131_1, var_0_136)
end

var_0_0.sectionTitleUnderHud = var_0_143

function var_0_0.sectionTitleLayout(arg_133_0, arg_133_1, arg_133_2, arg_133_3)
	local var_133_0 = var_0_141(arg_133_0, arg_133_2, arg_133_3)

	if not var_133_0 then
		return nil
	end

	local var_133_1 = {}

	for iter_133_0, iter_133_1 in ipairs(var_0_122) do
		local var_133_2 = var_133_0[iter_133_1]

		if var_133_2 then
			local var_133_3 = var_0_142(var_133_2, arg_133_1)
			local var_133_4 = var_133_3 and var_133_2.near or var_133_2.far

			var_133_1[iter_133_1] = {
				x = math.floor(var_133_4.x * arg_133_1 - var_133_2.w / 2 + 0.5),
				y = math.floor(var_133_4.y * arg_133_1 - var_133_2.h / 2 + 0.5),
				w = var_133_2.w,
				h = var_133_2.h,
				close = var_133_3,
				nearFrom = var_133_2.to,
				hasClose = var_133_2.near ~= nil
			}
		end
	end

	return var_133_1
end

local function var_0_144(arg_134_0, arg_134_1, arg_134_2, arg_134_3, arg_134_4)
	if not arg_134_1 then
		arg_134_0.a, arg_134_0.x = 0

		return
	end

	if not arg_134_0.x or arg_134_4.snap then
		arg_134_0.x, arg_134_0.y = arg_134_1.x, arg_134_1.y
	else
		local var_134_0 = arg_134_1.x - arg_134_0.x
		local var_134_1 = arg_134_1.y - arg_134_0.y

		if var_134_0 * var_134_0 + var_134_1 * var_134_1 > 0.25 then
			arg_134_0.x, arg_134_0.y = arg_134_0.x + var_134_0 * arg_134_4.ease, arg_134_0.y + var_134_1 * arg_134_4.ease
		else
			arg_134_0.x, arg_134_0.y = arg_134_1.x, arg_134_1.y
		end
	end

	local var_134_2 = arg_134_4.rootX + arg_134_0.x * arg_134_4.zoom - arg_134_3.w / 2
	local var_134_3 = arg_134_4.rootY + arg_134_0.y * arg_134_4.zoom - arg_134_3.h / 2
	local var_134_4 = arg_134_2 and not var_0_143(var_134_2, var_134_3, arg_134_3.w, arg_134_3.h, arg_134_4.lang) and 1 or 0

	if arg_134_4.snap then
		arg_134_0.a = var_134_4
	elseif var_134_4 > arg_134_0.a then
		arg_134_0.a = math.min(var_134_4, arg_134_0.a + arg_134_4.fade)
	else
		arg_134_0.a = math.max(var_134_4, arg_134_0.a - arg_134_4.fade)
	end

	if arg_134_0.a > 0 then
		love.graphics.setColor(1, 1, 1, arg_134_0.a)
		love.graphics.draw(arg_134_3.img, math.floor(var_134_2 * arg_134_4.device + 0.5) / arg_134_4.device, math.floor(var_134_3 * arg_134_4.device + 0.5) / arg_134_4.device)
	end
end

local var_0_145 = {}
local var_0_146 = {}
local var_0_147 = {}
local var_0_148 = -1
local var_0_149
local var_0_150 = {}

function var_0_0.drawSectionTitles(arg_135_0, arg_135_1, arg_135_2, arg_135_3)
	local var_135_0 = arg_135_0 and arg_135_0.menuSettings and arg_135_0.menuSettings.language or "ko"
	local var_135_1 = 0
	local var_135_2 = 0

	for iter_135_0 in pairs(var_0_62) do
		local var_135_3 = arg_135_1[iter_135_0]

		if var_135_3 then
			var_135_1, var_135_2 = var_135_1 + 1, var_135_2 + math.floor(var_135_3.x) * 3 + math.floor(var_135_3.y) * 7
		end
	end

	if var_135_1 ~= var_0_146.count or var_135_2 ~= var_0_146.sum or var_135_0 ~= var_0_146.lang then
		for iter_135_1 in pairs(var_0_145) do
			var_0_145[iter_135_1] = nil
		end

		for iter_135_2 in pairs(var_0_62) do
			local var_135_4 = arg_135_1[iter_135_2]

			if var_135_4 then
				var_0_145[iter_135_2] = {
					x = var_135_4.x - arg_135_2 / 2,
					y = var_135_4.y - arg_135_3 / 2
				}
			end
		end

		var_0_146.count, var_0_146.sum, var_0_146.lang = var_135_1, var_135_2, var_135_0
		var_0_146.places = next(var_0_145) and var_0_141(var_0_145, var_135_0, arg_135_2) or nil
	end

	local var_135_5 = var_0_146.places

	if not var_135_5 then
		return
	end

	local var_135_6 = love.timer.getTime()
	local var_135_7 = love.timer.getDelta()
	local var_135_8 = love.graphics.transformPoint(0, 0)
	local var_135_9 = love.graphics.transformPoint(1, 0)

	var_0_150.snap = var_135_6 - var_0_148 > 0.25 or var_135_0 ~= var_0_149
	var_0_148, var_0_149 = var_135_6, var_135_0
	var_0_150.device = math.max(1, var_135_9 - var_135_8)
	var_0_150.ease = 1 - math.exp(-var_135_7 * 14)
	var_0_150.fade = var_135_7 * var_0_137
	var_0_150.zoom, var_0_150.lang = var_0_46, var_135_0
	var_0_150.rootX, var_0_150.rootY = arg_135_2 / 2 + var_0_44, arg_135_3 / 2 + var_0_45

	for iter_135_3, iter_135_4 in ipairs(var_0_122) do
		local var_135_10 = var_135_5[iter_135_4]

		if not not var_135_10 then
			local var_135_11 = var_0_147[iter_135_4]

			if not var_135_11 then
				var_135_11 = {
					close = {
						a = 0
					},
					wide = {
						a = 0
					}
				}
				var_0_147[iter_135_4] = var_135_11
			end

			local var_135_12 = var_0_142(var_135_10, var_0_46)

			var_0_144(var_135_11.close, var_135_10.near, var_135_12, var_135_10, var_0_150)
			var_0_144(var_135_11.wide, var_135_10.far, not var_135_12, var_135_10, var_0_150)
		else
			var_0_147[iter_135_4] = nil
		end
	end

	love.graphics.setColor(1, 1, 1, 1)
end

function var_0_0.isUnlockNodeOwned(arg_136_0, arg_136_1)
	local var_136_0 = var_0_0._unlockNodeFor and var_0_0._unlockNodeFor[arg_136_0]
	local var_136_1 = var_136_0 and var_136_0[tostring(arg_136_1)]

	return var_136_1 ~= nil and var_0_91[var_136_1] ~= nil and var_0_91[var_136_1].maxed == true
end

function var_0_0.dropLevelTag(arg_137_0)
	return (tostring(arg_137_0 or ""):gsub("%s*%([^%s%d%(%)%.]+%.?%s*%d+%)%s*$", ""))
end

function var_0_0.coreMachineLabel(arg_138_0, arg_138_1)
	if not arg_138_0 then
		return nil
	end

	local var_138_0, var_138_1 = pcall(require, "src.game.machines")

	if not var_138_0 or not var_138_1.coreMachine then
		return nil
	end

	local var_138_2, var_138_3 = pcall(require, "src.game.cores")
	local var_138_4 = var_138_2 and var_138_3.getById and var_138_3.getById(arg_138_0) or {
		key = arg_138_0
	}
	local var_138_5 = var_138_1.coreMachine(var_138_4)

	if var_138_5 == "nudge" or var_138_5 == "blast" then
		return var_0_3.getText("collection_core_" .. var_138_5 .. "_only", arg_138_1), var_138_5
	end

	return nil
end

function var_0_0.unlockSectionText(arg_139_0, arg_139_1)
	if not arg_139_0 then
		return nil
	end

	if arg_139_0.unlockCoreKey then
		local var_139_0, var_139_1 = var_0_0.coreMachineLabel(arg_139_0.unlockCoreKey, arg_139_1)

		return var_0_3.getText("upgrade_unlock_label", arg_139_1), var_0_3.getText("core.name." .. arg_139_0.unlockCoreKey, arg_139_1), var_0_3.formatCoreDesc(arg_139_0.unlockCoreKey, var_0_3.getText("core.desc." .. arg_139_0.unlockCoreKey, arg_139_1)), var_139_0, var_139_1
	end

	local var_139_2 = arg_139_0.unlockSection

	if not var_139_2 then
		return nil
	end

	local var_139_3 = var_0_3.getText(var_139_2.descKey, arg_139_1)

	if arg_139_0.unlock and arg_139_0.unlock.kind == "core" then
		var_139_3 = var_0_3.formatCoreDesc(arg_139_0.unlock.key, var_139_3)
	end

	if var_139_2.dropLevel then
		var_139_3 = var_0_0.dropLevelTag(var_139_3)
	end

	local var_139_4
	local var_139_5

	if arg_139_0.unlock and arg_139_0.unlock.kind == "core" then
		var_139_4, var_139_5 = var_0_0.coreMachineLabel(arg_139_0.unlock.key, arg_139_1)
	end

	return var_0_3.getText(var_139_2.labelKey, arg_139_1), var_0_3.getText(var_139_2.nameKey, arg_139_1), var_139_3, var_139_4, var_139_5
end

function var_0_0.isBlastMachineUnlocked()
	return var_0_0.isContentUnlocked("machine", "blast")
end

function var_0_0.isBlastMachineOffered()
	return var_0_91.blastmachine ~= nil and var_0_91.blastmachine.maxed ~= true and var_0_102("blastmachine") == true
end

function var_0_0.migrateLegacyTree()
	if var_0_0._legacyTreeState ~= true then
		return 0
	end

	var_0_0._legacyTreeState = false

	local var_142_0, var_142_1 = pcall(require, "src.game.discovery")

	if not var_142_0 or not var_142_1 or not var_142_1.seen then
		return 0
	end

	local var_142_2 = 0

	for iter_142_0, iter_142_1 in ipairs(var_0_0._demoCoreNodes or {}) do
		local var_142_3 = var_0_91[iter_142_1]
		local var_142_4 = var_142_3 and var_142_3.unlock

		if var_142_4 and not var_142_3.maxed and (var_142_1.seen("cores", var_142_4.key) or var_142_1.seen("cores", var_142_4.id)) then
			var_142_3.maxed = true
			var_142_2 = var_142_2 + 1
		end
	end

	if var_142_2 > 0 then
		for iter_142_2, iter_142_3 in pairs(var_0_91) do
			if iter_142_3.parent and iter_142_3.maxed then
				local var_142_5 = var_0_72(iter_142_2)

				var_142_5.revealed, var_142_5.unlockLineProgress, var_142_5.scaleX, var_142_5.scaleY = true, 1, 1, 1
			end
		end
	end

	return var_142_2
end

local function var_0_151(arg_143_0)
	return var_0_91[arg_143_0] ~= nil and var_0_91[arg_143_0].maxed == true
end

function var_0_0.getStartEssenceBonus()
	return var_0_151("startessence") and 2 or 0
end

function var_0_0.getWinGoldBonus()
	return var_0_151("wingold") and 5 or 0
end

function var_0_0.getLastSpinDiscount()
	return var_0_151("lastspin") and 50 or 0
end

function var_0_0.getShopDiscountEnabled()
	return var_0_151("shopdiscount")
end

function var_0_0.getMercContractExtraUses()
	return var_0_151("mercextend") and 1 or 0
end

function var_0_0.getBlastMissDiscountEnabled()
	return var_0_151("blastmastery")
end

function var_0_0.getQuestRerollEnabled()
	return var_0_151("questreroll")
end

function var_0_0.isCodexUnlocked()
	return var_0_151("codex")
end

function var_0_0.isBattleSpeed3Unlocked()
	return var_0_151("battlespeed3")
end

function var_0_0.getCoreFavoriteSlots()
	return (var_0_151("corefav") and 1 or 0) + (var_0_151("corefav2") and 1 or 0)
end

function var_0_0.statKeyOf(arg_154_0, arg_154_1)
	if arg_154_0 == "corefav" or arg_154_0 == "corefav2" then
		return var_0_151(arg_154_0 == "corefav" and "corefav2" or "corefav") and "upgrade_corefav2_stat" or "upgrade_corefav_stat"
	end

	return arg_154_1 and arg_154_1.statKey
end

function var_0_0.getCoreFavorites()
	local var_155_0 = {}
	local var_155_1 = var_0_0.getCoreFavoriteSlots()

	for iter_155_0 = 1, var_155_1 do
		var_155_0[iter_155_0] = var_0_0._coreFav and var_0_0._coreFav[iter_155_0] or false
	end

	return var_155_0
end

function var_0_0.setCoreFavorite(arg_156_0, arg_156_1)
	arg_156_0 = math.floor(tonumber(arg_156_0) or 0)

	if arg_156_0 < 1 or arg_156_0 > var_0_0.getCoreFavoriteSlots() then
		return false
	end

	var_0_0._coreFav = var_0_0._coreFav or {}
	var_0_0._coreFavOff = var_0_0._coreFavOff or {}

	local var_156_0 = var_0_0._coreFav[arg_156_0]
	local var_156_1 = var_0_0._coreFavOff[arg_156_0]

	if arg_156_1 then
		for iter_156_0 = 1, 2 do
			if iter_156_0 ~= arg_156_0 and var_0_0._coreFav[iter_156_0] == arg_156_1 then
				var_0_0._coreFav[iter_156_0], var_0_0._coreFavOff[iter_156_0] = var_156_0, var_156_0 and var_156_1 or nil
			end
		end
	end

	var_0_0._coreFav[arg_156_0] = arg_156_1 or nil
	var_0_0._coreFavOff[arg_156_0] = nil

	return true
end

function var_0_0.isCoreFavoriteOn(arg_157_0)
	return not var_0_0._coreFavOff or not var_0_0._coreFavOff[arg_157_0]
end

function var_0_0.setCoreFavoriteOn(arg_158_0, arg_158_1)
	arg_158_0 = math.floor(tonumber(arg_158_0) or 0)

	if arg_158_0 < 1 or arg_158_0 > var_0_0.getCoreFavoriteSlots() or not var_0_0._coreFav or not var_0_0._coreFav[arg_158_0] then
		return false
	end

	var_0_0._coreFavOff = var_0_0._coreFavOff or {}
	var_0_0._coreFavOff[arg_158_0] = not arg_158_1 or nil

	return true
end

function var_0_0.fillNewCoreFavorite()
	local var_159_0 = var_0_0.getCoreFavoriteSlots()
	local var_159_1 = var_0_0.getCoreFavorites()

	if var_159_0 < 1 or var_159_1[var_159_0] then
		return false
	end

	local var_159_2 = {}
	local var_159_3 = {}

	for iter_159_0, iter_159_1 in ipairs(var_159_1) do
		if iter_159_1 then
			var_159_2[iter_159_1] = true
		end
	end

	for iter_159_2, iter_159_3 in ipairs(require("src.game.cores").favoriteCandidates()) do
		if not var_159_2[iter_159_3.key] then
			var_159_3[#var_159_3 + 1] = iter_159_3.key
		end
	end

	if not var_159_3[1] then
		return false
	end

	return var_0_0.setCoreFavorite(var_159_0, var_159_3[love.math.random(#var_159_3)])
end

function var_0_0.getActiveCoreFavorites()
	local var_160_0 = {}

	for iter_160_0, iter_160_1 in ipairs(var_0_0.getCoreFavorites()) do
		if iter_160_1 and var_0_0.isCoreFavoriteOn(iter_160_0) then
			var_160_0[#var_160_0 + 1] = iter_160_1
		end
	end

	return var_160_0
end

function var_0_0.getStoneStandSlots()
	if not var_0_151("stoneshop") then
		return 0
	end

	return var_0_151("stoneshop2") and 4 or 3
end

function var_0_0.getStandRoll()
	return var_0_0._standRoll or 0
end

function var_0_0.bumpStandRoll()
	var_0_0._standRoll = (var_0_0._standRoll or 0) + 1
end

function var_0_0.isStandSold()
	return var_0_0._standSold == true
end

function var_0_0.setStandSold(arg_165_0)
	var_0_0._standSold = arg_165_0 and true or nil
end

function var_0_0.getStandCarry()
	local var_166_0 = {}

	for iter_166_0, iter_166_1 in ipairs(var_0_0._standCarry or {}) do
		var_166_0[iter_166_0] = iter_166_1
	end

	return var_166_0
end

function var_0_0.setStandCarry(arg_167_0)
	local var_167_0 = {}

	for iter_167_0, iter_167_1 in ipairs(type(arg_167_0) == "table" and arg_167_0 or {}) do
		if type(iter_167_1) == "string" then
			var_167_0[#var_167_0 + 1] = iter_167_1
		end
	end

	var_0_0._standCarry = #var_167_0 > 0 and var_167_0 or nil
end

local var_0_152 = {
	2,
	3,
	4,
	6,
	9,
	13
}
local var_0_153 = {
	"slotodds",
	"maxunit",
	"maxhp",
	"slotadvanced",
	"slotnudge",
	"startgold",
	"shopreroll",
	"corereroll",
	"slotadvanced2",
	"factionsynergy",
	"slotadvanced3",
	"maxunit2",
	"blastmachine",
	"slotrare",
	"maxunit3",
	"slotlegend",
	"slotprism",
	"fatestone",
	"stoneshop"
}

function var_0_0.devFirstClearBudget(arg_168_0)
	local var_168_0 = 0

	for iter_168_0 = 1, math.min(#var_0_152, (tonumber(arg_168_0) or 1) - 1) do
		var_168_0 = var_168_0 + 2 * var_0_152[iter_168_0] * 23
	end

	return var_168_0
end

function var_0_0.devPreset(arg_169_0, arg_169_1)
	for iter_169_0, iter_169_1 in pairs(var_0_91) do
		iter_169_1.maxed = false
	end

	local var_169_0 = arg_169_1 == "full"
	local var_169_1 = var_169_0 and math.huge or var_0_0.devFirstClearBudget(arg_169_0)
	local var_169_2 = 0
	local var_169_3 = 0

	local function var_169_4(arg_170_0)
		local var_170_0 = var_0_91[arg_170_0]
		local var_170_1 = var_170_0 and tonumber(var_170_0.cost) or 0

		return var_170_0 ~= nil and not var_170_0.maxed and var_170_1 > 0 and var_169_2 + var_170_1 <= var_169_1 and (arg_170_0 == "slotodds" or var_0_91.slotodds.maxed) and var_0_102(arg_170_0)
	end

	local function var_169_5(arg_171_0)
		var_0_91[arg_171_0].maxed = true
		var_169_2 = var_169_2 + var_0_91[arg_171_0].cost
		var_169_3 = var_169_3 + 1
	end

	local var_169_6 = true

	while var_169_6 do
		var_169_6 = false

		for iter_169_2, iter_169_3 in ipairs(var_0_153) do
			if var_169_4(iter_169_3) then
				var_169_5(iter_169_3)

				var_169_6 = true
			end
		end
	end

	while true do
		local var_169_7

		for iter_169_4, iter_169_5 in pairs(var_0_91) do
			if var_169_4(iter_169_4) and (not var_169_7 or iter_169_5.cost < var_0_91[var_169_7].cost or iter_169_5.cost == var_0_91[var_169_7].cost and iter_169_4 < var_169_7) then
				var_169_7 = iter_169_4
			end
		end

		if not var_169_7 then
			break
		end

		var_169_5(var_169_7)
	end

	var_0_0.setUpgradeState(var_0_0.getUpgradeState())

	return {
		bought = var_169_3,
		spent = var_169_2,
		budget = var_169_0 and var_169_2 or var_169_1,
		left = var_169_0 and 0 or var_169_1 - var_169_2
	}
end

function var_0_0.ownAll()
	for iter_172_0, iter_172_1 in pairs(var_0_91) do
		iter_172_1.maxed = true
	end

	var_0_0.setUpgradeState(var_0_0.getUpgradeState())
end

function var_0_0.getPadTargets()
	local var_173_0 = {}
	local var_173_1 = var_0_0.isSandboxActive() and var_0_70.unlockAll

	for iter_173_0, iter_173_1 in pairs(var_0_62) do
		local var_173_2 = var_0_52 / 2 + var_0_44 + (iter_173_1.x - var_0_52 / 2) * var_0_46
		local var_173_3 = var_0_53 / 2 + var_0_45 + (iter_173_1.y - var_0_53 / 2) * var_0_46
		local var_173_4 = iter_173_1.w * var_0_46
		local var_173_5 = iter_173_1.h * var_0_46
		local var_173_6 = var_173_2 + var_173_4 / 2
		local var_173_7 = var_173_3 + var_173_5 / 2

		if not (var_173_1 and var_173_6 >= var_173_1.x and var_173_6 < var_173_1.x + var_173_1.w and var_173_7 >= var_173_1.y and var_173_7 < var_173_1.y + var_173_1.h) and var_173_4 > 2 and var_173_5 > 2 and var_173_2 + var_173_4 > 0 and var_173_3 + var_173_5 > 0 and var_173_2 < var_0_52 and var_173_3 < var_0_53 then
			var_173_0[#var_173_0 + 1] = {
				id = iter_173_0,
				x = var_173_2,
				y = var_173_3,
				w = var_173_4,
				h = var_173_5
			}
		end
	end

	if var_0_0.isSandboxActive() and var_0_70.unlockAll then
		local var_173_8 = var_0_70.unlockAll

		var_173_0[#var_173_0 + 1] = {
			id = "sandbox_unlock_all",
			x = var_173_8.x,
			y = var_173_8.y,
			w = var_173_8.w,
			h = var_173_8.h
		}
	end

	local var_173_9 = var_0_25 and var_0_25.rect

	if var_173_9 then
		var_173_0[#var_173_0 + 1] = {
			id = "back",
			x = var_173_9.x,
			y = var_173_9.y,
			w = var_173_9.w,
			h = var_173_9.h
		}
	end

	return var_173_0
end

function var_0_0.setPadPan(arg_174_0, arg_174_1)
	var_0_0._padPanX = tonumber(arg_174_0) or 0
	var_0_0._padPanY = tonumber(arg_174_1) or 0
end

function var_0_0.getZoom()
	return var_0_46
end

-- 手游捏合：连续缩放（游戏自带 12 档离散缩放，这里改连续、0 延迟，锚点跟手指）
function var_0_0.pinchZoom(arg_200_0, arg_200_1, arg_200_2)
	local var_200_5 = tonumber(arg_200_0) or var_0_52 / 2
	local var_200_6 = tonumber(arg_200_1) or var_0_53 / 2
	local var_200_4 = math.max(0.3, math.min(1.2, tonumber(arg_200_2) or var_0_48))
	local var_200_7 = var_0_52 / 2 + (var_200_5 - var_0_52 / 2 - var_0_44) / var_0_46
	local var_200_8 = var_0_53 / 2 + (var_200_6 - var_0_53 / 2 - var_0_45) / var_0_46
	var_0_49 = var_200_5 - var_0_52 / 2 - (var_200_7 - var_0_52 / 2) * var_200_4
	var_0_50 = var_200_6 - var_0_53 / 2 - (var_200_8 - var_0_53 / 2) * var_200_4
	var_0_49, var_0_50 = var_0_66(var_0_49, var_0_50, var_200_4)
	var_0_44, var_0_45 = var_0_49, var_0_50
	var_0_46 = var_200_4
	var_0_48 = var_200_4
	var_0_51 = false
	return true
end

-- 手游单指拖动：1:1 平移（增量，虚拟坐标位移）
function var_0_0.dragPan(arg_201_0, arg_201_1)
	local var_201_0 = tonumber(arg_201_0) or 0
	local var_201_1 = tonumber(arg_201_1) or 0
	var_0_44, var_0_45 = var_0_68(var_0_44, var_0_45, var_201_0, var_201_1, var_0_46)
	var_0_49, var_0_50 = var_0_44, var_0_45
	var_0_51 = false
	return true
end

return var_0_0
