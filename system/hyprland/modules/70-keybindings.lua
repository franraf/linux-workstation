local hl = require("hyprlang")

-- Application launcher
hl.bind("SUPER", "SPACE", "exec", "rofi -show drun")

-- Notification center
hl.bind("SUPER", "N", "exec", "swaync-client -t")

-- Terminal emulator
hl.bind("SUPER", "RETURN", "exec", "kitty")

-- File manager
hl.bind("SUPER", "E", "exec", "thunar")
