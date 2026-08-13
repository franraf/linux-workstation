-- Application launcher
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("rofi -show drun"))

-- Notification center
hl.bind("SUPER + N", hl.dsp.exec_cmd("swaync-client -t"))

-- Terminal emulator
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))

-- File manager
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))

-- Window management
hl.bind("SUPER + Q", hl.dsp.window.close({}))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))

-- Workspace navigation
for workspace = 1, 9 do
  hl.bind("SUPER + " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  hl.bind("SUPER + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = true }))
end
