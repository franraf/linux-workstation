-- Canonical Hyprland configuration entrypoint.
-- Modules are intentionally loaded in numeric responsibility order.

require("modules.10-environment")
require("modules.20-monitor")
require("modules.30-input")
require("modules.40-general")
require("modules.50-autostart")
require("modules.60-session-lock")
require("modules.70-keybindings")
require("modules.80-appearance")
