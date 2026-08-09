-- Hammerspoon 脚本：Alt+M 切换 Alacritty，只在主显示器（拥有菜单栏的屏幕）右侧 1/3 区域出现
local spaces = require("hs.spaces")
local screen = require("hs.screen")
local app = hs.application
local hotkey = hs.hotkey
local eventtap = hs.eventtap
local console = hs.console   -- 用于彩色打印（可选）

local APP_NAME = "Alacritty" -- 目标应用名称

-----------------------------------------------------------------
-- 1️⃣ 把窗口强制放到 **主显示器** left 1/3 区域
-----------------------------------------------------------------
local function placeOnPrimaryScreen(win)
  if not win then
    return
  end

  local primaryScr = screen.primaryScreen() -- 主显示器（拥有菜单栏的那块屏幕）
  local scrFrm = primaryScr:frame()

  -- 屏幕 left 1/3 区域
  local newFrm = {
    x = scrFrm.x,
    y = scrFrm.y,
    w = scrFrm.w / 3,
    h = scrFrm.h,
  }

  win:setFrame(newFrm, 0) -- 立即生效
  win:focus()
  print("[placeOnPrimaryScreen] 窗口已放置于主显示器右侧 1/3，frame =", newFrm)
end

-----------------------------------------------------------------
-- 2️⃣ 将窗口搬到指定 Space（先确保在主显示器所在的 Space）
-----------------------------------------------------------------
local function moveWindowToSpace(win, targetSpace)
  if not win then
    return
  end

  local primaryScr = screen.primaryScreen()
  local curScreen = win:screen()

  -- 若窗口不在主显示器，则先搬过去
  if curScreen:id() ~= primaryScr:id() then
    local primarySpace = spaces.spaceForScreen(primaryScr)
    spaces.moveWindowToSpace(win, primarySpace)
    hs.timer.usleep(200000) -- 等待系统完成搬迁（0.2 秒，可酌情调大）
    print("[moveWindowToSpace] 窗口先搬到主显示器所在的 Space")
  end

  -- 再搬到目标 Space（仍然在主显示器上）
  spaces.moveWindowToSpace(win, targetSpace)
  print("[moveWindowToSpace] 窗口搬到目标 Space:", targetSpace)

  -- 最后确保位置、大小仍在主显示器
  placeOnPrimaryScreen(win)
end

-----------------------------------------------------------------
-- 3️⃣ 主热键：Alt+M
-----------------------------------------------------------------
hotkey.bind({ "alt" }, "m", function()
  local alacritty = app.get(APP_NAME)
  -- 已经在前台 → 隐藏
  if alacritty and alacritty:isFrontmost() then
    -- 1. 把 Alacritty 藏起来
    alacritty:hide()
    -- 2. 选择当前 Space 中的下一个可聚焦窗口（不是 Alacritty）
    hs.timer.doAfter(0.05, function()
      local wins = hs.window.orderedWindows() or {}
      for _, w in ipairs(wins) do
        local owner = w:application()
        -- 跳过 Alacritty 自己
        if owner and owner:name() ~= APP_NAME then
          -- 只要是标准窗口而且可见，就让它上来
          if w:isStandard() and w:isVisible() then
            w:focus()
            print(
              "[hotkey] Alacritty 隐藏 -> 焦点切到同一 Space 内窗口: "
              .. (owner:name() or "(unknown app)")
              .. " / "
              .. (w:title() or "(untitled)")
            )
            return
          end
        end
      end
      -- 如果这个 Space 里除了 Alacritty 没别的窗口（纯桌面）
      print("[hotkey] Alacritty 隐藏，但当前 Space 没有其他窗口可聚焦（停留在桌面）")
    end)
    return
  end

  -- 当前 Space（目标 Space）
  local curSpace = spaces.activeSpaceOnScreen()
  print("[hotkey] 当前 Space =", curSpace)

  -----------------------------------------------------------------
  -- 若 Alacritty 未运行 → 启动并监听 launch 事件
  -----------------------------------------------------------------
  if not alacritty then
    if not app.launchOrFocus(APP_NAME) then
      hs.alert.show("启动 " .. APP_NAME .. " 失败")
      return
    end

    local watcher = nil
    watcher = app.watcher.new(function(name, event, appObj)
      if event == app.watcher.launched and name == APP_NAME then
        appObj:hide() -- 先隐藏，防止闪现
        local win = appObj:mainWindow()
        if win then
          moveWindowToSpace(win, curSpace)
        end
        watcher:stop()
        print("[watcher] Alacritty 启动完成并已移动")
      end
    end)
    watcher:start()
    print("[hotkey] 已创建并启动 Alacritty 启动 watcher")
    return
  end

  -----------------------------------------------------------------
  -- 已经在运行 → 直接搬窗口
  -----------------------------------------------------------------
  local win = alacritty:mainWindow()
  if win then
    moveWindowToSpace(win, curSpace)
  else
    print("[hotkey] 未能获取 Alacritty 主窗口")
  end
end)

-----------------------------------------------------------------
-- 4️⃣ Space 变化监听：一旦切到别的 Space，就隐藏 Alacritty
-----------------------------------------------------------------
local alacrittySpaceWatcher = spaces.watcher.new(function()
  local alacritty = app.get(APP_NAME)
  if alacritty then
    alacritty:hide()
    print("[spaceWatcher] 检测到 Space 变化，已隐藏 Alacritty")
  end
end)
alacrittySpaceWatcher:start()
print("[init] Alacritty Space watcher 已启动")

-----------------------------------------------------------------
-- 5️⃣（可选）在 Space 变化时强制把 Alacritty 拉回主显示器
-----------------------------------------------------------------
-- 如果你希望即使在隐藏状态下也保证它仍然位于主显示器，
-- 可以在上面的 watcher 里再调用一次 placeOnPrimaryScreen：
--
-- local win = alacritty:mainWindow()
-- if win then placeOnPrimaryScreen(win) end
--
-----------------------------------------------------------------
hs.alert.show("Alacritty 脚本已加载（Alt+M）")
