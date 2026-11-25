-- 最简窗口几何
--   ⌥⌘ + [ → 左侧循环：1/2 → 2/3 → 1/3 → …
--   ⌥⌘ + ] → 右侧循环：1/2 → 2/3 → 1/3 → …
--   ⌥⌘ + H → 聚焦左半边的窗口（最靠前的一扇）
--   ⌥⌘ + L → 聚焦右半边的窗口（最靠前的一扇）
--   ⌥⌘ + M → 最大化（铺满当前屏的可用区域）
--   ⌥⌘ + J → 左区宽度循环 1/2 → 2/3 → 1/3；左半边的窗叠左区，右半边的窗叠右区（剩余宽度）
--   ⌥⌘ + K → 右区宽度循环 1/2 → 2/3 → 1/3；同上
--   ⌥⌘ + Enter → 左右区窗口互换，并各占 1/2

local spaces = require("hs.spaces")
local hotkey = hs.hotkey

local mods = { "alt", "cmd" }

-- 循环顺序：半屏 → 更宽 → 更窄
local FRACTIONS = { 1 / 2, 2 / 3, 1 / 3 }
local TOL = 0.06 -- 判定「当前已是某档」时的宽度容差（相对屏宽）

local function focusedStandardWindow()
	local win = hs.window.focusedWindow()
	if not win or not win:isStandard() then
		return nil
	end
	return win
end

--- 当前窗口若已贴在该侧某一档，返回档位下标；否则 nil
local function currentFractionIndex(win, side)
	local sf = win:screen():frame()
	local wf = win:frame()
	local ratio = wf.w / sf.w
	local edgeTol = sf.w * TOL

	for i, frac in ipairs(FRACTIONS) do
		if math.abs(ratio - frac) <= TOL then
			if side == "left" and math.abs(wf.x - sf.x) <= edgeTol then
				return i
			end
			if side == "right" and math.abs((wf.x + wf.w) - (sf.x + sf.w)) <= edgeTol then
				return i
			end
		end
	end
	return nil
end

local function nextFractionIndex(win, side)
	local cur = currentFractionIndex(win, side)
	if not cur then
		return 1
	end
	return (cur % #FRACTIONS) + 1
end

--- 贴某侧、占屏宽 frac 的矩形
local function sideFractionFrame(screenFrame, side, frac)
	local w = screenFrame.w * frac
	local frame = {
		x = screenFrame.x,
		y = screenFrame.y,
		w = w,
		h = screenFrame.h,
	}
	if side == "right" then
		frame.x = screenFrame.x + screenFrame.w - w
	end
	return frame
end

local function resizeToSideFraction(side, frac)
	local win = focusedStandardWindow()
	if not win then
		return
	end

	local sf = win:screen():frame()
	local w = sf.w * frac
	local frame = {
		x = sf.x,
		y = sf.y,
		w = w,
		h = sf.h,
	}
	if side == "right" then
		frame.x = sf.x + sf.w - w
	end
	-- 第 2 参为动画时长（秒）；0 = 立即到位，避免循环连按时「拖泥带水」
	win:setFrame(frame, 0)
end

local function cycleSide(side)
	local win = focusedStandardWindow()
	if not win then
		return
	end
	local idx = nextFractionIndex(win, side)
	resizeToSideFraction(side, FRACTIONS[idx])
end

local function maximizeFocused()
	local win = focusedStandardWindow()
	if not win then
		return
	end
	-- 铺满 screen:frame()（不含菜单栏/Dock 占用区）
	win:setFrame(win:screen():frame(), 0)
end

local function windowOnSpace(win, spaceID)
	local ws = spaces.windowSpaces(win) or {}
	for _, sid in ipairs(ws) do
		if sid == spaceID then
			return true
		end
	end
	return false
end

--- 同屏、同 Space、可布局的其它标准窗（与焦点交叠堆到对侧）
local function siblingWindows(main)
	local screen = main:screen()
	local spaceID = spaces.focusedSpace()
	local mainID = main:id()
	local out = {}

	for _, win in ipairs(hs.window.allWindows()) do
		if win:id() ~= mainID
			and win:isStandard()
			and win:isVisible()
			and not win:isFullScreen()
			and not win:isMinimized()
			and win:screen() and win:screen():id() == screen:id()
			and windowOnSpace(win, spaceID)
		then
			out[#out + 1] = win
		end
	end
	return out
end

--- 归属半边：窗口中心与屏中心比较；中心在屏中心附近（≈铺满）返回 nil
local function windowHalf(win)
	local sf = win:screen():frame()
	local wf = win:frame()
	local cx = wf.x + wf.w / 2
	local mid = sf.x + sf.w / 2
	if cx < mid - 1 then
		return "left"
	end
	if cx > mid + 1 then
		return "right"
	end
	return nil
end

--- 焦点及同屏同 Space 窗按中心归左右区；居中（≈铺满）的窗：焦点归 focusFallback，其它归 otherFallback（nil = 不参与）
local function groupByHalf(focus, focusFallback, otherFallback)
	local groups = { left = {}, right = {} }
	local function assign(win, fallback)
		local half = windowHalf(win) or fallback
		if half then
			groups[half][#groups[half] + 1] = win
		end
	end
	assign(focus, focusFallback)
	for _, win in ipairs(siblingWindows(focus)) do
		assign(win, otherFallback)
	end
	return groups
end

--- side: "left" | "right"，该侧区域宽度循环 1/2→2/3→1/3，对侧占剩余宽度
--- 按窗口中心归左右区；居中（≈铺满）的窗：焦点归 side，其它归对侧
local function splitCycle(side)
	local focus = focusedStandardWindow()
	if not focus or focus:isFullScreen() then
		return
	end

	local otherSide = side == "left" and "right" or "left"
	local groups = groupByHalf(focus, side, otherSide)

	-- 档位以该侧已贴边的窗判定；都不在档上则从 1/2 开始
	local idx = 1
	for _, win in ipairs(groups[side]) do
		if currentFractionIndex(win, side) then
			idx = nextFractionIndex(win, side)
			break
		end
	end
	local frac = FRACTIONS[idx]
	local sf = focus:screen():frame()
	local frames = {
		[side] = sideFractionFrame(sf, side, frac),
		[otherSide] = sideFractionFrame(sf, otherSide, 1 - frac),
	}

	for half, wins in pairs(groups) do
		for _, win in ipairs(wins) do
			win:setFrame(frames[half], 0)
		end
	end
	focus:focus()
end

--- 左右区窗口互换并均分；居中（≈铺满）的窗不动
local function swapHalves()
	local focus = focusedStandardWindow()
	if not focus or focus:isFullScreen() then
		return
	end

	local groups = groupByHalf(focus, nil, nil)
	local sf = focus:screen():frame()
	local frames = {
		left = sideFractionFrame(sf, "right", 1 / 2),
		right = sideFractionFrame(sf, "left", 1 / 2),
	}
	for half, wins in pairs(groups) do
		for _, win in ipairs(wins) do
			win:setFrame(frames[half], 0)
		end
	end
	focus:focus()
end

--- 同屏、同 Space、可布局、中心落在指定半边的标准窗
local function windowsInHalf(half)
	local focus = hs.window.focusedWindow()
	local screen = focus and focus:screen() or hs.mouse.getCurrentScreen()
	local spaceID = spaces.focusedSpace()
	local out = {}

	for _, win in ipairs(hs.window.allWindows()) do
		if win:isStandard()
			and win:isVisible()
			and not win:isFullScreen()
			and not win:isMinimized()
			and win:screen() and win:screen():id() == screen:id()
			and windowOnSpace(win, spaceID)
			and windowHalf(win) == half
		then
			out[#out + 1] = win
		end
	end
	return out
end

--- 聚焦指定半边「最靠前」的窗口；焦点已在该半边则无操作
local function focusSide(half)
	local cands = windowsInHalf(half)
	if #cands == 0 then
		return
	end

	local index = {}
	for i, w in ipairs(hs.window.orderedWindows()) do
		index[w:id()] = i
	end

	local best, bestIdx = nil, math.huge
	for _, win in ipairs(cands) do
		local i = index[win:id()]
		if i and i < bestIdx then
			bestIdx, best = i, win
		end
	end
	if best then
		best:focus()
	end
end

hotkey.bind(mods, "[", function()
	cycleSide("left")
end)

hotkey.bind(mods, "]", function()
	cycleSide("right")
end)

hotkey.bind(mods, "h", function()
	focusSide("left")
end)

hotkey.bind(mods, "l", function()
	focusSide("right")
end)

hotkey.bind(mods, "m", function()
	maximizeFocused()
end)

hotkey.bind(mods, "j", function()
	splitCycle("left")
end)

hotkey.bind(mods, "k", function()
	splitCycle("right")
end)

hotkey.bind(mods, "return", function()
	swapHalves()
end)

print(
	"[init] window-layout 已加载（⌥⌘+[/] 左右循环；⌥⌘+H/L 聚焦半窗；⌥⌘+M 最大化；⌥⌘+J/K 左区/右区 1/2→2/3→1/3；⌥⌘+Enter 左右互换均分）"
)
