--[[----- TIME v3.2 ------------------------
"time_intf.lua" > Put this VLC Interface Lua script file in \lua\intf\ folder
--------------------------------------------
Requires "time_ext.lua" > Put the VLC Extension Lua script file in \lua\extensions\ folder

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

INSTALLATION directory (\lua\intf\):
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\intf\
* Windows (current user): %APPDATA%\VLC\lua\intf\
* Linux (all users): /usr/lib/vlc/lua/intf/
* Linux (current user): ~/.local/share/vlc/lua/intf/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/intf/
* Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua/intf/
Create directory if it does not exist!
--]]----------------------------------------

os.setlocale("C", "all") -- fixes numeric locale issue on Mac

config={}
config.TIME={} -- subtable reserved for TIME extension

VLC_version = vlc.misc.version()
VLC_tc = 1 -- time corrector
if tonumber(string.sub(VLC_version,1,1)) > 2 then VLC_tc = 1000000 end -- VLC3

function Looper()
	local curi=nil
	local loops=0 -- counter of loops
	while true do
		if vlc.volume.get() == -256 then break end  -- inspired by syncplay.lua; kills vlc.exe process in Task Manager
		Get_config()
--		config.TIME={time_format="[E1]",osd_position="bottom-left"}

		if vlc.playlist.status()=="stopped" then -- no input or stopped input
			if curi then -- input stopped
				Log("stopped")
				curi=nil
			end
			--loops=loops+1
			--Log(loops)
			Sleep(1)
		else -- playing, paused
			local uri=nil
			if vlc.input.item() then uri=vlc.input.item():uri() end
			if not uri then --- WTF (VLC 2.1+): status playing with nil input? Stopping? O.K. in VLC 2.0.x
				Log("WTF??? " .. vlc.playlist.status())
				Sleep(0.1)
			elseif not curi or curi~=uri then -- new input (first input or changed input)
				curi=uri
				Log(curi)
			else -- current input
				if not config.TIME or config.TIME.stop~=true then TIME_Loop() end
				if vlc.playlist.status()=="playing" then
					--Log("playing")
				elseif vlc.playlist.status()=="paused" then
					--Log("paused")
					Sleep(0.3)
				else -- ?
					Log("unknown")
					Sleep(1)
				end
				Sleep(0.1)
			end
		end
	end
end

function Log(lm)
	vlc.msg.info("[time_intf] " .. lm)
end

function Sleep(st) -- seconds
	vlc.misc.mwait(vlc.misc.mdate() + st*1000000)
end

function Get_config()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^config={.*}$") then s = "config={}" end
	assert(loadstring(s))() -- global var
end

--- TIME ---

TIME_time_format = "[E] / [D][_]([T])"
TIME_osd_position = "top-right"
TIME_Enoms = false
TIME_Thm = false

function TIME_Loop()
	if config.TIME then
		TIME_time_format = config.TIME.time_format or TIME_time_format
		TIME_osd_position = config.TIME.osd_position or TIME_osd_position
		TIME_Enoms = config.TIME.Enoms and true or false
		TIME_Thm = config.TIME.Thm and true or false
	end
	vlc.osd.message(TIME_Decode_time_format(), 1111111111, TIME_osd_position)
end

function TIME_Decode_time_format()
	local input = vlc.object.input()
	local elapsed_time = vlc.var.get(input, "time")/VLC_tc
	local position = vlc.var.get(input, "position")
	--local duration = vlc.var.get(input, "length")
	local duration = vlc.input.item():duration()
	local systemTime = os.date("*t")
	local system_time = systemTime.hour*3600 + systemTime.min*60 + systemTime.sec
	local remaining_time
	local ending_time
	local rate = vlc.var.get(vlc.object.input(),"rate")
	if duration>0 then
		remaining_time = duration - elapsed_time
		ending_time = system_time + remaining_time/rate

		duration = TIME_Time2string(duration/rate)
		remaining_time = TIME_Time2string(remaining_time)
		ending_time = TIME_Time2string(ending_time, 0, nil, TIME_Thm) -- h:m > D/h:m 
	else
		duration = "--:--"
		remaining_time = "--:--"
		ending_time = "--:--"
	end
	local et = elapsed_time
	elapsed_time = TIME_Time2string(elapsed_time, 0, not TIME_Enoms)
	system_time =  string.format((TIME_Thm and "%02d:%02d" or "%02d:%02d:%02d") ,systemTime.hour, systemTime.min, systemTime.sec)
	if rate~=1 then
		duration = duration .. " ("..string.format("%.2f", rate).."x)"
		elapsed_time = elapsed_time.."*"
		remaining_time = remaining_time.."*"
		--ending_time = ending_time.."*"
	end
	position = string.format("%.2f", position*100)

	local osd_output = string.gsub(TIME_time_format, "%[E%]", elapsed_time)
	osd_output = string.gsub(osd_output, "%[T%]", system_time)
	osd_output = string.gsub(osd_output, "%[D%]", duration)
	osd_output = string.gsub(osd_output, "%[R%]", remaining_time)
	osd_output = string.gsub(osd_output, "%[O%]", ending_time)
	osd_output = string.gsub(osd_output, "%[P%]", position)
	osd_output = string.gsub(osd_output, "%[n%]", vlc.input.item():name())
	osd_output = string.gsub(osd_output, "%[_%]", "\n")
	local fps=tonumber(string.match(osd_output,"%[E(.-)%]"))
	if fps~=nil then
		osd_output = string.gsub(osd_output, "%[E.-%]", math.floor(et * fps))
--		osd_output = string.gsub(osd_output, "%[E.-%]", string.format("%.3f", et * fps))
	end
	return osd_output	
end

function TIME_Time2string(timestamp, timeformat, ms, hm) -- seconds, 0/1/2/3/4, true/false, true/false
	if not timeformat then timeformat=0 end
	local msp=(ms and "%06.3f" or "%02d") -- seconds.milliseconds formatting pattern
	if timeformat==0 then
		if timestamp/60<1 then timeformat=1
		elseif timestamp/3600<1 then timeformat=2
		elseif timestamp/86400<1 then timeformat=3
		else timeformat=4
		end
	end
	if hm then msp="" if timeformat<3 then timeformat=3 end end

	if timeformat==3 then -- H:m:s,ms
		return string.format("%02d:%02d:"..msp, math.floor(timestamp/3600), math.floor(timestamp/60)%60, timestamp%60):gsub("%.",","):gsub(":$","")
	elseif timeformat==2 then -- M:s,ms
		return string.format("%02d:"..msp, math.floor(timestamp/60), timestamp%60):gsub("%.",",")
	elseif timeformat==1 then -- S,ms
		return string.format(msp, timestamp):gsub("%.",",")
	elseif timeformat==4 then -- D/h:m:s,ms
		return string.format("%d/%02d:%02d:"..msp, math.floor(timestamp/(24*60*60)), math.floor(timestamp/(60*60))%24, math.floor(timestamp/60)%60, timestamp%60):gsub("%.",","):gsub(":$","")
	end
end

--- XXX --- TIME ---

Looper() --starter