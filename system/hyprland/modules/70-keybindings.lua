-- Application launcher
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("rofi -show drun"))

-- Notification center
hl.bind("SUPER + N", hl.dsp.exec_cmd("swaync-client -t"))

-- Terminal emulator
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))

-- File manager
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))
