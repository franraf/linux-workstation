local hl = require("hyprlang")

hl.bind("SUPER", "L", "exec", "pidof hyprlock || hyprlock")
