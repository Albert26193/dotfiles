-- 将当前窗口移动到指定 macOS Mission Control Desktop（Space）
-- 热键：⌥⌘ + 1..9 / 0  →  Desktop 1..9 / 10（在按键抬起时触发）
--
-- 背景：macOS Sequoia 上 hs.spaces.moveWindowToSpace 常返回 true 却不搬窗。
-- 因此采用系统原生路径：按住标题栏 + 系统「切换 Desktop」快捷键。
-- 你的系统切桌面是 ⌥N（不是默认的 ⌃N）。

local spaces = require("hs.spaces")
local hotkey = hs.hotkey
local eventtap = hs.eventtap
local timer = hs.timer

-----------------------------------------------------------------
-- 配置
-----------------------------------------------------------------
-- true  = 搬完后停留在目标 Desktop（跟随窗口）
-- false = 搬完后回到原来的 Desktop（窗口留在目标）
local FOLLOW = true

-- 成功/失败弹提示（建议先开着，确认可用后再关）
local SHOW_ALERT = true

-- 系统「切换到 Desktop N」的修饰键（你当前是 alt / option）
local SWITCH_MODS = { "alt" }

-- 鼠标按下后稍等再发切桌面键（秒）
-- 不可为 0：过快松手/抢焦点会导致窗口被「带不走」或弹回原 Desktop
local PRESS_DELAY = 0.05

-- 等待系统完成切桌面的最长时间（秒）
local SWITCH_TIMEOUT = 1.2

-----------------------------------------------------------------
-- 工具
-----------------------------------------------------------------
local function notify(msg)
	print("[move-to-space] " .. msg)
	if SHOW_ALERT then
		hs.alert.show(msg, 0.9)
	end
end

--- Desktop 编号对应的系统快捷键字符（1..9 / 0）
local function desktopKey(desktopIndex)
	if desktopIndex >= 1 and desktopIndex <= 9 then
		return tostring(desktopIndex)
	elseif desktopIndex == 10 then
		return "0"
	end
	return nil
end

--- 当前屏上的 user Space 列表（Mission Control 从左到右）
local function userSpacesOnScreen(screen)
	local uuid = screen:getUUID()
	local all = spaces.allSpaces() or {}
	local list = all[uuid] or spaces.spacesForScreen(screen) or {}
	local out = {}
	for _, spaceID in ipairs(list) do
		if spaces.spaceType(spaceID) == "user" then
			out[#out + 1] = spaceID
		end
	end
	return out
end

local function indexOf(list, value)
	for i, v in ipairs(list) do
		if v == value then
			return i
		end
	end
	return nil
end

local function getMovableFocusedWindow()
	local win = hs.window.focusedWindow()
	if not win then
		return nil, "没有焦点窗口"
	end
	if not win:isStandard() then
		return nil, "当前窗口不是标准窗口"
	end
	if win:isFullScreen() then
		return nil, "全屏窗口不支持移动到其他 Desktop"
	end
	return win, nil
end

--- 标题栏上一个安全的按下点（靠近缩放按钮内侧，避开按钮本身）
local function titlebarClickPoint(win)
	local zoom = win:zoomButtonRect()
	if not zoom then
		-- 退化：窗口顶部中央
		local f = win:frame()
		return { x = f.x + f.w / 2, y = f.y + 8 }
	end

	local pt = {
		x = zoom.x + zoom.w + 6,
		y = zoom.y + zoom.h / 2,
	}

	-- Chrome 一类 UI 标题栏更靠上
	local appName = win:application() and win:application():name() or ""
	if appName == "Google Chrome" or appName == "Chromium" or appName == "Microsoft Edge" then
		pt.y = zoom.y - 2
	end

	return pt
end

-----------------------------------------------------------------
-- 核心：按住标题栏 + ⌥N 搬窗
-----------------------------------------------------------------
local moving = false

local function moveFocusedWindowToDesktop(desktopIndex)
	if moving then
		return
	end

	local key = desktopKey(desktopIndex)
	if not key then
		notify("不支持的 Desktop 编号: " .. tostring(desktopIndex))
		return
	end

	local win, err = getMovableFocusedWindow()
	if not win then
		notify(err)
		return
	end

	local screen = win:screen()
	local list = userSpacesOnScreen(screen)
	if desktopIndex < 1 or desktopIndex > #list then
		notify(string.format("Desktop %d 不存在（当前共 %d 个）", desktopIndex, #list))
		return
	end

	local targetSpace = list[desktopIndex]
	local originSpace = spaces.focusedSpace()
	local originIndex = indexOf(list, originSpace)

	-- 窗口已在目标 Space 且人就在该 Space
	local winSpaces = spaces.windowSpaces(win) or {}
	local alreadyThere = false
	for _, sid in ipairs(winSpaces) do
		if sid == targetSpace then
			alreadyThere = true
			break
		end
	end
	if alreadyThere and originSpace == targetSpace then
		notify(string.format("已在 Desktop %d", desktopIndex))
		return
	end

	moving = true
	local mousePos = hs.mouse.absolutePosition()
	local clickPoint = titlebarClickPoint(win)

	-- 先把鼠标移到标题栏并按下（系统会把窗口「粘」到拖拽状态）
	hs.mouse.absolutePosition(clickPoint)
	eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, clickPoint):post()

	timer.doAfter(PRESS_DELAY, function()
		-- 系统快捷键：⌥N 切换到 Desktop N；按住窗口时会带走窗口
		eventtap.keyStroke(SWITCH_MODS, key, 0)

		local deadline = hs.timer.secondsSinceEpoch() + SWITCH_TIMEOUT
		timer.waitUntil(
			function()
				-- 焦点 Space 到了目标，或窗口已经出现在目标 Space
				if spaces.focusedSpace() == targetSpace then
					return true
				end
				local ws = spaces.windowSpaces(win) or {}
				for _, sid in ipairs(ws) do
					if sid == targetSpace then
						return true
					end
				end
				return hs.timer.secondsSinceEpoch() > deadline
			end,
			function()
				eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, clickPoint):post()
				hs.mouse.absolutePosition(mousePos)

				local timedOut = spaces.focusedSpace() ~= targetSpace
				local ws = spaces.windowSpaces(win) or {}
				local moved = false
				for _, sid in ipairs(ws) do
					if sid == targetSpace then
						moved = true
						break
					end
				end

				if timedOut and not moved then
					moving = false
					notify("移动超时：请确认系统设置里已开启 ⌥" .. key .. " 切换 Desktop")
					return
				end

				local function finish(msg)
					moving = false
					notify(msg)
				end

				if FOLLOW or not originIndex or originIndex == desktopIndex then
					-- 留在目标 Desktop，尽量恢复焦点（需短延迟，等 Space 动画结束）
					timer.doAfter(0.15, function()
						if win:application() then
							win:focus()
						end
						finish(string.format("→ Desktop %d", desktopIndex))
					end)
					return
				end

				-- 不跟随：松手后再 ⌥原桌面 跳回去（此时不再按住窗口）
				timer.doAfter(0.12, function()
					local originKey = desktopKey(originIndex)
					if originKey then
						eventtap.keyStroke(SWITCH_MODS, originKey, 0)
					end
					timer.doAfter(0.2, function()
						finish(string.format("窗口 → Desktop %d（已回到原 Desktop）", desktopIndex))
					end)
				end)
			end,
			0.03
		)
	end)
end

-----------------------------------------------------------------
-- 热键：⌥⌘ + 数字（在 key-up 时触发，避免与模拟的 ⌥N 抢修饰键）
-----------------------------------------------------------------
local mods = { "alt", "cmd" }

for n = 1, 9 do
	hotkey.bind(mods, tostring(n), nil, function()
		moveFocusedWindowToDesktop(n)
	end)
end

hotkey.bind(mods, "0", nil, function()
	moveFocusedWindowToDesktop(10)
end)

print(
	"[init] move-to-space 已加载（⌥⌘+1..9/0 → 搬窗；系统切桌面=⌥N；FOLLOW="
		.. tostring(FOLLOW)
		.. "）"
)
