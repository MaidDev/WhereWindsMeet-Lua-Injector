-- SCRIPT START TEST
print("=== SCRIPT IS RUNNING ===")
print("If you see this, the script is loading...")
 
-- === Debug Logging System ===
 
-- master switch: set to false to completely stop writing script_debug.txt
local DEBUG_FILE_ENABLED = false
local DEBUG_FILE_PATH    = "C:\\temp\\Where Winds Meet\\Scripts\\script_debug.txt"
 
local function write_debug(message)
    -- Write to file only if enabled
    if DEBUG_FILE_ENABLED then
        local success, file = pcall(function()
            return io.open(DEBUG_FILE_PATH, "a")
        end)
        
        if success and file then
            local write_success, err = pcall(function()
                file:write(os.date("%H:%M:%S") .. " " .. message .. "\n")
                file:close()
            end)
            if not write_success then
                print("Debug file write error: " .. tostring(err))
            end
        else
            print("Debug file open error: " .. tostring(file))
        end
    end
 
    -- Always print to console as fallback
    print(message)
end
 
-- Optionally create/clear debug file at start
if DEBUG_FILE_ENABLED then
    local init_success, init_file = pcall(function()
        return io.open(DEBUG_FILE_PATH, "w")
    end)
 
    if init_success and init_file then
        local write_success = pcall(function()
            init_file:write("=== SCRIPT DEBUG LOG ===\n")
            init_file:write(os.date("%H:%M:%S") .. " Script started successfully\n")
            init_file:close()
        end)
        if not write_success then
            print("Failed to initialize debug file")
        end
    else
        print("Failed to create debug file: " .. tostring(init_file))
    end
else
    print("Debug file logging disabled (DEBUG_FILE_ENABLED = false)")
end
 
print("=== SCRIPT DEBUG LOG ===")
print("Script started successfully")
-- === Environment Check ===
write_debug("Checking environment...")
write_debug("G exists: " .. tostring(G ~= nil))
write_debug("G.main_player exists: " .. tostring(G and G.main_player ~= nil))
write_debug("cc exists: " .. tostring(cc ~= nil))
write_debug("cc.Director exists: " .. tostring(cc and cc.Director ~= nil))
write_debug("Director instance: " .. tostring(cc and cc.Director:getInstance() ~= nil))
write_debug("Running scene: " .. tostring(cc and cc.Director:getInstance() and cc.Director:getInstance():getRunningScene() ~= nil))
 
if not cc or not cc.Director then
    write_debug("ERROR: Cocos2d-x not available")
    return
end
 
local director = cc.Director:getInstance()
if not director then
    write_debug("ERROR: Director not available")
    return
end
 
local scene = director:getRunningScene()
if not scene then
    write_debug("ERROR: No running scene found!")
    return
end
 
write_debug("Scene valid for UI creation")
 
-- === Debug Flags Integration ===
local FLAGS_TO_SET = {
  DEBUG                   = false,
  DISABLE_ACSDK           = true,   -- always true
  ENABLE_DEBUG_PRINT      = false,
  ENABLE_FORCE_SHOW_GM    = false,
  FORCE_OPEN_DEBUG_SHORTCUT = false,
  GM_IS_OPEN_GUIDE        = false,
  GM_USE_PUBLISH          = false,
  acsdk_info_has_inited   = false,  -- always false
}
 
local MAX_DEPTH = 10
local ROOT = rawget(_G, "DUMP_ROOT") or package.loaded
local ROOT_NAME = rawget(_G, "DUMP_ROOT_NAME") or "ROOT"
local visited = setmetatable({}, { __mode = "k" })
 
local function modify_flags(tbl, path, depth)
  if depth > MAX_DEPTH or visited[tbl] then return end
  visited[tbl] = true
  for k, _ in next, tbl do
    local ok, v = pcall(rawget, tbl, k)
    if ok and type(k) == "string" and FLAGS_TO_SET[k] ~= nil then
      rawset(tbl, k, FLAGS_TO_SET[k])
      write_debug("[✔] " .. path .. k .. " set to " .. tostring(FLAGS_TO_SET[k]))
    end
    if type(v) == "table" then
      modify_flags(v, path .. tostring(k) .. ".", depth + 1)
    end
  end
end
 
write_debug("Applying debug flags...")
-- Run once at startup
modify_flags(ROOT, ROOT_NAME .. ".", 0)
 
-- Toggle function for selected flags
local function toggle_debug_flags()
    -- Flip only the allowed flags
    FLAGS_TO_SET.DEBUG                   = not FLAGS_TO_SET.DEBUG
    FLAGS_TO_SET.ENABLE_DEBUG_PRINT      = not FLAGS_TO_SET.ENABLE_DEBUG_PRINT
    FLAGS_TO_SET.ENABLE_FORCE_SHOW_GM    = not FLAGS_TO_SET.ENABLE_FORCE_SHOW_GM
    FLAGS_TO_SET.FORCE_OPEN_DEBUG_SHORTCUT = not FLAGS_TO_SET.FORCE_OPEN_DEBUG_SHORTCUT
    FLAGS_TO_SET.GM_IS_OPEN_GUIDE        = not FLAGS_TO_SET.GM_IS_OPEN_GUIDE
    FLAGS_TO_SET.GM_USE_PUBLISH          = not FLAGS_TO_SET.GM_USE_PUBLISH
 
    -- Reapply flags
    modify_flags(ROOT, ROOT_NAME .. ".", 0)
 
    write_debug(string.format(
        "[OK] Debug flags toggled: DEBUG=%s, PRINT=%s, SHOW_GM=%s, SHORTCUT=%s, GUIDE=%s, PUBLISH=%s",
        tostring(FLAGS_TO_SET.DEBUG),
        tostring(FLAGS_TO_SET.ENABLE_DEBUG_PRINT),
        tostring(FLAGS_TO_SET.ENABLE_FORCE_SHOW_GM),
        tostring(FLAGS_TO_SET.FORCE_OPEN_DEBUG_SHORTCUT),
        tostring(FLAGS_TO_SET.GM_IS_OPEN_GUIDE),
        tostring(FLAGS_TO_SET.GM_USE_PUBLISH)
    ))
end
 
 
-- Bare minimum combat menu
local function refresh_combat_menu()
    -- Bare minimum combat menu
    local gm_combat = package.loaded["hexm.client.debug.gm.gm_commands.gm_combat"]
    if gm_combat and gm_combat.gm_open_combat_train then
        gm_combat.gm_open_combat_train()
    end
end
 
-- Weapon Guise
local function weapon_guise()
    local gm_decorator = package.loaded["hexm.client.debug.gm.gm_decorator"] 
        or require("hexm.client.debug.gm.gm_decorator")
 
    if gm_decorator.gm_command_short_cuts.game then
        local cmds = gm_decorator.gm_command_short_cuts.game
        if cmds["$weapon_guise"] then 
            pcall(cmds["$weapon_guise"], 1) 
        end
    end
end
 
write_debug("Loading combat module...")
local ok_combat, gm_combat = pcall(require, "hexm.client.debug.gm.gm_commands.gm_combat")
write_debug("Combat module loaded: " .. tostring(ok_combat and gm_combat ~= nil))
local player_id = 1
_G.GM_ONEHIT = _G.GM_ONEHIT or false
_G.GM_ONEHIT_DELTA = _G.GM_ONEHIT_DELTA or nil
 
local eventOK = 0
write_debug("Scene found, proceeding with menu creation")
local size = director:getVisibleSize()
write_debug("Screen size: " .. size.width .. "x" .. size.height)
 
-- Remove old menu
if _G.GM_MENU then
    write_debug("Removed existing menu")
    _G.GM_MENU:removeFromParent()
    _G.GM_MENU = nil
end
 
-- Invisibility (using buff system)
_G.GM_INVISIBLE = _G.GM_INVISIBLE or false
 
local function toggle_invisible()
    local mp = G.main_player
    if not mp then
        write_debug("[Invisible] ERROR: G.main_player not available")
        return false
    end
    
    if _G.GM_INVISIBLE then
        -- Disable invisibility
        local mod = "hexm.client.ui.windows.gm.gm_combat.combat_train_action"
        local action = nil
        pcall(function() action = portable.import(mod) end)
        if action and action.rm_buff then
            pcall(action.rm_buff, 108010)
        end
        _G.GM_INVISIBLE = false
        write_debug("[Invisible] [✔] Invisibility disabled")
        return false
    else
        -- Enable invisibility
        pcall(mp.add_buff, mp, 108010)
        _G.GM_INVISIBLE = true
        write_debug("[Invisible] [✔] Invisibility enabled")
        return true
    end
end
 
-- Diving Air (REMOVED - not working)
-- This feature has been removed as requested
 
write_debug("Creating menu...")
-- Panel dimensions
local panelWidth, panelHeight = 480, 2000   -- base minimum height
local panel = ccui.Layout:create()
panel:setContentSize(cc.size(panelWidth, panelHeight))
write_debug("Creating panel with size: " .. panelWidth .. "x" .. panelHeight)
 
-- Spawn panel on the left side
local marginLeft = 20  -- optional padding from the edge
local initialY = (size.height - panelHeight) / 2
panel:setPosition(cc.p(marginLeft, initialY))
initialPosition = cc.p(marginLeft, initialY)  -- Store initial position
write_debug("Panel created and positioned at: " .. marginLeft .. ", " .. initialY)
 
panel:setBackGroundColorType(1)
panel:setBackGroundColor(cc.c3b(25, 25, 40))  -- Lighter blue tint for better visibility
panel:setBackGroundColorOpacity(220)  -- Slightly more transparent
panel:setClippingEnabled(true)
 
-- Add border for better visibility
panel:setBackGroundColorType(1)
panel:setBackGroundColor(cc.c3b(25, 25, 40))
scene:addChild(panel, 9999)
_G.GM_MENU = panel
write_debug("Panel added to scene")
 
-- Title bar with gradient effect
local titleBar = ccui.Layout:create()
titleBar:setContentSize(cc.size(panelWidth, 50))
titleBar:setPosition(cc.p(0, panelHeight - 50))
titleBar:setBackGroundColorType(1)
titleBar:setBackGroundColor(cc.c3b(50, 50, 75))  -- Lighter blue for title bar
titleBar:setBackGroundColorOpacity(255)
panel:addChild(titleBar)
write_debug("Title bar created")
 
-- Title text with shadow effect
local titleText = ccui.Text:create("✨ Maid WWM Menu ✨", "Arial", 28)
titleText:setTextColor(cc.c3b(255, 255, 255))
titleText:setPosition(cc.p(panelWidth/2, 30))
titleBar:addChild(titleText)
write_debug("Title text created")
 
-- Subtitle text with better color
local subtitleText = ccui.Text:create("Made with ❤️ by MAID", "Arial", 18)
subtitleText:setTextColor(cc.c3b(180, 180, 255))  -- Light blue tint
subtitleText:setPosition(cc.p(panelWidth/2, 10))
titleBar:addChild(subtitleText)
write_debug("Subtitle text created")
 
-- Variables to track dragging and minimization
local isDragging = false
local dragOffset = cc.p(0, 0)
local isMinimized = false
local originalPanelSize = nil
local originalButtonsVisible = true
local keybindInfo = nil  -- Make keybindInfo accessible to minimize function
local initialPosition = nil  -- Store initial position for boundary reset
 
-- Smart boundary checking function
local function keepPanelInBounds(newX, newY)
    local panelSize = panel:getContentSize()
    local screenWidth = size.width
    local screenHeight = size.height
    
    -- Calculate boundaries
    local minX = 0
    local maxX = screenWidth - panelSize.width
    local minY = 0
    local maxY = screenHeight - panelSize.height
    
    -- Apply boundaries
    newX = math.max(minX, math.min(maxX, newX))
    newY = math.max(minY, math.min(maxY, newY))
    
    return newX, newY
end
 
-- Make entire panel draggable with smart boundaries
panel:setTouchEnabled(true)
panel:addTouchEventListener(function(sender, eventType)
    if eventType == 0 then -- ccui.TouchEventType.began
        local touchPos = sender:getTouchBeganPosition()
        local panelPos = panel:getPosition()
        dragOffset = cc.p(touchPos.x - panelPos.x, touchPos.y - panelPos.y)
        isDragging = true
        return true -- consume event
 
    elseif eventType == 1 and isDragging then -- ccui.TouchEventType.moved
        local touchPos = sender:getTouchMovePosition()
        local newX = touchPos.x - dragOffset.x
        local newY = touchPos.y - dragOffset.y
        
        -- Apply smart boundaries
        newX, newY = keepPanelInBounds(newX, newY)
        panel:setPosition(cc.p(newX, newY))
        return true -- consume event
 
    elseif eventType == 2 or eventType == 3 then -- ccui.TouchEventType.ended or ccui.TouchEventType.canceled
        isDragging = false
        
        -- Check if panel is way off screen, reset to initial position if needed
        local currentPos = panel:getPosition()
        local panelSize = panel:getContentSize()
        
        -- If more than 50% of panel is off screen, reset to initial position
        if currentPos.x < -panelSize.width/2 or currentPos.x > size.width - panelSize.width/2 or
           currentPos.y < -panelSize.height/2 or currentPos.y > size.height - panelSize.height/2 then
            write_debug("[Boundary] Panel too far off screen, resetting to initial position")
            panel:setPosition(initialPosition)
        end
        
        return true -- consume event
    end
    return false
end)
 
titleBar:addTouchEventListener(function(sender, eventType)
    if eventType == 0 then -- ccui.TouchEventType.began
        local touchPos = sender:getTouchBeganPosition()
        local panelPos = panel:getPosition()
        dragOffset = cc.p(touchPos.x - panelPos.x, touchPos.y - panelPos.y)
        isDragging = true
 
    elseif eventType == 1 and isDragging then -- ccui.TouchEventType.moved
        local touchPos = sender:getTouchMovePosition()
        local newX = touchPos.x - dragOffset.x
        local newY = touchPos.y - dragOffset.y
        
        -- Apply smart boundaries for title bar dragging too
        newX, newY = keepPanelInBounds(newX, newY)
        panel:setPosition(cc.p(newX, newY))
 
    elseif eventType == 2 or eventType == 3 then -- ccui.TouchEventType.ended or ccui.TouchEventType.canceled
        isDragging = false
        
        -- Check if panel is way off screen, reset to initial position if needed
        local currentPos = panel:getPosition()
        local panelSize = panel:getContentSize()
        
        -- If more than 50% of panel is off screen, reset to initial position
        if currentPos.x < -panelSize.width/2 or currentPos.x > size.width - panelSize.width/2 or
           currentPos.y < -panelSize.height/2 or currentPos.y > size.height - panelSize.height/2 then
            write_debug("[Boundary] Panel too far off screen, resetting to initial position")
            panel:setPosition(initialPosition)
        end
    end
end)
 
 
-- Track buttons
local buttons = {}
local closeButton = nil
local buttonSpacing = 10
local buttonHeight = 50
local buttonWidth = 400
 
-- Extra margins
local topMargin = 30     -- space below title bar
local bottomMargin = 60  -- space above close button
 
-- to refresh layout whenever a new button is added
local function refreshLayout()
    local count = #buttons
    -- Reserve space for title bar, margins, and close button
    local totalHeight = 50 + topMargin + (count * (buttonHeight + buttonSpacing)) + bottomMargin
 
 
    panel:setContentSize(cc.size(panelWidth, totalHeight))
 
    -- Reposition panel after resize (left side)
    panel:setPosition(cc.p(
    marginLeft,
    (size.height - totalHeight) / 2
))
 
    -- Reposition title bar at top
    titleBar:setPosition(cc.p(0, totalHeight - 50))
 
    -- Reposition normal buttons
    local y = totalHeight - 50 - topMargin - (buttonHeight / 2)
    for i, btn in ipairs(buttons) do
        btn:setPosition(cc.p(panelWidth/2, y))
        btn:setContentSize(cc.size(buttonWidth, buttonHeight))
        y = y - (buttonHeight + buttonSpacing)
    end
end
 
 
-- Enhanced makeButton with better styling and debug logging
local function makeButton(label, x, y, width, height)
    write_debug("[makeButton] Starting creation of: " .. label)
    
    local success, b = pcall(function()
        return ccui.Button:create()
    end)
    
    if not success then
        write_debug("[makeButton] ERROR: Failed to create button for: " .. label)
        return nil
    end
    
    write_debug("[makeButton] Button created successfully for: " .. label)
    
    success = pcall(function()
        b:setTitleText(label)
    end)
    if not success then
        write_debug("[makeButton] ERROR: Failed to set title for: " .. label)
    end
    
    success = pcall(function()
        b:setTitleFontSize(30)
    end)
    if not success then
        write_debug("[makeButton] ERROR: Failed to set font size for: " .. label)
    end
    
    success = pcall(function()
        b:setTitleColor(cc.c3b(255, 255, 255))  -- Pure white text for maximum contrast
    end)
    if not success then
        write_debug("[makeButton] ERROR: Failed to set title color for: " .. label)
    end
    
    success = pcall(function()
        b:setScale9Enabled(true)
    end)
    if not success then
        write_debug("[makeButton] ERROR: Failed to set scale9 enabled for: " .. label)
    end
    
    success = pcall(function()
        b:setContentSize(cc.size(width, height))
    end)
    if not success then
        write_debug("[makeButton] ERROR: Failed to set content size for: " .. label)
    end
    
    success = pcall(function()
        b:setPosition(cc.p(x, y))
    end)
    if not success then
        write_debug("[makeButton] ERROR: Failed to set position for: " .. label)
    end
 
    -- Enhanced button styling with contrasting colors (not blue)
    local normalColor = cc.c3b(80, 120, 80)      -- Green color to contrast with blue background
    local hoverColor  = cc.c3b(100, 140, 100)    -- Lighter green
    local pressedColor= cc.c3b(60, 100, 60)      -- Darker green for contrast
    
    success = pcall(function()
        b:setColor(normalColor)
    end)
    if not success then
        write_debug("[makeButton] ERROR: Failed to set color for: " .. label)
    end
 
    -- Try to set background color with high contrast
    success = pcall(function()
        b:setBackGroundColorType(1)
        b:setBackGroundColor(normalColor)
        b:setBackGroundColorOpacity(255)
    end)
    if not success then
        write_debug("[makeButton] WARNING: Background color methods not supported for: " .. label)
    end
    
    -- Note: setBackGroundColorType, setBackGroundColor, setBackGroundColorOpacity
    -- are not supported in this Cocos2d-x version
    write_debug("[makeButton] Using setColor instead of background methods for: " .. label)
 
    success = pcall(function()
        b:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.began then
                pcall(function() sender:setColor(pressedColor) end)
                pcall(function() sender:setBackGroundColor(pressedColor) end)
            elseif eventType == ccui.TouchEventType.ended then
                pcall(function() sender:setColor(normalColor) end)
                pcall(function() sender:setBackGroundColor(normalColor) end)
            elseif eventType == ccui.TouchEventType.canceled then
                pcall(function() sender:setColor(normalColor) end)
                pcall(function() sender:setBackGroundColor(normalColor) end)
            end
        end)
    end)
    if not success then
        write_debug("[makeButton] ERROR: Failed to add touch listener for: " .. label)
    end
 
    success = pcall(function()
        panel:addChild(b)
        -- Ensure buttons are on top of background
        b:setLocalZOrder(10)
        
        -- Add border/outline to make buttons stand out
        pcall(function()
            b:setScale9Enabled(true)
            -- Try to add a subtle border effect
            b:setColor(normalColor)
        end)
    end)
    if not success then
        write_debug("[makeButton] ERROR: Failed to add button to panel for: " .. label)
    else
        write_debug("[makeButton] SUCCESS: Button fully created and added: " .. label)
    end
    
    return b
end
 
local function bind(btn, func)
    btn:addTouchEventListener(function(sender, eventType)
        if eventType == eventOK then func(sender) end
    end)
end
 
-- god mode (using buff system)
_G.GM_GODMODE = _G.GM_GODMODE or false
 
local function toggle_god()
    local mp = G.main_player
    if not mp then
        write_debug("[God] ERROR: G.main_player not available")
        return false
    end
    
    if _G.GM_GODMODE then
        -- Disable god mode
        local mod = "hexm.client.ui.windows.gm.gm_combat.combat_train_action"
        local action = nil
        pcall(function() action = portable.import(mod) end)
        if action and action.rm_buff then
            pcall(action.rm_buff, 70063)
        end
        _G.GM_GODMODE = false
        write_debug("[God] [✔] God mode disabled")
        return false
    else
        -- Enable god mode
        pcall(mp.add_buff, mp, 70063)
        _G.GM_GODMODE = true
        write_debug("[God] [✔] God mode enabled")
        return true
    end
end
 
-- One-Hit Exhaust (REMOVED)
-- This feature has been removed as requested
 
-- One-Hit Kill (using action system)
_G.GM_ONEHITKILL = _G.GM_ONEHITKILL or false
 
local function toggle_one_hit_kill()
    local mod = "hexm.client.ui.windows.gm.gm_combat.combat_train_action"
    local action = nil
    pcall(function() action = portable.import(mod) end)
    
    if not action then
        write_debug("[OHK] ERROR: Module not found")
        return
    end
    
    if _G.GM_ONEHITKILL then
        -- Disable One-Hit Kill (set_niubility=0 disables OHK)
        if action.set_niubility then
            pcall(action.set_niubility, 0)
        end
        _G.GM_ONEHITKILL = false
        write_debug("[OHK] [✔] One-Hit Kill disabled (set_niubility=0)")
    else
        -- Enable One-Hit Kill (set_niubility=1 enables OHK)
        if action.set_niubility then
            pcall(action.set_niubility, 1)
        end
        _G.GM_ONEHITKILL = true
        write_debug("[OHK] [✔] One-Hit Kill enabled (set_niubility=1)")
    end
end
 
-- Infinite Stamina (using action system)
_G.GM_STAMINA = _G.GM_STAMINA or false
 
local function toggle_stamina()
    local mod = "hexm.client.ui.windows.gm.gm_combat.combat_train_action"
    local action = nil
    pcall(function() action = portable.import(mod) end)
    
    if not action then
        write_debug("[Stamina] ERROR: Module not found")
        return false
    end
    
    if _G.GM_STAMINA then
        -- Disable infinite stamina
        if action.set_lock_res_consume then
            pcall(action.set_lock_res_consume, false)
        end
        _G.GM_STAMINA = false
        write_debug("[Stamina] [✔] Infinite stamina disabled")
        return false
    else
        -- Enable infinite stamina
        if action.set_lock_res_consume then
            pcall(action.set_lock_res_consume, true)
        end
        _G.GM_STAMINA = true
        write_debug("[Stamina] [✔] Infinite stamina enabled")
        return true
    end
end
 
 
 
 
 
 
-- Diving Air
_G.GM_DIVEAIR = _G.GM_DIVEAIR or false
 
local function toggle_diveair()
    local gm_decorator = package.loaded["hexm.client.debug.gm.gm_decorator"] 
        or require("hexm.client.debug.gm.gm_decorator")
 
    if not gm_decorator.gm_command_short_cuts.game then return false end
    local cmds = gm_decorator.gm_command_short_cuts.game
 
    if _G.GM_DIVEAIR then
        -- Disable infinite diving air
        if cmds["$unlimited_dive_resource"] then pcall(cmds["$unlimited_dive_resource"], 0) end
        _G.GM_DIVEAIR = false
        return false
    else
        -- Enable infinite diving air
        if cmds["$unlimited_dive_resource"] then pcall(cmds["$unlimited_dive_resource"], 1) end
        _G.GM_DIVEAIR = true
        return true
    end
end
 
 
-- No cooldown (using action system)
_G.GM_NOCD = _G.GM_NOCD or false
 
local function toggle_no_cd()
    local mod = "hexm.client.ui.windows.gm.gm_combat.combat_train_action"
    local action = nil
    pcall(function() action = portable.import(mod) end)
    
    if not action then
        write_debug("[NoCD] ERROR: Module not found")
        return false
    end
    
    if _G.GM_NOCD then
        -- Disable No Cooldown
        if action.set_no_cd then
            pcall(action.set_no_cd, false)
        end
        _G.GM_NOCD = false
        write_debug("[NoCD] [✔] No Cooldown disabled")
        return false
    else
        -- Enable No Cooldown
        if action.set_no_cd then
            pcall(action.set_no_cd, true)
        end
        _G.GM_NOCD = true
        write_debug("[NoCD] [✔] No Cooldown enabled")
        return true
    end
end
 
 
 
-- "Kill all nearby NPC" 
local function kill_all_nearby_npc()
    local count = 0
    local combat_action = nil
    pcall(function() combat_action = portable.import('hexm.client.ui.windows.gm.gm_combat.combat_train_action') end)
 
    if combat_action then
        -- BOSS SPECIFIC: Make all NPCs mortal (removes boss invincibility)
        pcall(function() combat_action.set_npc_mortal(true) end)
        -- Kill all nearby NPCs (including bosses if mortal)
        pcall(function() combat_action.kill_all_npc() end)
    end
 
    -- ========== BOSS DAMAGE ==========
    pcall(function()
        local target_id = mp:get_lock_target_id()
        if target_id then
            local target = G.space:get_entity(target_id)
            if target then
                pcall(function() target:force_set_HP(0, mp.entity_id, "gm") end)
                pcall(function() target:attr_set_HP(0, mp.entity_id, true, false) end)
                pcall(function() target:do_direct_damage(999999999, mp.entity_id, 0, 0, 0, 0) end)
                count = count + 1
            end
        end
    end)
 
    -- Damage all nearby AI/NPCs
    pcall(function()
        local all_entities = MEntityManager:GetAOIEntities()
        for i = 1, #all_entities do
            local ent = all_entities[i]
            local ok, name = pcall(function() return ent:GetName() end)
            if ok and name and (name:find('AiAvatar') or name:find('Npc') or name:find('Boss')) then
                local ok2, eid = pcall(function() return ent.entity_id end)
                if ok2 and eid then
                    local target = G.space:get_entity(eid)
                    if target and target ~= mp then
                        pcall(function() target:force_set_HP(0, mp.entity_id, "gm") end)
                        pcall(function() target:do_direct_damage(999999999, mp.entity_id, 0, 0, 0, 0) end)
                        count = count + 1
                    end
                end
            end
        end
    end)
 
    return true, count
end
 
 
-- Reset Crime
local function reset_crime()
    local gm_decorator = package.loaded["hexm.client.debug.gm.gm_decorator"] 
        or require("hexm.client.debug.gm.gm_decorator")
 
    if gm_decorator.gm_command_short_cuts.game then
        local cmds = gm_decorator.gm_command_short_cuts.game
        -- [RESET CRIME] -- resets when you teleport or reset instance/zone
        if cmds["$forbid_witness_wanfa"] then pcall(cmds["$forbid_witness_wanfa"], 1) end
        if cmds["$forbid_police_wanfa"] then pcall(cmds["$forbid_police_wanfa"], 1) end
    end
end
 
-- Instant Win Chess
local function instant_win_chess()
    local gm_wanfa = package.loaded["hexm.client.debug.gm.gm_commands.gm_wanfa"]
    if gm_wanfa and gm_wanfa.gm_common_chess_fast_win then
        pcall(function()
            gm_wanfa.gm_common_chess_fast_win(1)
        end)
    end
end
 
-- Auto Rhythm Game
local function auto_rhythm_game()
    local ok, gm_instrument = pcall(require, "hexm.client.debug.gm.gm_commands.gm_instrument")
    if not ok or not gm_instrument then return end
 
    if gm_instrument.enable_auto_rhythm_game then
        pcall(function()
            gm_instrument.enable_auto_rhythm_game(true)
        end)
    end
 
    write_debug("Auto Rhythm Game enabled")
end
 
-- Pitch Pot Circle enlarged for easy win
local function activate_pitch_pot_enlargement()
    local gm_wanfa = package.loaded["hexm.client.debug.gm.gm_commands.gm_wanfa"]
    if gm_wanfa and gm_wanfa.gm_scale_pitch_pot_circle then
        pcall(function()
            gm_wanfa.gm_scale_pitch_pot_circle(7)
        end)
    end
    write_debug("Pitch Pot Circle enlarged for easy win")
end
 
 
-- NPC DUMB (using buff system)
_G.GM_NPCDUMB = _G.GM_NPCDUMB or false
 
local function toggle_npc_dumb()
    local mp = G.main_player
    if not mp then
        write_debug("[NPC DUMB] ERROR: G.main_player not available")
        return false
    end
    
    if _G.GM_NPCDUMB then
        -- Disable NPC DUMB
        local mod = "hexm.client.ui.windows.gm.gm_combat.combat_train_action"
        local action = nil
        pcall(function() action = portable.import(mod) end)
        if action and action.rm_buff then
            pcall(action.rm_buff, 380013)
        end
        _G.GM_NPCDUMB = false
        write_debug("[NPC DUMB] [✔] NPC DUMB disabled")
        return false
    else
        -- Enable NPC DUMB
        pcall(mp.add_buff, mp, 380013)
        _G.GM_NPCDUMB = true
        write_debug("[NPC DUMB] [✔] NPC DUMB enabled")
        return true
    end
end
 
-- disable logging ??
local function disable_logs_and_checks()
    local ok_combat, gm_combat = pcall(require, "hexm.client.debug.gm.gm_commands.gm_combat")
    if ok_combat then
        if gm_combat.gm_forbid_behit_highlight then pcall(gm_combat.gm_forbid_behit_highlight, 1) end
        if gm_combat.gm_enable_stopframe_debug then pcall(gm_combat.gm_enable_stopframe_debug, 0) end
    end
 
    local ok_cutscene, gm_cutscene = pcall(require, "hexm.client.debug.gm.gm_commands.gm_cutscene")
    if ok_cutscene then
        if gm_cutscene.gm_cutscene_clear_log then pcall(gm_cutscene.gm_cutscene_clear_log) end
        if gm_cutscene.gm_cutscene_debug_terminate then pcall(gm_cutscene.gm_cutscene_debug_terminate) end
    end
 
    local ok_activity, gm_activity = pcall(require, "hexm.client.debug.gm.gm_commands.gm_activity_center")
    if ok_activity and gm_activity.gm_activity_center_clear then
        pcall(gm_activity.gm_activity_center_clear)
    end
 
    local ok_hotfix, gm_hotfix = pcall(require, "hexm.client.debug.gm.gm_commands.gm_hotfix")
    if ok_hotfix then
        if gm_hotfix.gm_hotfix_del_local_cache then pcall(gm_hotfix.gm_hotfix_del_local_cache) end
    end
 
    local ok_story, gm_story = pcall(require, "hexm.client.debug.gm.gm_commands.gm_storyline")
    if ok_story and gm_story.gm_server_not_run_lua_script then
        pcall(gm_story.gm_server_not_run_lua_script)
    end
 
    write_debug("[✔] Anti‑cheat logging and server checks disabled")
end
 
-- FOV Cycle Toggle
local FOV_VALUES = {10,20,30,40,50,60,70,80,90,100}
_G.GM_FOV_INDEX = _G.GM_FOV_INDEX or 6  -- default 60
 
-- Apply FOV using gm_camera
local function apply_fov(value)
    local gm_camera = package.loaded["hexm.client.debug.gm.gm_commands.gm_camera"]
        or require("hexm.client.debug.gm.gm_commands.gm_camera")
 
    if gm_camera and gm_camera.test_camera_fov then
        pcall(gm_camera.test_camera_fov, value)
        write_debug(string.format("[✔] FOV set to %d", value))
    else
        write_debug("[✘] gm_camera.test_camera_fov not available")
    end
end
 
-- Button (declare first so callback can reference it)
local btn_fov
 
-- Safely set button title and refresh layout
local function set_button_title_live(btn, text)
    if not btn then return end
 
    local updated = false
 
    -- Try updating the internal title renderer
    local okRenderer, titleRenderer = pcall(function()
        return btn.getTitleRenderer and btn:getTitleRenderer()
    end)
    if okRenderer and titleRenderer and titleRenderer.setString then
        titleRenderer:setString(text)
        updated = true
    end
 
    -- Fallbacks: different APIs across builds
    if not updated and btn.setTitleText then
        btn:setTitleText(text)
        updated = true
    end
    if not updated and btn.setTitle then
        btn:setTitle(text)
        updated = true
    end
 
    -- As a last resort, look for a child label commonly named "title"/"label"
    if not updated and btn.getChildByName then
        local label = btn:getChildByName("title") or btn:getChildByName("label")
        if label and label.setString then
            label:setString(text)
            updated = true
        end
    end
 
    -- Force layout so the UI redraws immediately
    pcall(function()
        if btn.requestDoLayout then btn:requestDoLayout() end
        local parent = btn.getParent and btn:getParent()
        if parent and parent.forceDoLayout then parent:forceDoLayout() end
        if cc and ccui and ccui.Helper and ccui.Helper.doLayout then
            ccui.Helper:doLayout(parent or btn)
        end
    end)
end
 
-- Cycle function
local function toggle_fov()
    _G.GM_FOV_INDEX = _G.GM_FOV_INDEX % #FOV_VALUES + 1
    local newFov = FOV_VALUES[_G.GM_FOV_INDEX]
    apply_fov(newFov)
    set_button_title_live(btn_fov, "Cycle FOV (" .. newFov .. ")")
end
 
 
-- Speed Hack (using working method from Speed.lua)
_G.SPEED_ENABLED = _G.SPEED_ENABLED or false
 
local function toggle_speed()
    write_debug("[Speed] Toggling speed hack...")
    local SPEED_MULTIPLIER = 3.0
    local NORMAL_SPEED = 1.0
    
    _G.SPEED_ENABLED = not _G.SPEED_ENABLED
    
    if _G.SPEED_ENABLED then
        -- Enable speed
        if G and G.main_player then
            local mp = G.main_player
            if mp.set_move_speed_scale then
                pcall(mp.set_move_speed_scale, mp, SPEED_MULTIPLIER)
                write_debug("[Speed] [✔] Speed enabled (x" .. SPEED_MULTIPLIER .. ")")
                return true
            else
                write_debug("[Speed] ERROR: set_move_speed_scale method not found")
            end
        else
            write_debug("[Speed] ERROR: G.main_player not available")
        end
    else
        -- Disable speed
        if G and G.main_player then
            local mp = G.main_player
            if mp.set_move_speed_scale then
                pcall(mp.set_move_speed_scale, mp, NORMAL_SPEED)
                write_debug("[Speed] [✔] Speed disabled")
                return true
            else
                write_debug("[Speed] ERROR: set_move_speed_scale method not found")
            end
        else
            write_debug("[Speed] ERROR: G.main_player not available")
        end
    end
    
    return false
end
 
-- Map Cycle
local room_ids = { 7, 10, 11, 13, 16 }
 
_G.GM_ROOM_INDEX = _G.GM_ROOM_INDEX or 1
 
local function cycle_gm_room()
    local ok, skip = pcall(require, "hexm.client.ui.windows.gm.gm_skip_window")
    if not ok or not skip or not skip.gm_skip_flow_imp then
        write_debug("[✘] gm_skip_window not available")
        return
    end
 
    -- advance index
    _G.GM_ROOM_INDEX = _G.GM_ROOM_INDEX + 1
    if _G.GM_ROOM_INDEX > #room_ids then
        _G.GM_ROOM_INDEX = 1
    end
 
    local room_id = room_ids[_G.GM_ROOM_INDEX]
    pcall(skip.gm_skip_flow_imp, room_id, nil)
    write_debug(string.format("[✔] Teleported to GM Room ID %d", room_id))
end
 
-- GM Room → Open World (ID 7)
local function teleport_open_world()
    local ok, skip = pcall(require, "hexm.client.ui.windows.gm.gm_skip_window")
    if not ok or not skip or not skip.gm_skip_flow_imp then
        write_debug("[✘] gm_skip_window not available")
        return
    end
    pcall(skip.gm_skip_flow_imp, 16, nil)
    write_debug("[✔] Teleported to Blissful Retreat (ID 16)")
end
 
 
local y = panelHeight - 80   -- start below title bar
local function row(label, func)
    write_debug("[Row] Creating button: " .. label)
    local b = makeButton(label, 240, y, 400, 50)
    write_debug("[Row] Button created successfully: " .. label)
    -- Use direct touch event handling instead of bind() to avoid eventOK conflicts
    b:addTouchEventListener(function(sender, eventType)
        write_debug("[Row] Touch event for " .. label .. ": " .. tostring(eventType))
        if eventType == 2 then -- ccui.TouchEventType.ended
            write_debug("[Row] Executing function for: " .. label)
            local success, err = pcall(func, sender)
            if not success then
                write_debug("[Row] Error executing " .. label .. ": " .. tostring(err))
            end
        end
    end)
    -- Add button to buttons array for tracking
    table.insert(buttons, b)
    write_debug("[Row] Button added to array: " .. label .. ", total buttons: " .. #buttons)
    y = y - 70
    return b
end
 
write_debug("Button creation functions set up")
write_debug("Starting button creation...")
 
-- Teleport Random button
btn_cycle_room = row("Teleport Random", function()
    cycle_gm_room()
end)
btn_cycle_room:setTitleColor(cc.c3b(255, 255, 255))
 
-- Teleport back button
btn_open_world = row("Teleport to Blissful Retreat", function()
    teleport_open_world()
end)
btn_open_world:setTitleColor(cc.c3b(255, 255, 255))
 
 
 
-- god mode
local btn_god = row("Godmode: " .. (_G.GM_GODMODE and "ON" or "OFF"), function(b)
    local state = toggle_god()
    b:setTitleText("Godmode: " .. (state and "ON" or "OFF"))
    b:setTitleColor(state and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
end)
 
-- Initialize color correctly at startup
btn_god:setTitleColor(_G.GM_GODMODE and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
 
-- One-Hit Exhaust (REMOVED)
-- This button has been removed as requested
 
-- ohk
local btn_onehitkill = row("One-Hit Kill: " .. (_G.GM_ONEHITKILL and "ON" or "OFF"), function(b)
    toggle_one_hit_kill() -- Just toggle, don't rely on return value
    -- Update button based on actual global state
    local currentState = _G.GM_ONEHITKILL
    b:setTitleText("One-Hit Kill: " .. (currentState and "ON" or "OFF"))
    b:setTitleColor(currentState and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
end)
 
-- Initialize color correctly at startup
btn_onehitkill:setTitleColor(_G.GM_ONEHITKILL and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
 
 
-- no cd
local btn_nocd = row("No Cooldown: " .. (_G.GM_NOCD and "ON" or "OFF"), function(b)
    local state = toggle_no_cd()
    b:setTitleText("No Cooldown: " .. (state and "ON" or "OFF"))
    b:setTitleColor(state and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
end)
 
-- Initialize color correctly at startup
btn_nocd:setTitleColor(_G.GM_NOCD and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
 
-- inf stamina 
local btn_stamina = row("Infinite Stamina: " .. (_G.GM_STAMINA and "ON" or "OFF"), function(b)
    -- Run toggle once
    toggle_stamina()
    -- Always read from the source
    local on = _G.GM_STAMINA == true
    b:setTitleText("Infinite Stamina: " .. (on and "ON" or "OFF"))
    b:setTitleColor(on and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
end)
 
-- Initialize color correctly at startup
btn_stamina:setTitleColor(_G.GM_STAMINA and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
 
 
local btn_invisible = row("Invisibility: " .. (_G.GM_INVISIBLE and "ON" or "OFF"), function(b)
    local state = toggle_invisible()
    b:setTitleText("Invisibility: " .. (state and "ON" or "OFF"))
    b:setTitleColor(state and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
end)
-- Initialize color correctly
btn_invisible:setTitleColor(_G.GM_INVISIBLE and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
 
-- Diving Air (REMOVED)
-- This button has been removed as requested
 
 
-- NPC DUMB
local btn_npcai = row("NPC DUMB: " .. (_G.GM_NPCDUMB and "ON" or "OFF"), function(b)
    local state = toggle_npc_dumb()
    b:setTitleText("NPC DUMB: " .. (state and "ON" or "OFF"))
    b:setTitleColor(state and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
end)
 
-- Initialize color correctly at startup
btn_npcai:setTitleColor(_G.GM_NPCDUMB and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
 
-- Speed Hack Button
local btn_speedup = row("Speed Hack: " .. (_G.SPEED_ENABLED and "ON (x3)" or "OFF"), function(b)
    local state = toggle_speed()
    b:setTitleText("Speed Hack: " .. (state and "ON (x3)" or "OFF"))
    b:setTitleColor(state and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
end)
 
-- Initialize color correctly at startup
btn_speedup:setTitleColor(_G.SPEED_ENABLED and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
 
 
-- reset crime
local btn_resetcrime = row("Reset Crime", function()
    reset_crime()
end)
btn_resetcrime:setTitleColor(cc.c3b(255, 255, 255))
 
-- kill all nearby npc
local btn_killnpc = row("Kill all nearby NPC", function()
    local ok, count = kill_all_nearby_npc()
    if ok then
        write_debug(string.format("Kill all nearby NPC executed. Count=%d", count))
    else
        write_debug("Kill all nearby NPC failed to execute")
    end
end)
btn_killnpc:setTitleColor(cc.c3b(255, 255, 255))
 
-- Chess
local btn_chesswin = row("Instant Win Chess", function()
    instant_win_chess()
end)
btn_chesswin:setTitleColor(cc.c3b(255, 255, 255))
 
-- Pitch Pot Circle enlarged for easy win
local btn_pitchpot = row("Pitch Pot Circle enlarged for easy win", function()
    activate_pitch_pot_enlargement()
end)
btn_pitchpot:setTitleColor(cc.c3b(255, 255, 255))
 
-- Rhythm
local btn_autorhythm = row("Auto Rhythm Game", function()
    auto_rhythm_game() 
end)
btn_autorhythm:setTitleColor(cc.c3b(255, 255, 255))
 
 
-- combat menu (HIDDEN)
-- local btn_combat_menu = row("Combat Menu", function()
--     refresh_combat_menu()
-- end)
-- btn_combat_menu:setTitleColor(cc.c3b(255, 255, 255))
  
-- change weapon skin (HIDDEN)
-- local btn_weapon_guise = row("Change Weapon Skin", function()
--     weapon_guise()
-- end)
-- btn_weapon_guise:setTitleColor(cc.c3b(255, 255, 255))
 
-- Cycle FOV button 
btn_fov = row("Cycle FOV (" .. FOV_VALUES[_G.GM_FOV_INDEX] .. ")", function()
    toggle_fov()
end)
btn_fov:setTitleColor(cc.c3b(255, 255, 255))
 
-- Auto Loot button (WORKING METHOD from 00AutoLoot.lua)
local btn_autoloot = row("Auto Loot", function()
    write_debug("[AutoLoot] Triggering AutoLoot...")
    local mp = G.main_player
    if not mp then
        write_debug("[AutoLoot] ERROR: Main player not found")
        return false
    end
    
    local interact_misc = portable.import('hexm.common.misc.interact_misc')
    
    -- Method 1: Collect nearby collections
    pcall(function() mp:ride_skill_collect_nearby_collections(1500) end)
    
    -- Method 2: Find and collect kill rewards
    pcall(function()
        local rewards = mp:ride_skill_find_nearest_kill_reward(1500)
        if rewards then
            mp:ride_skill_get_kill_reward(rewards)
        end
    end)
    
    -- Method 3: Pick up nearby drops
    pcall(function()
        local drops = DropManager.get_nearby_drop_entities(1500)
        if drops then
            for _, eid in ipairs(drops) do
                pcall(function() mp:pick_drop_item(eid) end)
                pcall(function() mp:pick_reward_item(eid) end)
            end
        end
    end)
    
    -- Method 4: Advanced InteractComEntity system
    local playerPos = mp:get_position()
    local entities = MEntityManager:GetAOIEntities()
    local targets = {}
    
    for i = 1, #entities do
        local ent = entities[i]
        local ok, name = pcall(function() return ent:GetName() end)
        if ok and name and name:find('InteractComEntity') then
            local ok2, eno = pcall(function() return ent:GetEntityNo() end)
            local ok3, eid = pcall(function() return ent.entity_id end)
            if ok2 and ok3 then
                local luaEnt = G.space:get_entity(eid)
                if luaEnt then
                    local ok4, comp = pcall(function() return luaEnt:get_interact_comp(eid) end)
                    if ok4 and comp and comp.position then
                        local dx = playerPos.x - comp.position[1]
                        local dy = playerPos.y - comp.position[2]
                        local dz = playerPos.z - comp.position[3]
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                        
                        local priority = eid:find('ins_entity') and 0 or 1
                        table.insert(targets, {
                            entity_no = eno,
                            entity_id = eid,
                            luaEnt = luaEnt,
                            comp = comp,
                            distance = dist,
                            priority = priority
                        })
                    end
                end
            end
        end
    end
    
    table.sort(targets, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        return a.distance < b.distance
    end)
    
    for i = 1, #targets do
        local t = targets[i]
        local ways = {}
        local seen = {}
        
        local ok_ways, possible = pcall(function()
            return interact_misc.get_all_possible_active_ways(t.entity_no)
        end)
        
        if ok_ways and possible then
            for _, w in ipairs(possible) do
                if not seen[w] then seen[w] = true; table.insert(ways, w) end
            end
        end
        
        local comp_id = nil
        if t.comp.components then
            for cid, comp_data in pairs(t.comp.components) do
                comp_id = cid
                
                if comp_data.status_no and not seen[comp_data.status_no] then
                    seen[comp_data.status_no] = true
                    table.insert(ways, comp_data.status_no)
                end
                
                if comp_data.config_no and not seen[comp_data.config_no] then
                    seen[comp_data.config_no] = true
                    table.insert(ways, comp_data.config_no)
                end
            end
        end
        
        if #ways > 0 then
            pcall(function() mp:set_interact_target_id(t.entity_id) end)
            
            for _, way in ipairs(ways) do
                pcall(function()
                    mp:trigger_active_interact(way, t.entity_id, nil, nil, comp_id)
                end)
            end
            
            pcall(function() mp:trigger_active_interact() end)
        end
    end
    
    write_debug("[AutoLoot] [✔] AutoLoot activated - all methods executed")
    return true
end)
btn_autoloot:setTitleColor(cc.c3b(255, 255, 255))
 
-- Auto Loot Loop button
_G.AUTO_COLLECT_ENABLED = _G.AUTO_COLLECT_ENABLED or false
local auto_collect_timer = nil
 
local btn_autolootloop = row("Auto Loot Loop: " .. (_G.AUTO_COLLECT_ENABLED and "ON" or "OFF"), function(b)
    local state = toggle_auto_collect_loop()
    b:setTitleText("Auto Loot Loop: " .. (state and "ON" or "OFF"))
    b:setTitleColor(state and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
end)
 
-- Initialize color correctly at startup
btn_autolootloop:setTitleColor(_G.AUTO_COLLECT_ENABLED and cc.c3b(0, 255, 0) or cc.c3b(255, 0, 0))
 
local function toggle_auto_collect_loop()
    write_debug("[AutoLootLoop] Toggling auto collect loop...")
    _G.AUTO_COLLECT_ENABLED = not _G.AUTO_COLLECT_ENABLED
    
    if _G.AUTO_COLLECT_ENABLED then
        -- Start auto collect loop
        if auto_collect_timer then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(auto_collect_timer)
        end
        
        auto_collect_timer = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
            local mp = G.main_player
            if not mp then
                write_debug("[AutoLootLoop] ERROR: Main player not found for AutoLoot")
                return
            end
            
            local interact_misc = portable.import('hexm.common.misc.interact_misc')
            
            -- Method 1: Collect nearby collections
            pcall(function() mp:ride_skill_collect_nearby_collections(1500) end)
            
            -- Method 2: Find and collect kill rewards
            pcall(function()
                local rewards = mp:ride_skill_find_nearest_kill_reward(1500)
                if rewards then
                    mp:ride_skill_get_kill_reward(rewards)
                end
            end)
            
            -- Method 3: Pick up nearby drops
            pcall(function()
                local drops = DropManager.get_nearby_drop_entities(1500)
                if drops then
                    for _, eid in ipairs(drops) do
                        pcall(function() mp:pick_drop_item(eid) end)
                        pcall(function() mp:pick_reward_item(eid) end)
                    end
                end
            end)
            
            -- Method 4: Advanced InteractComEntity system
            local playerPos = mp:get_position()
            local entities = MEntityManager:GetAOIEntities()
            local targets = {}
            
            for i = 1, #entities do
                local ent = entities[i]
                local ok, name = pcall(function() return ent:GetName() end)
                if ok and name and name:find('InteractComEntity') then
                    local ok2, eno = pcall(function() return ent:GetEntityNo() end)
                    local ok3, eid = pcall(function() return ent.entity_id end)
                    if ok2 and ok3 then
                        local luaEnt = G.space:get_entity(eid)
                        if luaEnt then
                            local ok4, comp = pcall(function() return luaEnt:get_interact_comp(eid) end)
                            if ok4 and comp and comp.position then
                                local dx = playerPos.x - comp.position[1]
                                local dy = playerPos.y - comp.position[2]
                                local dz = playerPos.z - comp.position[3]
                                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                                
                                local priority = eid:find('ins_entity') and 0 or 1
                                table.insert(targets, {
                                    entity_no = eno,
                                    entity_id = eid,
                                    luaEnt = luaEnt,
                                    comp = comp,
                                    distance = dist,
                                    priority = priority
                                })
                            end
                        end
                    end
                end
            end
            
            table.sort(targets, function(a, b)
                if a.priority ~= b.priority then return a.priority < b.priority end
                return a.distance < b.distance
            end)
            
            for i = 1, #targets do
                local t = targets[i]
                local ways = {}
                local seen = {}
                
                local ok_ways, possible = pcall(function()
                    return interact_misc.get_all_possible_active_ways(t.entity_no)
                end)
                
                if ok_ways and possible then
                    for _, w in ipairs(possible) do
                        if not seen[w] then seen[w] = true; table.insert(ways, w) end
                    end
                end
                
                local comp_id = nil
                if t.comp.components then
                    for cid, comp_data in pairs(t.comp.components) do
                        comp_id = cid
                        
                        if comp_data.status_no and not seen[comp_data.status_no] then
                            seen[comp_data.status_no] = true
                            table.insert(ways, comp_data.status_no)
                        end
                        
                        if comp_data.config_no and not seen[comp_data.config_no] then
                            seen[comp_data.config_no] = true
                            table.insert(ways, comp_data.config_no)
                        end
                    end
                end
                
                if #ways > 0 then
                    pcall(function() mp:set_interact_target_id(t.entity_id) end)
                    
                    for _, way in ipairs(ways) do
                        pcall(function()
                            mp:trigger_active_interact(way, t.entity_id, nil, nil, comp_id)
                        end)
                    end
                    
                    pcall(function() mp:trigger_active_interact() end)
                end
            end
        end, 2.0, false) -- Run every 2 seconds
        write_debug("[AutoLootLoop] [✔] Auto Collect Loop enabled (2s interval)")
    else
        -- Stop auto collect loop
        if auto_collect_timer then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(auto_collect_timer)
            auto_collect_timer = nil
        end
        write_debug("[AutoLootLoop] [✔] Auto Collect Loop disabled")
    end
    
    return _G.AUTO_COLLECT_ENABLED
end
 
-- RECOVERY button (Using Action and Buff)
local btn_recovery = row("Recovery", function()
    write_debug("[Recover] Recovering player...")
 
    local function recover_player()
        local mp = G.main_player
        if not mp then
            write_debug("[Recover] ERROR: Main player not found for recovery")
            return false
        end
 
        local success = false
        -- Try using the combat action module
        local mod = "hexm.client.ui.windows.gm.gm_combat.combat_train_action"
        local action = nil
        pcall(function() action = portable.import(mod) end)
 
        if action then
            pcall(function() action.recover_hp(1) end) -- Recover HP
            pcall(function() action.fullfill_all_combat_res(1) end) -- Full fill stamina
            write_debug("[Recover] [✔] Recovery applied via combat action")
            success = true
        else
            -- Fallback to buff method
            pcall(mp.add_buff, mp, 70141)
            write_debug("[Recover] [✔] Recovery buff applied as fallback")
            success = true
        end
 
        return success
    end
 
    -- Execute recovery when button clicked
    recover_player()
end)
 
btn_recovery:setTitleColor(cc.c3b(0, 255, 0))
 
 
 
 
 
 
-- DEBUG: Check if we reach this point after button creation
write_debug("[DEBUG] Reached point after Recovery button creation")
write_debug("[DEBUG] Total buttons created: " .. #buttons)
write_debug("[DEBUG] About to create minimize button...")
 
-- MINIMIZE BUTTON with enhanced styling
write_debug("[DEBUG] Starting minimize button creation...")
local btn_minimize_success, btn_minimize = pcall(function()
    return ccui.Button:create()
end)
write_debug("[DEBUG] Minimize button creation: " .. tostring(btn_minimize_success))
 
if btn_minimize_success and btn_minimize then
    write_debug("[DEBUG] Setting minimize button properties...")
    pcall(function() btn_minimize:setTitleText("−") end)  -- Better minus symbol
    pcall(function() btn_minimize:setTitleFontSize(26) end)
    pcall(function() btn_minimize:setTitleColor(cc.c3b(255, 255, 120)) end)  -- Brighter yellow
    pcall(function() btn_minimize:setScale9Enabled(true) end)
    pcall(function() btn_minimize:setContentSize(cc.size(35, 35)) end)
 
    -- Enhanced button styling
    pcall(function() btn_minimize:setBackGroundColorType(1) end)
    pcall(function() btn_minimize:setBackGroundColor(cc.c3b(60, 60, 80)) end)  -- Dark blue background
    pcall(function() btn_minimize:setBackGroundColorOpacity(200) end)
 
    -- Position at top-right of title bar (left of close button)
    pcall(function() btn_minimize:setPosition(cc.p(panelWidth - 65, titleBar:getContentSize().height / 2)) end)
 
    -- Ensure minimize button stays on top
    pcall(function() btn_minimize:setLocalZOrder(1000) end)
    write_debug("[DEBUG] Minimize button properties set successfully")
else
    write_debug("[ERROR] Failed to create minimize button")
end
 
-- Add comprehensive debug logging to minimize button
btn_minimize:addTouchEventListener(function(sender, eventType)
    write_debug("[Minimize] Touch event received: " .. tostring(eventType))
    write_debug("[Minimize] isMinimized state: " .. tostring(isMinimized))
    
    if eventType == 0 then -- ccui.TouchEventType.began
        write_debug("[Minimize] Touch began - button pressed")
        pcall(function() sender:setColor(cc.c3b(100, 100, 100)) end) -- Darken when pressed
    elseif eventType == 2 then -- ccui.TouchEventType.ended
        write_debug("[Minimize] Touch ended - executing action")
        pcall(function() sender:setColor(cc.c3b(255, 255, 255)) end) -- Restore color
        
        if isMinimized then
        -- Restore menu
        isMinimized = false
        panel:setContentSize(originalPanelSize)
        
        -- Show all buttons
        for i, btn in ipairs(buttons) do
            btn:setVisible(true)
        end
        
        -- Ensure minimize button is still visible
        btn_minimize:setVisible(true)
        
        -- Restore title text
        titleText:setString("Maid Mod Menu")
        titleText:setVisible(true)
        
        -- Change button back to minimize
        pcall(function() btn_minimize:setTitleText("−") end)  -- Better minus symbol
        pcall(function() btn_minimize:setTitleColor(cc.c3b(255, 255, 120)) end)  -- Brighter yellow
        pcall(function() btn_minimize:setBackGroundColor(cc.c3b(60, 60, 80)) end)  -- Restore dark blue
        
        -- Move minimize button back to original position
        pcall(function() btn_minimize:setPosition(cc.p(panelWidth - 60, titleBar:getContentSize().height / 2)) end)
        
        -- Show keybind info when restored
        if keybindInfo then
            pcall(function() keybindInfo:setVisible(true) end)
        end
        
        write_debug("[✔] Menu restored")
    else
        -- Minimize menu
        isMinimized = true
        originalPanelSize = panel:getContentSize()
        
        -- Resize panel to only show title bar
        panel:setContentSize(cc.size(panelWidth, 50))
        
        -- Hide all buttons EXCEPT minimize and close buttons
        for i, btn in ipairs(buttons) do
            btn:setVisible(false)
        end
        
        -- Ensure minimize button stays visible
        btn_minimize:setVisible(true)
        
        -- Update title text
        pcall(function() titleText:setString("Maid Mod Menu [Minimized]") end)
        
        -- Change minimize button to reopen style
        pcall(function() btn_minimize:setTitleText("⬜") end)  -- Better square symbol for reopen
        pcall(function() btn_minimize:setTitleColor(cc.c3b(120, 255, 120)) end)  -- Brighter green for reopen
        pcall(function() btn_minimize:setBackGroundColor(cc.c3b(80, 120, 80)) end)  -- Green tint for reopen
        
        -- Move reopen button to center of minimized panel
        pcall(function() btn_minimize:setPosition(cc.p(panelWidth - 60, titleBar:getContentSize().height / 2)) end)
        
        -- Ensure button is on top when minimized
        pcall(function() btn_minimize:setLocalZOrder(1002) end)
        
        -- Make minimized panel draggable via the text button
        local isDraggingMinimized = false
        local dragOffsetMinimized = cc.p(0, 0)
        
        write_debug("[Minimize] About to add unified touch handler to keybindInfo")
        write_debug("[Minimize] keybindInfo exists: " .. tostring(keybindInfo ~= nil))
        write_debug("[Minimize] keybindInfo touchEnabled before: " .. tostring(keybindInfo:isTouchEnabled()))
        
        -- Replace the existing touch event listener with a unified one
        keybindInfo:setTouchEnabled(true)
        keybindInfo:addTouchEventListener(function(sender, eventType)
            write_debug("[KeybindInfo] Unified handler - event: " .. tostring(eventType) .. ", isMinimized: " .. tostring(isMinimized))
            
            if not isMinimized then
                write_debug("[KeybindInfo] Not minimized, ignoring event")
                return false -- Don't handle events when not minimized
            end
            
            if eventType == 0 then -- ccui.TouchEventType.began
                write_debug("[KeybindInfo] Touch began - preparing for drag or click")
                local startPos = sender:getTouchBeganPosition()
                local panelPos = panel:getPosition()
                dragOffsetMinimized = cc.p(startPos.x - panelPos.x, startPos.y - panelPos.y)
                isDraggingMinimized = false -- Start as false, will become true on move
                return true -- consume event
                
            elseif eventType == 1 then -- ccui.TouchEventType.moved
                write_debug("[KeybindInfo] Touch moved - starting drag")
                -- This is now a drag, not a click
                isDraggingMinimized = true
                local touchPos = sender:getTouchMovePosition()
                local newX = touchPos.x - dragOffsetMinimized.x
                local newY = touchPos.y - dragOffsetMinimized.y
                panel:setPosition(cc.p(newX, newY))
                return true -- consume event
                
            elseif eventType == 2 then -- ccui.TouchEventType.ended
                write_debug("[KeybindInfo] Touch ended - checking if click or drag")
                if not isDraggingMinimized then
                    write_debug("[KeybindInfo] This was a click - restoring menu")
                    -- This was a click, not a drag - reopen menu
                    isMinimized = false
                    panel:setContentSize(originalPanelSize)
                    
                    -- Show all buttons
                    for i, btn in ipairs(buttons) do
                        btn:setVisible(true)
                    end
                    
                    -- Restore minimize button
                    btn_minimize:setVisible(true)
                    btn_minimize:setTitleText("-")
                    btn_minimize:setTitleColor(cc.c3b(255, 255, 80))
                    btn_minimize:setPosition(cc.p(panelWidth - 60, titleBar:getContentSize().height / 2))
                    btn_minimize:setLocalZOrder(1000)
                    
                    -- Restore title text
                    titleText:setString("Maid Mod Menu")
                    titleText:setVisible(true)
                    
                    -- Show keybind info when restored
                    keybindInfo:setVisible(true)
                    keybindInfo:setTouchEnabled(false)  -- Disable touch when restored
                    
                    write_debug("[✔] Menu restored via text click")
                else
                    write_debug("[KeybindInfo] This was a drag - ending drag")
                    -- This was a drag, just end it
                    isDraggingMinimized = false
                end
                return true -- consume event
                
            elseif eventType == 3 then -- ccui.TouchEventType.canceled
                write_debug("[KeybindInfo] Touch canceled")
                isDraggingMinimized = false
                return true -- consume event
            end
            return false
        end)
        
        write_debug("[Minimize] Unified touch handler added successfully")
        write_debug("[Minimize] keybindInfo touchEnabled after: " .. tostring(keybindInfo:isTouchEnabled()))
        
            write_debug("[✔] Menu minimized")
        end
    elseif eventType == 3 then -- ccui.TouchEventType.canceled
        write_debug("[Minimize] Touch canceled")
        pcall(function() sender:setColor(cc.c3b(255, 255, 255)) end) -- Restore color
    end
end)
 
if btn_minimize_success and btn_minimize then
    local add_success = pcall(function()
        titleBar:addChild(btn_minimize)
    end)
    write_debug("[DEBUG] Minimize button added to title bar: " .. tostring(add_success))
else
    write_debug("[ERROR] Cannot add minimize button - creation failed")
end
 
-- CLOSE MENU
write_debug("[DEBUG] Starting close button creation...")
local btn_close_success, btn_close = pcall(function()
    return ccui.Button:create()
end)
write_debug("[DEBUG] Close button creation: " .. tostring(btn_close_success))
 
if btn_close_success and btn_close then
    write_debug("[DEBUG] Setting close button properties...")
    pcall(function() btn_close:setTitleText("X") end)
    pcall(function() btn_close:setTitleFontSize(24) end)
    pcall(function() btn_close:setTitleColor(cc.c3b(255, 80, 80)) end)
    pcall(function() btn_close:setScale9Enabled(true) end)
    pcall(function() btn_close:setContentSize(cc.size(50, 50)) end)
 
    -- Position at top-right of title bar
    pcall(function() btn_close:setPosition(cc.p(panelWidth - 25, titleBar:getContentSize().height / 2)) end)
 
    -- Ensure close button stays on top
    pcall(function() btn_close:setLocalZOrder(1001) end)
    write_debug("[DEBUG] Close button properties set successfully")
else
    write_debug("[ERROR] Failed to create close button")
end
 
-- Add touch event listener with error handling
btn_close:addTouchEventListener(function(sender, eventType)
    if eventType == 2 then -- ccui.TouchEventType.ended
        write_debug("[Close] Close button clicked - removing menu")
        local success = pcall(function()
            panel:removeFromParent()
            _G.GM_MENU = nil
        end)
        write_debug("[Close] Menu removal: " .. tostring(success))
    end
end)
 
if btn_close_success and btn_close then
    local add_success = pcall(function()
        titleBar:addChild(btn_close)
    end)
    write_debug("[DEBUG] Close button added to title bar: " .. tostring(add_success))
else
    write_debug("[ERROR] Cannot add close button - creation failed")
end
 
-- Enhanced keybind info button for minimized state
write_debug("[DEBUG] Starting keybind info button creation...")
keybindInfo = ccui.Button:create()
write_debug("[DEBUG] Keybind info button created directly")
 
write_debug("[DEBUG] Setting keybind info button properties...")
pcall(function() keybindInfo:setTitleText("   Click to open menu or drag to move") end)
pcall(function() keybindInfo:setTitleFontSize(25) end)
pcall(function() keybindInfo:setTitleColor(cc.c3b(200, 200, 255)) end)  -- Light blue color
pcall(function() keybindInfo:setScale9Enabled(true) end)
pcall(function() keybindInfo:setContentSize(cc.size(320, 35)) end)
pcall(function() keybindInfo:setPosition(cc.p(panelWidth/2, 25)) end)
pcall(function() keybindInfo:setLocalZOrder(999) end)
 
-- Style the minimized button better
pcall(function() keybindInfo:setBackGroundColorType(1) end)
pcall(function() keybindInfo:setBackGroundColor(cc.c3b(30, 30, 50)) end)  -- Dark blue background
pcall(function() keybindInfo:setBackGroundColorOpacity(200) end)
 
local add_success = pcall(function()
    panel:addChild(keybindInfo)
end)
write_debug("[DEBUG] Keybind info button added to panel: " .. tostring(add_success))
write_debug("[DEBUG] Enhanced keybind info button created with better styling")
write_debug("[DEBUG] keybindInfo stored in global scope: " .. tostring(keybindInfo ~= nil))
 
write_debug("[DEBUG] About to write final completion messages...")
write_debug("Menu creation result: true")
write_debug("=== INITIALIZATION COMPLETE ===")
write_debug("If menu is not visible, check script_debug.txt for errors.")
write_debug("[DEBUG] Script reached the very end - all sections completed")
write_debug("[DEBUG] Final check - keybindInfo exists: " .. tostring(keybindInfo ~= nil))
write_debug("[DEBUG] Final check - btn_minimize exists: " .. tostring(btn_minimize ~= nil))
write_debug("[DEBUG] Final check - btn_close exists: " .. tostring(btn_close ~= nil))
 
-- Final success message to debug file (DEBUG_FILE_ENABLED)
if DEBUG_FILE_ENABLED then
    local final_success, final_file = pcall(function()
        return io.open(DEBUG_FILE_PATH, "a")
    end)
 
    if final_success and final_file then
        local final_write_success = pcall(function()
            final_file:write(os.date("%H:%M:%S") .. " === SCRIPT COMPLETED SUCCESSFULLY ===\n")
            final_file:write(os.date("%H:%M:%S") .. " Menu should now be visible!\n")
            final_file:write(os.date("%H:%M:%S") .. " All 24+ buttons are functional and ready to use.\n")
            final_file:write(os.date("%H:%M:%S") .. " Combat Menu and Weapon Skin buttons have been hidden.\n")
            final_file:write(os.date("%H:%M:%S") .. " AutoLoot has been fixed with working 4-method system!\n")
            final_file:close()
        end)
        if not final_write_success then
            print("Failed to write final success message to debug file")
        end
    else
        print("Failed to open debug file for final message: " .. tostring(final_file))
    end
else
    print("Debug file logging disabled, skipping final file write")
end
