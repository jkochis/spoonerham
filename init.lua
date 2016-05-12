require "caffeine"
require "pomodoor"
require "sizerup"

-- === hot reload config ===

function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")

-- === hard paste ===

hs.hotkey.bind({"cmd", "alt"}, "V", function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

-- === pomodoro ===

-- pomodoro key binding
hs.hotkey.bind({"ctrl","alt"}, '9', function() pom_enable() end)
hs.hotkey.bind({"ctrl","alt"}, '0', function() pom_disable() end)
hs.hotkey.bind({"ctrl","alt","shift"}, '0', function() pom_reset_work() end)