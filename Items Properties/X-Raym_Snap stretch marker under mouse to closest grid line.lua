--[[
 * ReaScript Name: Snap stretch marker under mouse to closest grid line
 * Description:
 * Instructions: Put this on a keyboard shortcut. Run.
 * Notes : Only work if take rate is 1. SWS issue.
 * Screenshot: http://i.giphy.com/l41m5L3XNjRhjDyww.gif
 * Author: X-Raym
 * Author URl: http://extremraym.com
 * Repository: GitHub > X-Raym > EEL Scripts for Cockos REAPER
 * Repository URl: https://github.com/X-Raym/REAPER-EEL-Scripts
 * File URl: http://i.giphy.com/l41m5L3XNjRhjDyww.gif
 * Licence: GPL v3
 * Forum Thread: REQ: Snap stretch marker closest to mouse cursor to grid
 * Forum Thread URl: http://forum.cockos.com/showthread.php?t=166702
 * REAPER: 5.0
 * Extensions: SWS 2.8.0
 --]]
 
--[[
 * Changelog:
 * v1.0 (2015-09-23)
	+ Initial Release
 --]]

 
--[[
debug_flag = false
function Msg(variable)
	if debug_flag == true then
		reaper.ShowConsoleMsg(tostring(variable).."\n")
	end
end
 --]]

function main() -- local (i, j, item, take, track)

	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.
	
	window, segment, details = reaper.BR_GetMouseCursorContext()
	
	if details == "item_stretch_marker" then
		
		take, mouse_pos = reaper.BR_TakeAtMouseCursor()
		
		if take ~= nil then
				
			idx = reaper.BR_GetMouseCursorContext_StretchMarker()
			
			if idx ~= nil then
	
				idx, strech_pos, srcpos = reaper.GetTakeStretchMarker(take, idx)
				
				item = reaper.GetMediaItemTake_Item(take)
				item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
				
				rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
				
				strech_pos = strech_pos / rate
				
				srcpos = (reaper.BR_GetClosestGridDivision(strech_pos+item_pos) - item_pos)*rate
				
				reaper.SetTakeStretchMarker(take, idx, srcpos)
			
			end
			
		end
				
	end
	
	reaper.Undo_EndBlock("Snap stretch marker under mouse to closest grid line", -1) -- End of the undo block. Leave it at the bottom of your main function.

end

reaper.PreventUIRefresh(1) -- Prevent UI refreshing. Uncomment it only if the script works.

main() -- Execute your main function

reaper.UpdateArrange() -- Update the arrangement (often needed)

reaper.PreventUIRefresh(-1) -- Restore UI Refresh. Uncomment it only if the script works.
