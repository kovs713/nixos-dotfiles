local function bind(key, dispatcher, options)
	hl.bind(key, dispatcher, options)
end

bind("SUPER + Q", hl.dsp.exec_cmd("ghostty"))
bind("SUPER + C", hl.dsp.window.close())
bind("SUPER + F", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + P", hl.dsp.window.fullscreen({ action = "toggle" }))
bind("SUPER + R", hl.dsp.layout("colresize +conf"))
bind("SUPER + X", hl.dsp.exec_cmd("voxtype record toggle"))
bind("SUPER + B", hl.dsp.exec_cmd("qs ipc call bar toggleAutoReveal"))
bind("SUPER + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
bind("SUPER + N", hl.dsp.exec_cmd("qs ipc call notes toggle"))
bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("qs ipc call nightlight toggle"))
bind("SUPER + CTRL + E", hl.dsp.exec_cmd("qs ipc call emoji toggle"))
bind("SUPER + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
bind("SUPER + S", hl.dsp.workspace.toggle_special("pocket"))
bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:pocket" }))

bind("ALT + Print", hl.dsp.exec_cmd("shot pick"))
bind("Print", hl.dsp.exec_cmd("shot clipboard"))
bind("SUPER + Print", hl.dsp.exec_cmd("shot annotate"))
bind("CTRL + Print", hl.dsp.exec_cmd("screenrec av"))
bind("CTRL + ALT + Print", hl.dsp.exec_cmd("screenrec audio"))

bind("SUPER + mouse:272", hl.dsp.window.drag())
bind("SUPER + mouse:273", hl.dsp.window.resize())

bind("XF86Tools", hl.dsp.exec_cmd('test -r /tmp/olay-overlay.pid && kill -USR2 "$(cat /tmp/olay-overlay.pid)"'))
bind("XF86Launch5", hl.dsp.exec_cmd('test -r /tmp/olay-overlay.pid && kill -USR1 "$(cat /tmp/olay-overlay.pid)"'))
bind("XF86Launch6", hl.dsp.exec_cmd('test -r /tmp/olay-overlay.pid && kill -IO "$(cat /tmp/olay-overlay.pid)"'))

bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("backlight up"), { repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("backlight down"), { repeating = true })

for i = 1, 5 do
	bind("SUPER + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
	bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

bind("SUPER + h", hl.dsp.focus({ direction = "l" }))
bind("SUPER + j", hl.dsp.focus({ direction = "d" }))
bind("SUPER + k", hl.dsp.focus({ direction = "u" }))
bind("SUPER + l", hl.dsp.focus({ direction = "r" }))

hl.config({
	animations = { enabled = false },
	binds = { hide_special_on_workspace_change = true },
	cursor = { no_hardware_cursors = 1 },
	decoration = {
		blur = { enabled = false },
		dim_special = 0.45,
		rounding = 0,
		shadow = { enabled = false },
	},
	general = {
		border_size = 2,
		["col.active_border"] = "rgb(6e6e6e)",
		["col.inactive_border"] = "rgb(808080)",
		gaps_in = 0,
		gaps_out = 0,
		layout = "scrolling",
	},
	group = {
		["col.border_active"] = "rgb(6e6e6e)",
		["col.border_inactive"] = "rgb(808080)",
		["col.border_locked_active"] = "rgb(3e3e3e)",
		groupbar = {
			["col.active"] = "rgb(6e6e6e)",
			["col.inactive"] = "rgb(808080)",
			text_color = "rgb(000000)",
		},
	},
	input = {
		kb_layout = "us,ru",
		kb_options = "grp:alt_space_toggle",
		repeat_delay = 500,
		repeat_rate = 25,
	},
})

dofile(os.getenv("HOME") .. "/.config/hypr/theme.lua")

hl.workspace_rule({
	workspace = "special:pocket",
	layout = "dwindle",
	gaps_out = 80,
	gaps_in = 8,
})

hl.window_rule({
	name = "anki",
	match = { class = "^(anki|Anki|net\\.ankiweb\\.Anki)$" },
	size = "1400 750",
	center = true,
	float = true,
})

hl.layer_rule({
	name = "gtk-layer-shell-olay",
	match = { namespace = "^(olay-overlay)$" },
	screen_share_mode = "omit",
	blur = true,
})

hl.monitor({ output = "", mode = "highrr", position = "auto", scale = "1" })
