--[[
 * ReaScript Name: Create one text item on first selected track from last selected items notes
 * Description: This was created as a "glue empty items concatenating their notes", but this version works with a destination track, all kind of items, and preserve original selection
 * Instructions: Select a destination track. Select items. Execute. You can use it in Custom Action with the Delete selected items action.
 * Author: X-Raym
 * Author URl: http://extremraym.com
 * Repository: GitHub > X-Raym > EEL Scripts for Cockos REAPER
 * Repository URl: https://github.com/X-Raym/REAPER-EEL-Scripts
 * File URl: https://github.com/X-Raym/REAPER-EEL-Scripts/scriptName.eel
 * Licence: GPL v3
 * Forum Thread: Script: Scripts (LUA): Create Text Items Actions (various)
 * Forum Thread URl: http://forum.cockos.com/showthread.php?t=156763
 * REAPER: 5.0 pre 15
 * Extensions: SWS/S&M 2.7.3 #0
 --]]
 
--[[
 * Changelog:
 * v1.4 (2015-07-29)
	# Better Set notes
 * v1.3 (2015-25-05)
	+ Now with item color preservation
 * v1.2 (2015-04-14)
	# Even better item selection and time selection/loop restoration
 * v1.1.1 (2015-03-11)
	# Better item selection restoration
	# First selected track as last touched
 * v1.0 (2015-03-11)
	+ Initial Release
 --]]

--[[ ----- DEBUGGING ====>
function get_script_path()
  if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
    return debug.getinfo(1,'S').source:match("(.*".."\\"..")"):sub(2) -- remove "@"
  end
    return debug.getinfo(1,'S').source:match("(.*".."/"..")"):sub(2)
end

package.path = package.path .. ";" .. get_script_path() .. "?.lua"
require("X-Raym_Functions - console debug messages")

debug = 1 -- 0 => No console. 1 => Display console messages for debugging.
clean = 1 -- 0 => No console cleaning before every script execution. 1 => Console cleaning before every script execution.

msg_clean()
]]-- <==== DEBUGGING -----

function CreateTextItem(starttime, endtime, notetext, color) 
	--ref: Lua: number startOut retval, number endOut reaper.GetSet_LoopTimeRange(boolean isSet, boolean isLoop, number startOut, number endOut, boolean allowautoseek)
	reaper.GetSet_LoopTimeRange(1,0,starttime,endtime,0) -- define the time range for the empty item
	--ref: Lua: reaper.Main_OnCommand(integer command, integer flag)
	reaper.Main_OnCommand(40142,0) -- insert empty item
	--ref: Lua: MediaItem reaper.GetSelectedMediaItem(ReaProject proj, integer selitem)
	item = reaper.GetSelectedMediaItem(0,0) -- get the selected item
	
	reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)

	reaper.ULT_SetMediaItemNote(item, notetext)
	
	reaper.SetEditCurPos(endtime, 1, 0) -- moves cursor for next item
end

function main() -- local (i, j, item, take, track)

	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	text_output = ""
	
	selected_tracks_count = reaper.CountSelectedTracks(0)

	if selected_tracks_count > 0 then

		selected_items_count = reaper.CountSelectedMediaItems(0)

		if selected_items_count > 0 then
			-- THE THING

			--track = reaper.GetSelectedTrack(0, i)
			reaper.Main_OnCommand(40914,0) -- Set first selected track as last touched track
			reaper.Main_OnCommand(40644,0) -- Implode selected items into one track

			selected_items_count = reaper.CountSelectedMediaItems(0) -- Get selected item on track
			
			first_item = reaper.GetSelectedMediaItem(0, 0)
			first_item_start = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
			
			last_item = reaper.GetSelectedMediaItem(0, selected_items_count-1)
			last_item_duration = reaper.GetMediaItemInfo_Value(last_item, "D_LENGTH")
			last_item_start = reaper.GetMediaItemInfo_Value(last_item, "D_POSITION")
			last_item_end = last_item_start + last_item_duration
			last_item_color = reaper.GetMediaItemInfo_Value(last_item, "I_CUSTOMCOLOR")

			
			-- GET ITEMS
			loop_item = reaper.GetSelectedMediaItem(0, selected_items_count-1) -- Get last elected item i
			loop_item_track = reaper.GetMediaItem_Track(loop_item)

			text_output = reaper.ULT_GetMediaItemNote(loop_item)

			reaper.Main_OnCommand(40029,0)

			--reaper.Main_OnCommand(40697, 0) -- DELETE all selected items
			reaper.Undo_BeginBlock()
			
			CreateTextItem(first_item_start, last_item_end, text_output, last_item_color)

			--end
			reaper.Undo_EndBlock("Create one text item on first selected track from last selected items notes", -1) -- End of the undo block. Leave it at the bottom of your main function.
		
		else -- no selected item
			reaper.ShowMessageBox("Select at least one item","Please",0)
		end -- if select item

	else -- no selected track
		reaper.ShowMessageBox("Select a destination track before running the script","Please",0)
	end

end

--msg_start() -- Display characters in the console to show you the begining of the script execution.


--[[ ----- INITIAL SAVE AND RESTORE ====> ]]

-- SAVE INITIAL SELECTED ITEMS
init_sel_items = {}
local function SaveSelectedItems (table)
	for i = 0, reaper.CountSelectedMediaItems(0)-1 do
		table[i+1] = reaper.GetSelectedMediaItem(0, i)
	end
end

-- RESTORE INITIAL SELECTED ITEMS
local function RestoreSelectedItems (table)
	reaper.Main_OnCommand(40289, 0) -- Unselect all items
	for _, item in ipairs(table) do
		reaper.SetMediaItemSelected(item, true)
	end
end

-- SAVE INITIAL LOOP AND TIME SELECTION
function SaveLoopTimesel()
	init_start_timesel, init_end_timesel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
	init_start_loop, init_end_loop = reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
end

-- RESTORE INITIAL SELECTED ITEMS
function RestoreLoopTimesel()
	reaper.GetSet_LoopTimeRange(1, 0, init_start_timesel, init_end_timesel, 0)
	reaper.GetSet_LoopTimeRange(1, 1, init_start_loop, init_end_loop, 0)
end

-- VIEW
-- SAVE INITIAL VIEW
function SaveView()
	start_time_view, end_time_view = reaper.BR_GetArrangeView(0)
end


-- RESTORE INITIAL VIEW
function RestoreView()
	reaper.BR_SetArrangeView(0, start_time_view, end_time_view)
end

--[[ <==== INITIAL SAVE AND RESTORE ----- ]]


reaper.PreventUIRefresh(1)
SaveView()
SaveSelectedItems(init_sel_items)
SaveLoopTimesel()

reaper.Main_OnCommand(40914, 0) -- Select first track as last touched
main() -- Execute your main function

RestoreLoopTimesel()
RestoreView()
RestoreSelectedItems(init_sel_items)

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange() -- Update the arrangement (often needed)

--msg_end() -- Display characters in the console to show you the end of the script execution.

--[[
IDEAS
 * Make it per track (loop through selected item on track and glue on tracks)
 * Make it works with track name if take is not a empty item
]]
