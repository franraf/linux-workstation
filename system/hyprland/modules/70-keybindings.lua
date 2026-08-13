local hl = require("hyprlang")

-- Application launcher
hl.bind("SUPER", "SPACE", "exec", "rofi -show drun")

-- Notification center
hl.bind("SUPER", "N", "exec", "swaync-client -t")
