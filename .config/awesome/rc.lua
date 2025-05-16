-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
local lain = require("lain")
-- Theme handling library
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local chosen_theme = "catppuccin"
local theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme)
beautiful.init(theme_path)
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors,
	})
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		-- Make sure we don't go into an endless error loop
		if in_error then
			return
		end
		in_error = true

		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err),
		})
		in_error = false
	end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.

-- This is used later as the default terminal and editor to run.
local terminal = "~/.local/kitty.app/bin/kitty"
local browser = "firefox"
local file_explorer = "yazi"
local file_explorer_cmd = terminal .. " " .. file_explorer
local editor = "nvim"
local editor_cmd = terminal .. " -e " .. editor
local app_runner_cmd = "/home/k/.config/rofi/launchers/type-1/launcher.sh"
local power_menu_cmd = "/home/k/.config/rofi/powermenu/type-3/powermenu.sh"
local screenshot_cmd = "/home/k/.local/bin/screenshot"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
	awful.layout.suit.spiral,
	--	awful.layout.suit.spiral.dwindle,
	awful.layout.suit.floating,
	--	awful.layout.suit.tile,
	--	awful.layout.suit.tile.left,
	--	awful.layout.suit.tile.bottom,
	--	awful.layout.suit.tile.top,
	--	awful.layout.suit.fair,
	--	awful.layout.suit.fair.horizontal,
	--	awful.layout.suit.max,
	--	awful.layout.suit.max.fullscreen,
	--	awful.layout.suit.magnifier,
	--	awful.layout.suit.corner.nw,
	-- awful.layout.suit.corner.ne,
	-- awful.layout.suit.corner.sw,
	-- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
	{
		"hotkeys",
		function()
			hotkeys_popup.show_help(nil, awful.screen.focused())
		end,
	},
	{ "manual", terminal .. " -e man awesome" },
	{ "edit config", editor_cmd .. " " .. awesome.conffile },
	{ "restart", awesome.restart },
	{
		"quit",
		function()
			awesome.quit()
		end,
	},
}

local editormenu = {
	{ "neovim", "kitty -e nvim" },
}

local myexitmenu = {
	{
		"logout",
		function()
			awesome.quit()
		end,
	},
	{ "reboot", "sudo systemctl reboot" },
	{ "suspend", "sudo systemctl suspend" },
	{ "shutdown", "sudo systemctl poweroff" },
}

local mymainmenu = awful.menu({
	items = {
		{ "editors", editormenu },
		{ "awesome", myawesomemenu },
		{ "exit options", myexitmenu },
	},
})
local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }
local mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibar
-- Create a textclock widget
local mytextclock = wibox.widget.textclock("%R")

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
	awful.button({}, 1, function(t)
		t:view_only()
	end),
	awful.button({ modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({ modkey }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({}, 4, function(t) end),
	awful.button({}, 5, function(t) end)
)

local tasklist_buttons = gears.table.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c:emit_signal("request::activate", "tasklist", { raise = true })
		end
	end),
	awful.button({}, 3, function()
		awful.menu.client_list({ theme = { width = 250 } })
	end),
	awful.button({}, 4, function()
		awful.client.focus.byidx(1)
	end),
	awful.button({}, 5, function()
		awful.client.focus.byidx(-1)
	end)
)

local markup = lain.util.markup
local battery = require("awesome-wm-widgets.battery-widget.battery")
local brightness = require("awesome-wm-widgets.brightness-widget.brightness")
local calendar_widget = require("awesome-wm-widgets.calendar-widget.calendar")
local calendar = calendar_widget({
	placement = "center",
	start_sunday = true,
	theme = "catppuccin",
})
local vol = lain.widget.alsa({
	timeout = 1,
	settings = function()
		local font = beautiful.font
		local color = "#ffffff"
		local level = volume_now.level
		local icon
		if volume_now.status == "off" then
			level = ""
			icon = "婢"
			color = beautiful.fg_normal
		else
			level = level .. "%"
			icon = "奔 "
			color = beautiful.fg_normal
		end
		widget:set_markup(markup.fontfg(font, color, icon .. level))
	end,
})
--[[
local cpu = lain.widget.cpu({
	timeout = 1,
	settings = function()
		widget:set_markup(markup.fontfg(beautiful.font, beautiful.yellow, " " .. cpu_now.usage .. "%"))
	end,
})

local mem = lain.widget.mem({
	timeout = 1,
	settings = function()
		widget:set_markup(markup.fontfg(beautiful.font, beautiful.blue, " " .. mem_now.perc .. "%"))
	end,
})
--]]
-- local systray = wibox.widget.systray()

local mpris = require("themes.default.mpris")
-- local mpd = require("themes.default.mpdarc")
local spacer = wibox.widget.textbox("")
spacer.markup = '<span foreground="' .. beautiful.light_grey .. '"> | </span>'

local record_widget = wibox.widget.textbox("")

record_widget.update = function()
	awful.spawn.easy_async_with_shell("sleep .1; cat ~/.config/awesome/recordicon", function(out)
		record_widget.markup = '<span foreground="' .. beautiful.fg_normal .. '">' .. out .. "</span>"
	end)
end
record_widget:buttons((gears.table.join(awful.button({}, 1, function()
	-- Call script to toggle recording
	awful.spawn.with_shell("~/.local/bin/record")
	record_widget.update()
end))))

record_widget.update()
-- Icons for tags
local tag1 = "  "
local tag2 = " 󰌢 "
local tag3 = "  "
local tag4 = "  "
local tag5 = "  "
local tag6 = "  "
local tag7 = "  "
local tag8 = "  "
local tag9 = "  "
awful.screen.connect_for_each_screen(function(s)
	-- Wallpaper
	--set_wallpaper(s)

	-- Each screen has its own tag table.
	awful.tag.add(tag1, {
		layout = awful.layout.layouts[1],
		master_fill_policy = "master_width_factor",
		screen = s,
		selected = true,
	})

	awful.tag.add(tag2, {
		layout = awful.layout.layouts[1],
		master_fill_policy = "master_width_factor",
		screen = s,
	})

	awful.tag.add(tag3, {
		layout = awful.layout.layouts[1],
		master_fill_policy = "master_width_factor",
		screen = s,
	})

	awful.tag.add(tag4, {
		layout = awful.layout.layouts[1],
		master_fill_policy = "master_width_factor",
		screen = s,
	})

	awful.tag.add(tag5, {
		layout = awful.layout.layouts[1],
		master_fill_policy = "master_width_factor",
		screen = s,
	})
	--[[
	awful.tag.add(tag6, {
		layout = awful.layout.layouts[5],
		master_fill_policy = "master_width_factor",
		screen = s,
	})

	awful.tag.add(tag7, {
		layout = awful.layout.layouts[1],
		master_fill_policy = "master_width_factor",
		screen = s,
	})

	awful.tag.add(tag8, {
		layout = awful.layout.layouts[1],
		master_fill_policy = "master_width_factor",
		screen = s,
	})

	awful.tag.add(tag9, {
		layout = awful.layout.layouts[1],
		master_fill_policy = "master_width_factor",
		screen = s,
	})--]]

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contain an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(gears.table.join(
		awful.button({}, 1, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 3, function()
			awful.layout.inc(-1)
		end),
		awful.button({}, 4, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 5, function()
			awful.layout.inc(-1)
		end)
	))
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist({
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = taglist_buttons,
	})

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist({
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = tasklist_buttons,
	})

	-- Create the wibox
	s.mywibox = awful.wibox({
		screen = s,
		--		border_color = beautiful.blue,
		--		border_width = beautiful.border_width,
	})

	-- Add widgets to the wibox

	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		expand = "none",
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			s.mytaglist,
		},
		{ -- Center widgets
			layout = wibox.layout.fixed.horizontal,
			mytextclock,
		},
		{ -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			record_widget,
			spacer,
			vol,
			spacer,
			battery({
				font = beautiful.font,
				show_current_level = true,
				display_notification = true,
			}),
			spacer,
			brightness({
				program = "xbacklight",
				type = "icon_and_text",
				timeout = 1,
				percentage = true,
			}),
			spacer,
			-- s.mylayoutbox,
		},
	})
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
	awful.button({}, 3, function()
		mymainmenu:toggle()
	end),
	awful.button({}, 4, awful.tag.viewnext),
	awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
	-- Tag hotkeys
	awful.key({ modkey }, "Left", awful.tag.viewprev, { description = "view previous", group = "tag" }),
	awful.key({ modkey }, "Right", awful.tag.viewnext, { description = "view next", group = "tag" }),
	awful.key({ modkey }, "Escape", awful.tag.history.restore, { description = "go back", group = "tag" }),

	-- Screen hotkeys
	awful.key({ modkey, "Control" }, "j", function()
		awful.screen.focus_relative(1)
	end, { description = "focus the next screen", group = "screen" }),
	awful.key({ modkey, "Control" }, "k", function()
		awful.screen.focus_relative(-1)
	end, { description = "focus the previous screen", group = "screen" }),

	-- Awesome hotkeys
	awful.key({ modkey }, "q", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),
	awful.key({ modkey, "Shift" }, "w", function()
		mymainmenu:show()
	end, { description = "show main menu", group = "awesome" }),
	awful.key({ modkey, "Control" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
	awful.key({ modkey, "Shift" }, "q", function()
		awful.spawn.with_shell(power_menu_cmd)
	end, { description = "quit awesome", group = "awesome" }),

	-- Launchers hotkeys
	awful.key({ modkey }, "Return", function()
		awful.spawn.with_shell(terminal)
	end, { description = "open a terminal", group = "launcher" }),
	awful.key({ modkey }, "s", function()
		awful.spawn.with_shell(browser)
	end, { description = "open the browser", group = "launcher" }),
	awful.key({ modkey }, "e", function()
		awful.spawn.with_shell(file_explorer_cmd)
	end, { description = "open the file explorer", group = "launcher" }),
	awful.key({ modkey }, "r", function()
		awful.spawn.with_shell(app_runner_cmd)
	end, { description = "run prompt", group = "launcher" }),

	-- Media hotkeys
	awful.key({ modkey, "Shift" }, "s", function()
		awful.spawn.with_shell(screenshot_cmd)
	end, { description = "screenshot", group = "multimedia" }),
	awful.key({ modkey }, "p", function()
		awful.spawn.with_shell("playerctl play-pause")
	end, { description = "pause/play", group = "multimedia" }),
	awful.key({}, "XF86AudioMute", function()
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false)
		vol.update()
	end, { description = "toggle mute", group = "multimedia" }),
	awful.key({}, "XF86AudioRaiseVolume", function()
		awful.spawn("pactl -- set-sink-volume @DEFAULT_SINK@ +5%", false)
		vol.update()
	end, { description = "brightness up", group = "multimedia" }),
	awful.key({}, "XF86MonBrightnessDown", function()
		brightness.dec(10)
	end, { description = "brightness down", group = "multimedia" }),
	awful.key({}, "XF86MonBrightnessUp", function()
		brightness.inc(10)
	end, { description = "volume up", group = "multimedia" }),
	awful.key({}, "XF86AudioLowerVolume", function()
		awful.spawn("pactl -- set-sink-volume @DEFAULT_SINK@ -5%", false)
		vol.update()
	end, { description = "volume down", group = "multimedia" }),

	-- Layout hotkeys
	awful.key({ modkey }, "l", function()
		awful.tag.incmwfact(0.05)
	end, { description = "increase master width factor", group = "layout" }),
	awful.key({ modkey }, "h", function()
		awful.tag.incmwfact(-0.05)
	end, { description = "decrease master width factor", group = "layout" }),
	awful.key({ modkey, "Shift" }, "h", function()
		awful.tag.incnmaster(1, nil, true)
	end, { description = "increase the number of master clients", group = "layout" }),
	awful.key({ modkey, "Shift" }, "l", function()
		awful.tag.incnmaster(-1, nil, true)
	end, { description = "decrease the number of master clients", group = "layout" }),
	awful.key({ modkey, "Control" }, "h", function()
		awful.tag.incncol(1, nil, true)
	end, { description = "increase the number of columns", group = "layout" }),
	awful.key({ modkey, "Control" }, "l", function()
		awful.tag.incncol(-1, nil, true)
	end, { description = "decrease the number of columns", group = "layout" }),
	awful.key({ modkey }, "space", function()
		awful.layout.inc(1)
	end, { description = "select next", group = "layout" }),
	awful.key({ modkey, "Shift" }, "space", function()
		awful.layout.inc(-1)
	end, { description = "select previous", group = "layout" }),

	-- Window hotkeys
	awful.key({ modkey, "Shift" }, "j", function()
		awful.client.swap.byidx(1)
	end, { description = "swap with next client by index", group = "client" }),
	awful.key({ modkey, "Shift" }, "k", function()
		awful.client.swap.byidx(-1)
	end, { description = "swap with previous client by index", group = "client" }),
	awful.key({ modkey }, "u", awful.client.urgent.jumpto, { description = "jump to urgent client", group = "client" }),
	awful.key({ modkey }, "Tab", function()
		awful.client.focus.history.previous()
		if client.focus then
			client.focus:raise()
		end
	end, { description = "go back", group = "client" }),
	awful.key({ modkey }, "j", function()
		awful.client.focus.byidx(1)
	end, { description = "focus next by index", group = "client" }),
	awful.key({ modkey }, "k", function()
		awful.client.focus.byidx(-1)
	end, { description = "focus previous by index", group = "client" }),
	awful.key({ modkey, "Control" }, "n", function()
		local c = awful.client.restore()
		-- Focus restored client
		if c then
			c:emit_signal("request::activate", "key.unminimize", { raise = true })
		end
	end, { description = "restore minimized", group = "client" })
)

clientkeys = gears.table.join(
	awful.key({ modkey }, "f", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, { description = "toggle fullscreen", group = "client" }),
	awful.key({ modkey }, "w", function(c)
		c:kill()
	end, { description = "close", group = "client" }),
	awful.key(
		{ modkey, "Control" },
		"space",
		awful.client.floating.toggle,
		{ description = "toggle floating", group = "client" }
	),
	awful.key({ modkey, "Control" }, "Return", function(c)
		c:swap(awful.client.getmaster())
	end, { description = "move to master", group = "client" }),
	awful.key({ modkey }, "o", function(c)
		c:move_to_screen()
	end, { description = "move to screen", group = "client" }),
	awful.key({ modkey }, "t", function(c)
		c.ontop = not c.ontop
	end, { description = "toggle keep on top", group = "client" }),
	awful.key({ modkey }, "n", function(c)
		-- The client currently has the input focus, so it cannot be
		-- minimized, since minimized clients can't have the focus.
		c.minimized = true
	end, { description = "minimize", group = "client" }),
	awful.key({ modkey }, "m", function(c)
		c.maximized = not c.maximized
		c:raise()
	end, { description = "(un)maximize", group = "client" }),
	awful.key({ modkey, "Control" }, "m", function(c)
		c.maximized_vertical = not c.maximized_vertical
		c:raise()
	end, { description = "(un)maximize vertically", group = "client" }),
	awful.key({ modkey, "Shift" }, "m", function(c)
		c.maximized_horizontal = not c.maximized_horizontal
		c:raise()
	end, { description = "(un)maximize horizontally", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = gears.table.join(
		globalkeys,
		-- View tag only.
		awful.key({ modkey }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, { description = "view tag #" .. i, group = "tag" }),
		-- Toggle tag display.
		awful.key({ modkey, "Control" }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end, { description = "toggle tag #" .. i, group = "tag" }),
		-- Move client to tag.
		awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end, { description = "move focused client to tag #" .. i, group = "tag" }),
		-- Toggle tag on focused client.
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end, { description = "toggle focused client on tag #" .. i, group = "tag" })
	)
end

clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
	end),
	awful.button({ modkey }, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.move(c)
	end),
	awful.button({ modkey }, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.resize(c)
	end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
		},
	},

	-- Floating clients.
	{
		rule_any = {
			instance = {
				"DTA", -- Firefox addon DownThemAll.
				"copyq", -- Includes session name in class.
				"pinentry",
			},
			class = {
				"Arandr",
				"Blueman-manager",
				"Gpick",
				"Kruler",
				"MessageWin", -- kalarm.
				"Sxiv",
				"Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
				"Wpa_gui",
				"veromix",
				"xtightvncviewer",
			},

			-- Note that the name property shown in xprop might be set slightly after creation of the client
			-- and the name shown there might not match defined rules here.
			name = {
				"Event Tester", -- xev.
			},
			role = {
				"AlarmWindow", -- Thunderbird's calendar.
				"ConfigManager", -- Thunderbird's about:config.
				"pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
			},
		},
		properties = { floating = true },
	},
	--[[
	-- No border on specified
	{
		rule_any = { class = { "Spotify", "discord" } },
		properties = { border_width = 0 },
	},
	--]]
	-- Spotify
	{
		rule = { class = "Spotify" },
		properties = { tag = tag4 },
	},

	-- Discord
	{
		rule = { class = "discord" },
		properties = { tag = tag3 },
	},

	-- Add titlebars to and dialogs
	-- { rule_any = { type = { "dialog" } }, properties = { titlebars_enabled = true } },
	-- Remove titlebars from everything
	{ rule_any = {}, properties = { titlebars_enabled = false } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
	-- Set the windows at the slave,
	-- i.e. put it at the end of others instead of setting it master.
	-- if not awesome.startup then awful.client.setslave(c) end

	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		-- Prevent clients from being unreachable after screen count changes.
		awful.placement.no_offscreen(c)
	end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
	-- Ignore titlebars if disabled
	if not c.titlebars_enabled then
		return
	end
	-- buttons for the titlebar
	local buttons = gears.table.join(
		awful.button({}, 1, function()
			c:emit_signal("request::activate", "titlebar", { raise = true })
			awful.mouse.client.move(c)
		end),
		awful.button({}, 3, function()
			c:emit_signal("request::activate", "titlebar", { raise = true })
			awful.mouse.client.resize(c)
		end)
	)

	awful.titlebar(c):setup({
		{ -- Left
			awful.titlebar.widget.iconwidget(c),
			buttons = buttons,
			layout = wibox.layout.fixed.horizontal,
		},
		{ -- Middle
			{ -- Title
				align = "center",
				widget = awful.titlebar.widget.titlewidget(c),
			},
			buttons = buttons,
			layout = wibox.layout.flex.horizontal,
		},
		{ -- Right
			awful.titlebar.widget.floatingbutton(c),
			awful.titlebar.widget.maximizedbutton(c),
			awful.titlebar.widget.stickybutton(c),
			awful.titlebar.widget.ontopbutton(c),
			awful.titlebar.widget.closebutton(c),
			layout = wibox.layout.fixed.horizontal(),
		},
		layout = wibox.layout.align.horizontal,
	})
end)

-- Enable sloppy focus, so that focus follows mouse.
--[[
client.connect_signal("mouse::enter", function(c)
	c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)
--]]
client.connect_signal("property::floating", function(c)
	if c.floating then
		awful.titlebar.show(c)
	else
		awful.titlebar.hide(c)
	end
end)

--[[
-- No borders when rearranging only 1 non-floating or maximized client
screen.connect_signal("arrange", function(s)
	local only_one = #s.tiled_clients == 1
	for _, c in pairs(s.clients) do
		if only_one and not c.floating or c.maximized then
			c.border_width = 0
		else
			c.border_width = beautiful.border_width -- your border width
		end
	end
end)
--]]

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- }}}
client.connect_signal("property::maximized", function(c)
	if c.maximized then
		c.border_width = 0
	else
		c.border_width = beautiful.border_width
	end
end)

mytextclock:connect_signal("mouse::enter", function()
	calendar.toggle()
end)
mytextclock:connect_signal("mouse::leave", function()
	calendar.toggle()
end)

-- Autostart Apps
local autostart_apps = {
	"nitrogen --restore",
	"picom -b",
	--	"~/.config/polybar/launch.sh",
	"xfce4-power-manager",
	"source ~/.bashrc",
}
for i, app in pairs(autostart_apps) do
	awful.spawn.with_shell(app)
end
