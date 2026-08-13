-- Visual appearance baseline.
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
    ["col.active_border"] = "#7aa2f7ff",
    ["col.inactive_border"] = "#3b4048ff",
  },
  decoration = {
    rounding = 8,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    fullscreen_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = "#00000055",
    },
    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      new_optimizations = true,
      xray = false,
      special = false,
      popups = true,
      noise = 0.01,
      contrast = 0.95,
      brightness = 0.90,
      vibrancy = 0.10,
    },
  },
  animations = {
    enabled = true,
  },
  misc = {
    background_color = "#1a1b26ff",
  },
})
