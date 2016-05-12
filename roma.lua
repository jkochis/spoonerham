-- roma module

--------------------------------------------------------------------------------
-- Configuration variables
--------------------------------------------------------------------------------
local roma={}
roma.bar = {
  indicator_height = 0.2, -- ratio from the height of the menubar (0..1)
  indicator_alpha  = 0.3,
  indicator_in_all_spaces = true,
  color_time_remaining = hs.drawing.color.green,
  color_time_used      = hs.drawing.color.red,
  
  c_left = hs.drawing.rectangle(hs.geometry.rect(0,0,0,0)),
  c_used = hs.drawing.rectangle(hs.geometry.rect(0,0,0,0))
}

roma.config = {
  enable_color_bar = true,
  work_period_sec  = 25 * 60,
  rest_period_sec  = 5 * 60,
  
}

roma.var = { 
  is_active        = false,
  disable_count    = 0,
  work_count       = 0,
  curr_active_type = "work", -- {"work", "rest"}
  time_left        = roma.config.work_period_sec,
  max_time_sec     = roma.config.work_period_sec
}

--------------------------------------------------------------------------------
-- Color bar for romaodoor
--------------------------------------------------------------------------------

function roma_del_indicators()
  roma.bar.c_left:delete()
  roma.bar.c_used:delete()
end

function roma_draw_on_menu(target_draw, screen, offset, width, fill_color)
  local screeng                  = screen:fullFrame()
  local screen_frame_height      = screen:frame().y
  local screen_full_frame_height = screeng.y
  local height_delta             = screen_frame_height - screen_full_frame_height
  local height                   = roma.bar.indicator_height * (height_delta)

  target_draw:setSize(hs.geometry.rect(screeng.x + offset, screen_full_frame_height, width, height))
  target_draw:setTopLeft(hs.geometry.point(screeng.x + offset, screen_full_frame_height))
  target_draw:setFillColor(fill_color)
  target_draw:setFill(true)
  target_draw:setAlpha(roma.bar.indicator_alpha)
  target_draw:setLevel(hs.drawing.windowLevels.overlay)
  target_draw:setStroke(false)
  if roma.bar.indicator_in_all_spaces then
    target_draw:setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
  end
  target_draw:show()
end

function roma_draw_indicator(time_left, max_time)  
  local main_screen = hs.screen.mainScreen()
  local screeng     = main_screen:fullFrame()
  local time_ratio  = time_left / max_time
  local width       = math.ceil(screeng.w * time_ratio)
  local left_width  = screeng.w - width

  roma_draw_on_menu(roma.bar.c_left, main_screen, left_width, width,      roma.bar.color_time_remaining)
  roma_draw_on_menu(roma.bar.c_used, main_screen, 0,          left_width, roma.bar.color_time_used)  
  
end
--------------------------------------------------------------------------------

-- update display
local function roma_update_display()
  local time_min = math.floor( (roma.var.time_left / 60))
  local time_sec = roma.var.time_left - (time_min * 60)
  local str = string.format ("[%s|%02d:%02d|#%02d]", roma.var.curr_active_type, time_min, time_sec, roma.var.work_count)
  roma_menu:setTitle(str)
end

-- stop the clock
-- Stateful:
-- * Disabling once will pause the countdown
-- * Disabling twice will reset the countdown
-- * Disabling trice will shut down and hide the romaodoro timer
function roma_disable()
  
  local roma_was_active = roma.var.is_active
  roma.var.is_active = false

  if (roma.var.disable_count == 0) then
     if (roma_was_active) then
      roma_timer:stop()
    end
  elseif (roma.var.disable_count == 1) then
    roma.var.time_left         = roma.config.work_period_sec
    roma.var.curr_active_type  = "work"
    roma_update_display()
  elseif (roma.var.disable_count >= 2) then
    if roma_menu == nil then 
      roma.var.disable_count = 2
      return
    end

    roma_menu:delete()
    roma_menu = nil
    roma_timer:stop()
    roma_timer = nil
    roma_del_indicators()
  end

  roma.var.disable_count = roma.var.disable_count + 1

end

-- update romaodoro timer
local function roma_update_time()
  if roma.var.is_active == false then
    return
  else
    roma.var.time_left = roma.var.time_left - 1

    if (roma.var.time_left <= 0 ) then
      roma_disable()
      if roma_curr_active_type == "work" then 
        hs.alert.show("Work Complete!", 2)
        roma.var.work_count        =  roma.var.work_count + 1 
        roma.var.curr_active_type  = "rest"
        roma.var.time_left         = roma.config.rest_period_sec
        roma.var.max_time_sec      = roma.config.rest_period_sec
      else 
          hs.alert.show("Done resting", 2)
          roma.var.curr_active_type  = "work"
          roma.var.time_left         = roma.config.work_period_sec
          roma.var._max_time_sec     = roma.config.work_period_sec 
      end
    end

    -- draw color bar indicator, if enabled.
    if (roma.config.enable_color_bar == true) then
      roma_draw_indicator(roma.var.time_left, roma.var.max_time_sec)
    end

  end
end

-- update menu display
local function roma_update_menu()
  roma_update_time()
  roma_update_display()
end

local function roma_create_menu(roma_origin)
  if roma_menu == nil then
    roma_menu = hs.menubar.new()
  end
end

-- start the romaodoro timer
function roma_enable()
  roma.var.disable_count = 0;
  if (roma_is_active) then
    return
  elseif roma_timer == nil then
    roma_create_menu()
    --roma_init_indicator()
    roma_timer = hs.timer.new(1, roma_update_menu)
  end

  roma.var.is_active = true
  roma_timer:start()
end

-- reset work count
-- TODO - reset automatically every day
function roma_reset_work()
  roma.var.work_count = 0;
end
-- Use examples:

-- init romaodoro -- show menu immediately
-- roma_create_menu()
-- roma_update_menu()

-- show menu only on first roma_enable
--hs.hotkey.bind(mash, '9', function() roma_enable() end)
--hs.hotkey.bind(mash, '0', function() roma_disable() end)