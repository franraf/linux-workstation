local hl = require("hyprlang")

-- Canonical session autostart registry.
-- Each configured capability owns one guarded command here.
hl.on("hyprland.start", function()
  hl.exec_cmd("pidof waybar || waybar")
  hl.exec_cmd("pidof hypridle || hypridle")
  hl.exec_cmd("pidof swaync || swaync")
end)
