-- 最简窗口几何
--   ⌥⌘ + [ → 左侧循环：1/2 → 2/3 → 1/3 → …
--   ⌥⌘ + ] → 右侧循环：1/2 → 2/3 → 1/3 → …
--   ⌥⌘ + H → 聚焦左半边的窗口（最靠前的一扇）
--   ⌥⌘ + L → 聚焦右半边的窗口（最靠前的一扇）
--   ⌥⌘ + M → 最大化（铺满当前屏的可用区域）
--   ⌥⌘ + J → 焦点主左 + 其它叠右；主区循环 1/2 → 2/3 → 1/3（对侧为剩余宽度）
--   ⌥⌘ + K → 焦点主右 + 其它叠左；同上

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

--- mainSide: "left" | "right"
--- 焦点占该侧 frac（循环 1/2→2/3→1/3）；其它窗全部叠在对侧剩余宽度（彼此交叠）
local function mainSideOthersStackCycle(mainSide)
	local main = focusedStandardWindow()
	if not main or main:isFullScreen() then
		return
	end

	local frac = FRACTIONS[nextFractionIndex(main, mainSide)]
	local sf = main:screen():frame()
	local otherSide = mainSide == "left" and "right" or "left"
	local mainFrame = sideFractionFrame(sf, mainSide, frac)
	local otherFrame = sideFractionFrame(sf, otherSide, 1 - frac)

	-- 先摆从窗（交叠），再摆主窗并 focus，保证主窗在前
	for _, win in ipairs(siblingWindows(main)) do
		win:setFrame(otherFrame, 0)
	end
	main:setFrame(mainFrame, 0)
	main:focus()
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
	mainSideOthersStackCycle("left")
end)

hotkey.bind(mods, "k", function()
	mainSideOthersStackCycle("right")
end)

print(
	"[init] window-layout 已加载（⌥⌘+[/] 左右循环；⌥⌘+H/L 聚焦半窗；⌥⌘+M 最大化；⌥⌘+J/K 主从叠对侧 1/2→2/3→1/3）"
)
