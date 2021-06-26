--[[----------------------------------------
"time_ext.lua" > Put this VLC Extension Lua script file in \lua\extensions\ folder
--------------------------------------------
Requires "time_intf.lua" > Put the VLC Interface Lua script file in \lua\intf\ folder

Simple instructions:
1) "time_ext.lua" > Copy the VLC Extension Lua script file into \lua\extensions\ folder;
2) "time_intf.lua" > Copy the VLC Interface Lua script file into \lua\intf\ folder;
3) Start the Extension in VLC menu "View > Time v3.x (intf)" on Windows/Linux or "Vlc > Extensions > Time v3.x (intf)" on Mac and configure the Time interface to your liking.

Alternative activation of the Interface script:
* The Interface script can be activated from the CLI (batch script or desktop shortcut icon):
vlc.exe --extraintf=luaintf --lua-intf=time_intf
* VLC preferences for automatic activation of the Interface script:
Tools > Preferences > Show settings=All > Interface >
> Main interfaces: Extra interface modules [luaintf]
> Main interfaces > Lua: Lua interface [time_intf]

INSTALLATION directory (\lua\extensions\):
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\VLC\lua\extensions\
* Linux (all users): /usr/lib/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/
* Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua/extensions/
Create directory if it does not exist!
--]]----------------------------------------
-- TODO: timer/reminder/alarm; multiple time format inputs for different positions (1-9);

config={}
local cfg={}
intf_script = "time_intf" -- Location: \lua\intf\time_intf.lua
-- defaults
DEF_time_format = "[E] / [D][_]([T])"  -- [T]ime, [O]ver, [E]lapsed, [D]uration, [R]emaining, ...
DEF_osd_position = "top-right"
time_formats = {"---> Clear! <---", "[E]", "[E23.976]", "[D]", "[R]", "[T]", "[O]", "[P]%", "[n]", "[_]", "<--- Append / Replace --->", "[E] / [D]", "[T] >> [O]", "-[R] / [D]", "-[R] ([T])", "[E] / [D][_]([T])", "[E] / [D][_]([T] / [O])[_]-[R]"}
positions = {"top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"}
appendreplace_id = 0

function descriptor()
	return {
		title = "Time v3.2 (intf)",
		version = "3.2",
		author = "lubozle",
--		url = "http://addons.videolan.org/content/show.php?content=149618",
		url = "https://addons.videolan.org/p/1154032/",
--		shortdesc = "Time displayer.",
-- No shortdesc to use title instead of short description in VLC menu.
-- Then the first line of description will be the short description.
		description = [[
Time displayer.

Time is VLC Extension that displays running time on the screen in a playing video.
(Extension script "time_ext.lua" + Interface script "time_intf.lua")

Features:
- supported tags:  [E], [Efps], [D], [R], [T], [O], [P], [n], [_];
- 9 possible positions on the screen;
- elapsed time with milliseconds;
- playback speed rate taken into account for duration time;
]],
		capabilities = {"menu"}
	}
end

function activate()
	os.setlocale("C", "all") -- just in case
	Get_config()
	if config and config.TIME then
		cfg = config.TIME
	end
--[[
	if cfg.first_run==nil or cfg.first_run==true then
		cfg.first_run = false
		Set_config(cfg, "TIME")
		create_dialog_S()
	else create_dialog() end
--]]
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
	if not ti or VLC_luaintf~=intf_script then trigger_menu(2) else trigger_menu(1) end
end

function deactivate()
end

function close()
	vlc.deactivate()
end

function meta_changed()
end

function menu()
	return {"Control panel", "Settings"}
end
function trigger_menu(id)
	if id==1 then -- Control panel
		if dlg then dlg:delete() end
		create_dialog()
	elseif id==2 then -- Settings
		if dlg then dlg:delete() end
		create_dialog_S()
	end
end

-----------------------------------------

function create_dialog_S()
	dlg = vlc.dialog(descriptor().title .. " > SETTINGS")
	cb_extraintf = dlg:add_check_box("Enable interface: ", true,1,1,1,1)
	ti_luaintf = dlg:add_text_input(intf_script,2,1,2,1)
	dlg:add_button("SAVE!", click_SAVE_settings,1,2,1,1)
	dlg:add_button("CANCEL", click_CANCEL_settings,2,2,1,1)
--	lb_message = dlg:add_label("CLI options: --extraintf=luaintf --lua-intf="..intf_script,1,3,3,1)
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
	lb_message = dlg:add_label("Current status: " .. (ti and "ENABLED" or "DISABLED") .. " " .. tostring(VLC_luaintf),1,3,3,1)
end

function click_SAVE_settings()
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()

	if cb_extraintf:get_checked() then
		--vlc.config.set("extraintf", "luaintf")
		if not ti then table.insert(t, "luaintf") end
		vlc.config.set("lua-intf", ti_luaintf:get_text())
	else
		--vlc.config.set("extraintf", "")
		if ti then table.remove(t, ti) end
	end
	vlc.config.set("extraintf", table.concat(t, ":"))

	lb_message:set_text("Please restart VLC for changes to take effect!")
end

function click_CANCEL_settings()
	trigger_menu(1)
end

--------------------

function create_dialog()
	dlg = vlc.dialog(descriptor().title .. (cfg.stop and " >STOPPED<" or ""))
	--dlg:add_label("Time format: \\ Position:",1,1,2,1)
	dlg:add_label("<b>Time format:</b>",1,1,1,1)
	dlg:add_label("<b>\\ Position:</b>",2,1,1,1)
	dd_position = dlg:add_dropdown(3,1,1,1)
		for i,v in ipairs(positions) do
			if v==(cfg.osd_position or DEF_osd_position) then table.remove(positions,i) break end
		end
		table.insert(positions, 1, (cfg.osd_position or DEF_osd_position))
		for i,v in ipairs(positions) do
			dd_position:add_value(v, i)
		end
	dd_time_format = dlg:add_dropdown(1,2,2,1)
		for i,v in ipairs(time_formats) do
			dd_time_format:add_value(v, i)
			if v=="<--- Append / Replace --->" then appendreplace_id=i end
		end
	dlg:add_button("START!", click_START,1,4,1,1)
	dlg:add_button(">> USE pattern", click_USE,3,2,1,1)
	ti_time_format = dlg:add_text_input((cfg.time_format or DEF_time_format),1,3,2,1)
	dlg:add_button("SETTINGS", function() trigger_menu(2) end,3,3,1,1)
	dlg:add_button("STOP", click_STOP,2,4,1,1)
	bt_help = dlg:add_button("HELP", click_HELP,3,4,1,1)
	cb_Enoms = dlg:add_check_box("[E] no ms", not not cfg.Enoms, 2,5,1,1)
	cb_Thm = dlg:add_check_box("[T] h:m", cfg.Thm and true or false, 3,5,1,1)
end

function click_STOP()
	cfg.stop = true
	Set_config(cfg, "TIME")
	dlg:set_title(descriptor().title .. " >STOPPED<")
end

function click_START()
	cfg.time_format = ti_time_format:get_text()
	cfg.osd_position = positions[dd_position:get_value()]
	cfg.stop = false
	cfg.Enoms = cb_Enoms:get_checked()
	cfg.Thm = cb_Thm:get_checked()
	Set_config(cfg, "TIME")
	dlg:set_title(descriptor().title)
end

function click_USE()
	local selected_id = dd_time_format:get_value()
	local selected_time_format = time_formats[selected_id]
	if selected_time_format=="---> Clear! <---" then
		ti_time_format:set_text("")
	else
		if selected_id < appendreplace_id then
			ti_time_format:set_text(ti_time_format:get_text() .. selected_time_format)
		elseif selected_id > appendreplace_id then
			ti_time_format:set_text(selected_time_format)
		end
	end
	--dlg:update()
end

function click_HELP()
	local help_text=[[
<div style="background-color:lightgreen;"><b>Time</b> is VLC Extension that displays running time on the screen in a playing video.</div>(Extension script "time_ext.lua" + Interface script "time_intf.lua")
<hr />
<center><b><a style="background-color:#FF7FAA;">&nbsp;Instructions&nbsp;</a></b></center>
<b><a style="background-color:#FF7FAA;">1.)</a></b> Choose a desired <b><a style="background-color:lightblue;">position</a></b> from the drop-down menu.<br />
<b><a style="background-color:#FF7FAA;">2.)</a></b> In <b><a style="background-color:lightblue;">time format</a></b> input field write some time pattern containing time tags. The list of available tags is below.<br />
You can use predefined pattern from the drop-down menu. Choose one and put it in the time format field by pressing <b><nobr><a style="background-color:silver;">[ >> USE pattern ]</a></nobr></b> button.<br />
<b><a style="background-color:#FF7FAA;">3.)</a></b> Press <b><nobr><a style="background-color:silver;">[ START! ]</a></nobr></b> button for changes to take effect.<br /><br />
<b>Following <a style="background-color:#FF7FAA;">time tags</a> can be used within time format pattern:</b>
<div style="background-color:#FF7FAA;">
<b>&nbsp;[T]</b> - actual system time;<br />
<b>&nbsp;[O]</b> - time when video will be over;<br />
<b>&nbsp;[E]</b> - elapsed time (current playback position);<br />
<b>&nbsp;[E25]</b> - elapsed frames (elapsed time * fps);<br />
<b>&nbsp;[R]</b> - remaining time;<br />
<b>&nbsp;[D]</b> - duration (length);<br />
<b>&nbsp;[P]</b> - percentage position (%);<br />
<b>&nbsp;[n]</b> - name;<br />
<b>&nbsp;[_]</b> - new/next line;</div>
 > They are automatically replaced with actual time values on the screen.<br />
 > If duration value is not available then [D], [R], [O] is replaced with "--:--".<br />
 > You can also use some short descriptions or put some delimiters between time tags.<br />
<div style="background-color:#FFFF7F;"><b>OSD text format</b> can be customised within internal VLC settings:<br />
Tools > Preferences > (Show settings = Simple) > Subtitles/OSD<br />
Tools > Preferences > (Show settings = All) > Video \ Subtitles/OSD \ Text renderer<br />
Do not forget to Save and restart VLC for changes to take effect!</div>
<hr />
<div style="background-color:lightblue;">
<b>Homepage:</b> <a href="https://addons.videolan.org/p/1154032/">VLC Extension: Time</a><br />
<b>Forum:</b> <a href="http://forum.videolan.org/viewforum.php?f=29">Scripting VLC in Lua</a><br />
Please visit us and bring some new ideas.<br />
Learn how to write your own scripts and share them with us.<br />
Help to build happy VLC community :o)</div>
<pre>     www
    (. .)
-ooo-(_)-ooo-</pre>
]]
	dlg:del_widget(bt_help)
	bt_help=nil
	ht_help=dlg:add_html(help_text,1,5,3,1)
	bt_helpx = dlg:add_button("HELP [x]", click_HELPx,3,4,1,1)
	dlg:update()
end
function click_HELPx()
	dlg:del_widget(ht_help)
	dlg:del_widget(bt_helpx)
	ht_help=nil
	bt_helpx=nil
	bt_help = dlg:add_button("HELP", click_HELP,3,4,1,1)
	dlg:update()
end

-----------------------------------------

function Get_config()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^config={.*}$") then s = "config={}" end
	assert(loadstring(s))() -- global var
end

function Set_config(cfg_table, cfg_title)
	if not cfg_table then cfg_table={} end
	if not cfg_title then cfg_title=descriptor().title end
	Get_config()
	config[cfg_title]=cfg_table
	vlc.config.set("bookmark10", "config="..Serialize(config))
end

function Serialize(t)
	if type(t)=="table" then
		local s='{'
		for k,v in pairs(t) do
			if type(k)~='number' then k='"'..k..'"' end
			s = s..'['..k..']='..Serialize(v)..',' -- recursion
		end
		return s..'}'
	elseif type(t)=="string" then
		return string.format("%q", t)
	else --if type(t)=="boolean" or type(t)=="number" then
		return tostring(t)
	end
end

function SplitString(s, d) -- string, delimiter pattern
	local t={}
	local i=1
	local ss, j, k
	local b=false
	while true do
		j,k = string.find(s,d,i)
		if j then
			ss=string.sub(s,i,j-1)
			i=k+1
		else
			ss=string.sub(s,i)
			b=true
		end
		table.insert(t, ss)
		if b then break end
	end
	return t
end

function VLC_intf_settings()
	local VLC_extraintf = vlc.config.get("extraintf") -- enabled VLC interfaces
	local VLC_luaintf = vlc.config.get("lua-intf") -- Lua Interface script name
	local t={}
	local ti=false
	if VLC_extraintf then
		t=SplitString(VLC_extraintf, ":")
		for i,v in ipairs(t) do
			if v=="luaintf" then
				ti=i
				break
			end
		end
	end
	return VLC_extraintf, VLC_luaintf, t, ti
end

