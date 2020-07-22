(*
Export Playlists for Apple Music
Written by Daniel Petrescu
https://github.com/dpet23
*)



------------------------------
(* global properties *)
------------------------------

property myTitle : "Export Playlists"
global iconApp
global iconWarning
global iconError
global originalDelimiter
global illegalCharacters1
global illegalCharacters2
global attrShow
global folderChoice
global nameChoice
global dupeLimit
global playlistsExported
global songsExported
global maxPathComponentLength
global ellipsisChar
set progress description to "Preparing…"
set progress total steps to -1



------------------------------
(* main program *)
------------------------------

-- SET GLOBAL VARIABLES
set iconApp to 1 -- [icon note]
set iconWarning to 2 -- [icon caution]
set iconError to 0 -- [icon stop]
set dupeLimit to 100 -- [allow up to this many duplicate files; set limit to avoid possible infinite loop]
set maxPathComponentLength to 255 -- [the maximum length of a component of the new file's path]
set ellipsisChar to "..." -- [character to use when truncating long names. Example: 3 full stops (...) or the ellipsis character (…)]
set playlistsExported to 0
set songsExported to 0

-- SET ILLEGAL CHARACTERS
-- `illegalCharacters1`: will be converted to "_"
-- `illegalCharacters2`: will be removed from name
set illegalCharacters1 to {"~", "?", "!", "@", "#", "$", "%", "&", "*", "=", "+", "{", "}", "<", ">", "|", "\\", "/", ";", ":", "×", "÷"}
set illegalCharacters2 to {"'", "\"", ",", "`", "^", "˘"}

with timeout of 60 * 60 * 24 seconds -- (timeout of 24 hours for many huge playlists, slow computer/network, etc.)
	tell application "Music"
		
		-- No need to check if Apple Music is open. The "tell application Music" command opens Apple Music if it's closed.
		
		-- SAVE DELIMITER
		set originalDelimiter to AppleScript's text item delimiters
		
		-- GET ALL PLAYLISTS FROM APPLE MUSIC
		try
			set all_specialps to (get name of every user playlist whose special kind is not none)
			set all_userps to (get name of every user playlist whose smart is false and special kind is none)
			set all_smartps to (get name of every user playlist whose smart is true and special kind is none)
			
			set delim to "--------------------------------------------------"
			set delim_specialpl to "---------------- Special Playlists: ----------------"
			set delim_userpl to "------------------ User Playlists: -----------------"
			set delim_smartpl to "---------------- Smart Playlists: -----------------"
			set all_ps to {}
			if ((length of all_specialps) > 0) then
				set the end of all_ps to delim
				set the end of all_ps to delim_specialpl
				repeat with ps in all_specialps
					set the end of all_ps to ps
				end repeat
			end if
			if ((length of all_userps) > 0) then
				set the end of all_ps to delim
				set the end of all_ps to delim_userpl
				repeat with ps in all_userps
					set the end of all_ps to ps
				end repeat
			end if
			if ((length of all_smartps) > 0) then
				set the end of all_ps to delim
				set the end of all_ps to delim_smartpl
				repeat with ps in all_smartps
					set the end of all_ps to ps
				end repeat
			end if
		end try
		
		-- CHOOSE PLAYLISTS TO EXPORT
		set thePlaylistsNames to (choose from list all_ps with prompt ({"Choose which playlists to export.", return, "[can choose multiple out of ", (length of all_specialps as string), " special playlists, ", (length of all_userps as string), " user playlists, and ", (length of delim_smartpl as string), " smart playlists]"} as string) with title myTitle with multiple selections allowed)
		if thePlaylistsNames is false then return
		set thePlaylistsNumber to (count of thePlaylistsNames)
		set thePlaylistsNumberInvalid to my count_matches(thePlaylistsNames, "---------------")
		set thePlaylistsNumberGood to (thePlaylistsNumber - thePlaylistsNumberInvalid)
		my log_out("Playlists chosen:", thePlaylistsNames)
		
		try
			-- CLEAN UP PLAYLIST SELECTION
			set thePlaylistsNamesClean to {}
			repeat with i from 1 to thePlaylistsNumber
				if ({thePlaylistsNames's item i} as string) does not contain "---------------" then set thePlaylistsNamesClean's end to thePlaylistsNames's item i
			end repeat
			
			-- GET NUMBER OF SONGS IN EACH PLAYLIST
			set thePlaylistsNamesLength to {}
			set thePlaylistsNumberZero to 0
			repeat with i from 1 to thePlaylistsNumberGood
				set thisPlaylistName to (item i of thePlaylistsNamesClean)
				set thisPlaylist to (get some playlist whose name is thisPlaylistName)
				set numberSongs to (get count of tracks of thisPlaylist)
				if numberSongs = 0 then
					set thePlaylistsNumberZero to (thePlaylistsNumberZero + 1)
					set thePlaylistsNumberGood to (thePlaylistsNumberGood - 1)
				else
					set the end of thePlaylistsNamesLength to ({thisPlaylistName, " (", numberSongs, " songs)"} as string)
				end if
			end repeat
			
			-- DELIMITERS
			set AppleScript's text item delimiters to (return as string)
			set thePlaylistsDisplay to (thePlaylistsNamesLength as string)
			set AppleScript's text item delimiters to originalDelimiter
			
			-- USER FEEDBACK
			if thePlaylistsNumberInvalid = 1 then
				set delimiter_s to " delimiter. It"
			else
				set delimiter_s to " delimiters. These"
			end if
			
			if thePlaylistsNumberZero = 1 then
				set playlist_s0 to "playlist. It"
			else
				set playlist_s0 to "playlists. These"
			end if
			
			if thePlaylistsNumberGood = 1 then
				set playlist_s to " playlist"
			else
				set playlist_s to " playlists"
			end if
			
			set message to ""
			if (thePlaylistsNumberInvalid > 0) then
				set message to message & ({return, "- You have chosen ", thePlaylistsNumberInvalid, delimiter_s, " will be ignored."} as string)
			end if
			if (thePlaylistsNumberZero > 0) then
				set message to message & ({return, "- You have chosen ", thePlaylistsNumberZero, " empty ", playlist_s0, " will be ignored."} as string)
			end if
			if ((thePlaylistsNumberInvalid > 0) or (thePlaylistsNumberZero > 0)) then
				display dialog ({"Issues:", message} as string) with title myTitle buttons {"Cancel", "Continue"} default button 1 with icon iconWarning giving up after 10
			end if
			
			-- SHOW FINAL LIST OF PLAYLISTS
			set button to button returned of (display dialog ({"The ", thePlaylistsNumberGood, playlist_s, " to export: ", return, return, thePlaylistsDisplay} as string) with title myTitle buttons {"Cancel", "Proceed"} default button 2 with icon iconApp giving up after 10)
			my log_out((thePlaylistsNumberGood & playlist_s & " to export:") as string, thePlaylistsDisplay)
			
			-- GET ROOT FOLDER
			set folderPath to (choose folder with prompt "Choose the folder in which to export the playlists:" default location path to desktop)
			set folderPathPOSIX to POSIX path of folderPath
			
			-- SAVING MODE
			if thePlaylistsNumberGood > 1 then
				set folderChoice to button returned of (display dialog ({"Would you like to save the playlists in the same folder or in different folders?", return, return, return, ¬
					"Summary:", return, return, ¬
					"Same folder - Create a new folder in the location chosen and place all songs from all playlists there. Create a subfolder and place all m3u playlist files in it.", return, return, ¬
					"Different folders - Make separate subfolders for each playlist in the location chosen. The m3u playlist file is placed in the subfolder, and a further subfolder is created for the songs."} as string) with title myTitle buttons {"Cancel", "Same folder", "Different folders"} default button 1)
			else
				set folderChoice to "Different folders"
			end if
			my log_out("Saving mode:", folderChoice)
			
			-- GET ATTRIBUTES FOR FILENAME
			set availableAttributes to {"[album]", "[album artist]", "[artist]", "[composer]", "[track name]", "[track number]", "[disc number]", "[playlist order number]", "[original file name]"}
			set AppleScript's text item delimiters to (return as string)
			set availableAttributesDisplay to (availableAttributes as string)
			set AppleScript's text item delimiters to originalDelimiter
			set folderStructure to text returned of (display dialog ({"Choose the folder structure for the exported files.", return, return, return, ¬
				"AVAILABLE ATTRIBUTES:", return, availableAttributesDisplay, return, return, ¬
				"EXAMPLE:", return, "[artist] > [album] > [track number] - [track name]", return, "    means", return, "In the music subfolder folder, make a folder for ARTIST, then make a folder for ALBUM inside this, then copy the files inside that, with the name structure \"[track number] - [track name]\"", return, return, ¬
				"NOTE: The last item (filename) must include [file name] or [track name] or [original file name]!"} as string) with title myTitle buttons {"Cancel", "OK"} default button 2 default answer "")
			
			-- CHECK ATTRIBUTE LIST - not empty
			if folderStructure is "" then
				display dialog ({"WARNING:", return, "No attributes were chosen!", return, return, "The value used will be", return, "    [original file name]"} as string) with title myTitle buttons {"Cancel", "Proceed"} default button 2 with icon iconWarning giving up after 10
				set folderStructure to "[original file name]"
			end if
			my log_out("Attributes chosen:", folderStructure)
			
			-- CHECK SPECIFIED FOLDER STRUCTURE
			set AppleScript's text item delimiters to (" > ")
			set folderStructure_NewFolders to every text item of folderStructure
			set AppleScript's text item delimiters to (return as string)
			log ({"Specified folder structure:", folderStructure_NewFolders, return} as string)
			set AppleScript's text item delimiters to originalDelimiter
			
			-- CHECK ATTRIBUTE LIST - file name
			set fileName to ((item -1 of folderStructure_NewFolders) as string)
			if (("[file name]" is not in fileName) and ("[track name]" is not in fileName) and ("[original file name]" is not in fileName)) then
				error ({"ERROR: The filename template given was", return, "    ", fileName, return, "which does not contain [file name] or [track name] or [original file name]. Cannot continue."} as string) number 1
			end if
			
			-- Don't need to check the attribute list for valid attributes.
			-- An invalid attribute is treated as a string and added to the name like any other symbols (after cleaning).
			
			-- PARSE ATTRIBUTE LIST
			set attrLength to (count of availableAttributes)
			set attrShow to {}
			repeat with attr from 1 to attrLength
				set the end of attrShow to null
			end repeat
			repeat with attr from 1 to attrLength
				if folderStructure contains (item attr of availableAttributes) then
					set (item attr of attrShow) to true
				else
					set (item attr of attrShow) to false
				end if
			end repeat
			
			-- TRACK NAME OR WORK NAME?
			if ((item 5 of attrShow) = true) then
				set nameChoice to button returned of (display dialog ({"You have included the Track Name. For tracks that have a work name and movement number set (usually classical music), would you like to use the work name or the track name?", return, return, "(If unsure, select 'Track Name'.)"} as string) with title myTitle buttons {"Cancel", "Work name", "Track name"} default button 3 with icon iconApp giving up after 60)
				if (nameChoice = "Track name") then
					set nameChoice to true
				else if (nameChoice = "Work name") then
					set nameChoice to false
				else if (nameChoice = "") then
					set nameChoice to true
				end if
			else
				set nameChoice to true
			end if
			
		on error number -128 ------ "Cancel" button
			return
		end try
		
		-- MAKE MASTER LIST OF PLAYLISTS
		-- List of [reference to playlist, clean name, number of tracks] for each chosen playlist
		set thePlaylists to {}
		set thePlaylistsClean to {}
		repeat with i from 1 to thePlaylistsNumberGood ------ for each playlist:
			repeat 1 times ------ to allow skipping
				-- SET UP VARIABLES
				set tmp_list to {}
				set thisPlaylistName to (item i of thePlaylistsNamesClean)
				set thisPlaylistNameClean to my clean_name(thisPlaylistName)
				set thisPlaylist to (get some playlist whose name is thisPlaylistName)
				
				-- CHECK FOR DUPLICATE CLEAN NAMES
				if thePlaylistsClean does not contain thisPlaylistNameClean then
					set the end of thePlaylistsClean to thisPlaylistNameClean
				else
					set {thisPlaylistNameClean, thePlaylistsClean} to my fix_duplicate("playlist", thisPlaylistName, thisPlaylistNameClean, thePlaylistsClean)
					if (thisPlaylistNameClean = "exit repeat") then
						set thePlaylistsNumberGood to thePlaylistsNumberGood - 1
						exit repeat
					end if
				end if
				
				-- MAKE MASTER LIST
				set the end of tmp_list to thisPlaylist
				set the end of tmp_list to thisPlaylistNameClean
				set the end of tmp_list to (get count of tracks of thisPlaylist)
				set the end of thePlaylists to tmp_list
			end repeat ------ to allow skipping
		end repeat ------ for each playlist
		
		-- INITIAL FOLDER STRUCTURE
		if (folderChoice = "Same folder") then
			
			-- MAKE ROOT FOLDER
			set newName to "Apple Music Export"
			set rootPathExists to my folder_exists(folderPathPOSIX, newName, "d")
			if not rootPathExists then
				set rootPath to my make_dir(folderPathPOSIX, newName)
			else
				set rootPath to {POSIX path of folderPath as string, newName, "/"} as string
			end if
			
			-- MAKE PLAYLISTS FOLDER
			set newName to "_Playlists"
			set playlistsPathExists to my folder_exists(rootPath, newName, "d")
			if not playlistsPathExists then
				set playlistsPath to my make_dir(rootPath, newName)
			else
				set playlistsPath to {POSIX path of rootPath as string, newName, "/"} as string
			end if
			
			-- SET MUSIC PATH
			set musicPath to rootPath
			
		else if (folderChoice = "Different folders") then
			set rootPath to (POSIX path of folderPath as string)
		end if
		
		-- EXPORT PLAYLISTS
		repeat with i from 1 to thePlaylistsNumberGood ------ for each playlist:
			repeat 1 times ------ to allow skipping
				
				-- Update number of songs exported after 1st playlist
				if (i = 2) then
					set songsExported to (songsExported + 1)
				end if
				
				-- EXTRACT DETAILS FROM MASTER LIST
				set thisPlaylistDetails to (item i of thePlaylists)
				set thisPlaylist to (item 1 of thisPlaylistDetails)
				set thisPlaylistName to (get name of thisPlaylist)
				set thisPlaylistNameClean to (item 2 of thisPlaylistDetails)
				set thisPlaylistNumberSongs to (item 3 of thisPlaylistDetails)
				
				log ({delim, return, "Exporting playlist: '", thisPlaylistName, "'", return, return} as string)
				
				if (folderChoice = "Different folders") then
					
					-- MAKE PLAYLIST FOLDER
					if not my folder_exists(rootPath, thisPlaylistNameClean, "d") then
						set playlistsPath to my make_dir(rootPath, thisPlaylistNameClean)
					else
						set skipChoice to button returned of (display dialog ({"Exporting playlist '", thisPlaylistName, "'.", return, ¬
							"Folder exists:", return, "    ", ({POSIX path of rootPath as string, thisPlaylistNameClean} as string), return, return, ¬
							"Would you like to skip this playlist or use the existing folder?"} as string) with title myTitle buttons {"Cancel", "Skip", "Use existing folder"} default button 3 with icon iconError)
						if (skipChoice = "Skip") then
							exit repeat
						else if (skipChoice = "Use existing folder") then
							set playlistsPath to {POSIX path of rootPath as string, thisPlaylistNameClean, "/"} as string
						end if
					end if
					
					-- MAKE MUSIC FOLDER
					set newName to "Music"
					if not my folder_exists(playlistsPath, newName, "d") then
						set musicPath to my make_dir(playlistsPath, newName)
					else
						set musicPath to {POSIX path of playlistsPath as string, newName, "/"} as string
					end if
				end if
				
				-- LOG FOLDER STRUCTURE
				log ({"Folder structure:", return, ¬
					"- Chosen folder: ", folderPathPOSIX, return, ¬
					"- Root path: ", rootPath, return, ¬
					"- Music path: ", musicPath, return, ¬
					"- Playlists path: ", playlistsPath, return, return} as string)
				
				-- PLAYLIST FILE SETUP
				set playlistFileType to "m3u"
				set playlistFileName to ({thisPlaylistNameClean, ".", playlistFileType} as string)
				set playlistFileName to my truncate_name(playlistFileName, true)
				set playlistFilePath to {POSIX path of playlistsPath as string, thisPlaylistNameClean, ".", playlistFileType} as string
				
				try ------ if anything goes wrong, close the playlist file
					
					-- CREATE PLAYLIST FILE
					set thePlaylistFile to open for access (POSIX path of playlistFilePath) with write permission
					if (playlistFileType = "m3u") then
						tell current application to write ("#EXTM3U" & return) to thePlaylistFile starting at eof
					end if
					
					repeat with j from 1 to thisPlaylistNumberSongs ------ for each song:
						repeat 1 times ------ for skipping missing/duplicate songs
							
							-- GET THIS TRACK'S DETAILS
							set thisTrack to (get track j of thisPlaylist)
							set thisTrackDetails to my get_track_details(thisTrack)
							
							-- SKIP IF NO DURATION
							if ((item 4 of thisTrackDetails) is null) then
								set message to ({"MISSING DURATION: \"", (item 1 of thisTrackDetails as string), "\" by ", (item 2 of thisTrackDetails as string), return} as string)
								log message
								display dialog message with title myTitle buttons {"Continue"} default button 1 with icon iconError giving up after 10
								exit repeat
							end if
							
							-- SHOW ERROR IF FILE IS MISSING
							if (item 5 of thisTrackDetails) is equal to missing value then
								set message to ({"MISSING SONG: \"", (item 1 of thisTrackDetails as string), "\" by ", (item 2 of thisTrackDetails as string), return} as string)
								log message
								display dialog message with title myTitle buttons {"Continue"} default button 1 with icon iconError giving up after 10
								exit repeat
							end if
							
							-- CHECK FILE SIZE < 4GB
							tell application "Finder" to set fileSize to size of file (item 5 of thisTrackDetails as string)
							set fileSize to (fileSize / 1.073741824E+9)
							if (fileSize ≥ 4) then
								set sizeChoice to button returned of (display dialog ({"The size of the file '", (POSIX path of (item 5 of thisTrackDetails as string) as string), "' is ", ((round (fileSize * 100)) / 100), "GB.", return, return, "For maximum compatibility, it is not recommended to export files over 4GB. Would you like to skip this file or continue copying it?"} as string) with title myTitle buttons {"Cancel", "Skip", "Continue"} default button 2 with icon iconWarning)
								if (sizeChoice = "Skip") then
									exit repeat
								end if
							end if
							
							-- GET MORE DETAILS
							tell application "Finder"
								set thisTrackFileName to name of file (item 5 of thisTrackDetails)
							end tell
							set AppleScript's text item delimiters to (".")
							set thisTrackExtension to the last text item of thisTrackFileName
							set AppleScript's text item delimiters to originalDelimiter
							set the end of thisTrackDetails to thisTrackFileName
							set the end of thisTrackDetails to thisTrackExtension
							-- thisTrackDetails = {thisTrackName, thisTrackArtist, thisTrackAlbum, thisTrackDuration, thisTrackLocation, thisTrackAlbumArtist, thisTrackComposer, thisTrackNumber, thisTrackDisc, thisTrackCompilation, thisTrackFileName, thisTrackExtension}
							
							-- SHOW CURRENT PROGRESS
							my progress(i, thePlaylistsNumberGood, thisPlaylistName, j, thisPlaylistNumberSongs, (item 1 of thisTrackDetails), (item 2 of thisTrackDetails), (item 3 of thisTrackDetails))
							
							-- DEFINE PATH FOR NEW FILE
							set cwd to musicPath
							set foldersToMake to {}
							set foldersExist to {}
							set foldersAll to {}
							set folderStructure_NumberFolders to ((count of folderStructure_NewFolders) - 1)
							repeat with k from 1 to folderStructure_NumberFolders ------ for each new folder
								
								set newFolderTemplate to ((item k of folderStructure_NewFolders) as string)
								set newName to my define_from_attributes(newFolderTemplate, thisTrackDetails, thisPlaylistNumberSongs, j, i)
								set newNameStr to newName as string
								
								-- Make sure no folder starts with "." (no folder is hidden)
								if ((length of newNameStr > 0) and ((item 1 of newNameStr) = ".")) then
									set newNameStr to ({"_", ((characters 2 thru -1 of newNameStr) as string)} as string)
								end if
								
								-- Truncate name
								set newNameStr to my truncate_name(newNameStr, false)
								(*
								set pathComponentLength to the length of newNameStr
								if (pathComponentLength > maxPathComponentLength) then
									set pathComponentMiddle to (round (pathComponentLength / 2) rounding down) + 1
									set charsToRemove to {pathComponentLength - maxPathComponentLength + 1}
									set charstoRemoveLeft to (round (charsToRemove / 2) rounding down)
									set charstoRemoveRight to (round (charsToRemove / 2) rounding up) - 1
									set newNameStr to {(characters 1 thru (pathComponentMiddle - charstoRemoveLeft - 1) of newNameStr as string), "…", (characters (pathComponentMiddle + charstoRemoveLeft) thru -1 of newNameStr as string)} as string
								end if
								*)
								
								set pathExists to my folder_exists(cwd, newNameStr, "d")
								if not pathExists then
									set the end of foldersToMake to newNameStr
								else
									set the end of foldersExist to newNameStr
								end if
								set the end of foldersAll to newNameStr
								set cwd to {POSIX path of cwd as string, newNameStr, "/"} as string
								
							end repeat ------ for each new folder
							
							-- DEFINE NEW FILE NAME
							set newNameTemplate to (item -1 of folderStructure_NewFolders)
							set newName to my define_from_attributes(newNameTemplate, thisTrackDetails, thisPlaylistNumberSongs, j, i)
							set the end of newName to ({".", (item 12 of thisTrackDetails as string)} as string)
							set newNameStr to (newName as string)
							
							-- Truncate name
							set newNameStr to my truncate_name(newNameStr, true)
							
							-- Make sure new name starts with "." (not hidden)
							if ((length of newNameStr > 0) and ((item 1 of newNameStr) = ".")) then
								set newNameStr to ({"_", ((characters 2 thru -1 of newNameStr) as string)} as string)
							end if
							
							set makeNewFile to true
							
							-- CREATE NEW PATH
							set newFileExists to my folder_exists(cwd, newNameStr, "f")
							if (newFileExists = true) then
								set {newNameStr, _} to my fix_duplicate("song", ({"'", (item 1 of thisTrackDetails as string), "' by ", (item 2 of thisTrackDetails as string)} as string), newNameStr, cwd)
								if (newNameStr = "exit repeat") then
									exit repeat
								end if
								if (_ = "reference previous") then
									set makeNewFile to false
								end if
							end if
							set cwd to musicPath
							repeat with currentFolder in foldersAll
								set currentFolder to (currentFolder as string)
								if foldersToMake contains currentFolder then
									set cwd to my make_dir(cwd, currentFolder)
								else
									set cwd to {POSIX path of cwd as string, currentFolder, "/"} as string
								end if
							end repeat
							
							-- COPY FILE
							if (makeNewFile = true) then
								set newPath to ({cwd, newNameStr} as string)
								tell application "Finder"
									set newFile to (duplicate file (item 5 of thisTrackDetails) to (POSIX file cwd))
									set name of newFile to newNameStr
								end tell
							end if
							
							-- ADD FILE TO PLAYLIST FILE
							if (playlistFileType = "m3u") then
								my write_playlist_file_m3u(thePlaylistFile, thisTrackDetails, ({cwd, newNameStr} as string))
							end if
							
							-- LOG THE SUCCESSFUL COMPLETION
							set songsExported to (songsExported + 1)
							log {POSIX path of (item 5 of thisTrackDetails as string) as string, "   -->   ", cwd, newNameStr} as string
							
						end repeat ------ for skipping missing/duplicate songs
					end repeat ------ for each song
					
					set playlistsExported to (playlistsExported + 1)
					
					-- CLOSE PLAYLIST FILE
					close access thePlaylistFile
					
				on error e number n partial result r from f to t
					try
						close access thePlaylistFile
					end try
					if n = -1728 then
						display dialog ({"Can't make folders from ", attribute} as string) with title myTitle buttons {"OK"} default button 1 with icon iconError giving up after 10
					end if
					error e number n partial result r from f to t
					return
				end try ------ if anything goes wrong, close the playlist file
				
			end repeat ------ to allow skipping
		end repeat ------ for each playlist
		
		-- FINISH
		if (playlistsExported = 1) then
			set playlist_s to " playlist"
		else
			set playlist_s to " playlists"
		end if
		display notification ({"Finished exporting ", playlistsExported, playlist_s, " (", songsExported, " songs total)."} as string) with title myTitle
		
	end tell
end timeout



------------------------------
(* helper subroutines *)
------------------------------


(*
  DESCRIPTION: Logs a message.
  @param Str message = the text message to log
  @param List vars = optional - any variables to include in the message
*)
on log_out(message, vars)
	set AppleScript's text item delimiters to (return as string)
	if (vars is missing value) then
		log ({message, return} as string)
	else
		log ({message, vars, return} as string)
	end if
	set AppleScript's text item delimiters to originalDelimiter
end log_out


(*
  DESCRIPTION: Counts the number of times `this_item` appears in `this_list`.
  @param Int/Str this_item = the item to search for
  @param List this_list = the list in which to search
  @return Int - the number of matches
*)
on count_matches(this_list, this_item)
	set the match_counter to 0
	repeat with i from 1 to the count of this_list
		if (((item i of this_list) is this_item) or ((item i of this_list) contains this_item)) then
			set the match_counter to the match_counter + 1
		end if
	end repeat
	return the match_counter
end count_matches


(*
  DESCRIPTION: Cleans the illigal characters from a string.
  @param Str originalName = the string to clean
  @return Str - the cleaned string
*)
on clean_name(originalName)
	-- Clean accents
	set originalNameQuoted to (quoted form of (originalName as string))
	try
		set cleanAccents to (do shell script ({"echo ", originalNameQuoted, " | iconv -f UTF-8 -t ASCII//TRANSLIT"} as string))
	on error e number 1
		display dialog ({"Cannot clean ", originalNameQuoted, return, "Using original name …"} as string) with title myTitle buttons {"OK"} default button 1 with icon iconError giving up after 10
		set cleanAccents to originalNameQuoted
	end try
	
	-- Clean illegal characters 1
	set AppleScript's text item delimiters to illegalCharacters1
	set listName to every text item of cleanAccents
	set AppleScript's text item delimiters to "_"
	set listNameString to (listName as string)
	
	-- Clean illegal characters 2
	set AppleScript's text item delimiters to illegalCharacters2
	set listName to every text item of listNameString
	set AppleScript's text item delimiters to ""
	set listNameString to (listName as string)
	
	-- Return
	set AppleScript's text item delimiters to originalDelimiter
	return listNameString
end clean_name


(*
  DESCRIPTION: Checks if a folder exists.
  @param Str folderPath = path to root folder
  @param Str newName = name of the new folder
  @param Str mode = what to search for: folders (d) or files (f)
  @return Bool - true if the folder exists, false otherwise
*)
on folder_exists(folderPath, newName, mode)
	set pathToCheck to ({POSIX path of folderPath as string, newName} as string)
	if ((mode is not "d") and (mode is not "f")) then
		error ({"Cannot create folder or file ", pathToCheck, return, "The mode specified (", mode, ") is incorrect."} as string) number 1
	end if
	set found_var to (do shell script ({"if [ -", mode, " \"", pathToCheck, "\" ]; then echo \"FOUND\"; else echo \"NOT FOUND\"; fi"} as string))
	if found_var = "FOUND" then
		return true
	else
		return false
	end if
end folder_exists


(*
  DESCRIPTION: Make a folder if it doesn't exist.
  @param Str folderPath = path to root folder (in which to create new folder)
  @param Str newName = name of the new folder
  @return Str - path to the new folder (folderPath/newName)
*)
on make_dir(folderPath, newName)
	tell application "Finder"
		set newPath to ({POSIX path of folderPath as string, newName} as string)
		make new folder at (POSIX file folderPath) with properties {name:newName}
		return ({newPath, "/"} as string)
	end tell
end make_dir


(*
  DESCRIPTION: Convert an Arabic numeral to a Roman numeral. Used to convert the movement number.
  @param Int n = an Arabic numeral
  @return Int - a Roman numeral
*)
on arabic2roman(n)
	local r, i, n
	try
		if (n as integer) > 3999 then error "Max number is 3999." number 1
		set r to ""
		repeat with i from 1 to (count (n as string))
			set r to item (((item -i of (n as string)) as integer) + 1) of item i of ¬
				{{"", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"}, ¬
					{"", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"}, ¬
					{"", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"}, ¬
					{"", "M", "MM", "MMM"}} & r
		end repeat
		return r
	on error eMsg number eNum
		error "Can't convert to Roman numeral: " & eMsg number eNum
	end try
end arabic2roman


(*
  DESCRIPTION: Get the metadata of a track from Apple Music.
  @param Track thisTrack = a reference to an Apple Music track
  @return List - the track's metadata
*)
on get_track_details(thisTrack)
	tell application "Music"
		
		-- GET NAME/WORK
		if (nameChoice = true) then
			set thisTrackName to (get name of thisTrack)
		else
			if ((work of thisTrack) as string) is "" then
				set thisTrackName to (get name of thisTrack)
			else
				set thisTrackName to ({(work of thisTrack) as string, ": ", my arabic2roman((movement number of thisTrack) as string), ". ", (movement of thisTrack) as string} as string)
			end if
		end if
		
		-- GET ARTIST
		if artist of thisTrack = "" then
			set thisTrackArtist to "Unknown Artist"
		else
			set thisTrackArtist to (get artist of thisTrack)
		end if
		
		-- GET ALBUM
		if album of thisTrack = "" then
			set thisTrackAlbum to "Unknown Album"
		else
			set thisTrackAlbum to (get album of thisTrack)
		end if
		
		-- GET DURATION
		set thisTrackDuration to (get duration of thisTrack)
		if (thisTrackDuration is missing value) then
			set thisTrackDuration to null
		else
			set thisTrackDuration to round thisTrackDuration rounding down
		end if
		
		-- GET LOCATION & SKIP IF MISSING
		set thisTrackLocation to (get location of thisTrack)
		
		-- IF SELECTED: GET ALBUM ARTIST
		if ((item 2 of attrShow) is true) then
			if album artist of thisTrack = "" then
				set thisTrackAlbumArtist to "Unknown Album Artist"
			else
				set thisTrackAlbumArtist to (get album artist of thisTrack)
			end if
		else
			set thisTrackAlbumArtist to null
		end if
		
		-- IF SELECTED: GET COMPOSER
		if ((item 4 of attrShow) is true) then
			if ((composer of thisTrack) as string) is equal to "" then
				set thisTrackComposer to "Unknown Composer"
			else
				set thisTrackComposer to (get composer of thisTrack)
			end if
		else
			set thisTrackComposer to null
		end if
		
		-- IF SELECTED: GET TRACK NUMBER
		if ((item 6 of attrShow) is true) then
			set thisTrackNumber to (get track number of thisTrack)
		else
			set thisTrackNumber to null
		end if
		
		-- IF SELECTED: GET DISC NUMBER
		if ((item 7 of attrShow) is true) then
			set thisTrackDisc to (get disc number of thisTrack)
		else
			set thisTrackDisc to null
		end if
		
		-- IS TRACK PART OF A COMPILATION?
		set thisTrackCompilation to (get compilation of thisTrack)
		
		-- RETURN VALUES
		return {thisTrackName, thisTrackArtist, thisTrackAlbum, thisTrackDuration, thisTrackLocation, thisTrackAlbumArtist, thisTrackComposer, thisTrackNumber, thisTrackDisc, thisTrackCompilation}
		
	end tell
end get_track_details


(*
  DESCRIPTION: Get a specific piece of metadata from the list of extracted metadata for a track from Apple Music.
  @param Str folderStructureItem = the attribute to search for
  @param List trackAttributes = the list of extracted metadata for the track
  @return Str - the value of the attribute
*)
on value_of_attr(folderStructureItem, thisTrackDetails)
	if folderStructureItem contains "[album]" then
		return (item 3 of thisTrackDetails)
	else if folderStructureItem contains "[album artist]" then
		return (item 6 of thisTrackDetails)
	else if folderStructureItem contains "[artist]" then
		return (item 2 of thisTrackDetails)
	else if folderStructureItem contains "[composer]" then
		return (item 7 of thisTrackDetails)
	else if folderStructureItem contains "[track name]" then
		return (item 1 of thisTrackDetails)
	else if folderStructureItem contains "[track number]" then
		set trackNumber to (item 8 of thisTrackDetails)
		if trackNumber < 10 then
			return (("0" & trackNumber) as string)
		else
			return (trackNumber as string)
		end if
	else if folderStructureItem contains "[disc number]" then
		set discNumber to (item 9 of thisTrackDetails)
		if discNumber < 10 then
			return (("0" & discNumber) as string)
		else
			return (discNumber as string)
		end if
	else if folderStructureItem contains "[playlist order number]" then
		return folderStructureItem
	else if folderStructureItem contains "[original file name]" then
		return folderStructureItem
	else
		return null
	end if
end value_of_attr


(*
  DESCRIPTION: Define a new folder/song name based on the given name template and the extracted metadata.
  @param Str newTemplate = template for the new name
  @param List thisTrackDetails = the list of extracted metadata for the track
  @param Int thisPlaylistNumberSongs = number of songs in the current playlist
  @param Int j = the number of the current song (eg. 5th song of playlist is 5)
  @param Int i = the number of the current playlist (eg. 2nd playlist to be exported is 2)
  @return Str - the new name of the folder or song
*)
on define_from_attributes(newTemplate, thisTrackDetails, thisPlaylistNumberSongs, j, i)
	set AppleScript's text item delimiters to ("[")
	set newTemplate_split to every text item of newTemplate
	set AppleScript's text item delimiters to ("]")
	set newTemplate_split to every text item of (newTemplate_split as string)
	set AppleScript's text item delimiters to originalDelimiter
	set newNameAttrLength to (count of newTemplate_split)
	
	set newName to {}
	repeat with k from 1 to newNameAttrLength
		set theItem to ((item k of newTemplate_split) as string)
		set theItemBrackets to ({"[", theItem, "]"} as string)
		set newNameTMP to my value_of_attr(theItemBrackets, thisTrackDetails)
		if (newNameTMP is not null) then
			if (newNameTMP = "[playlist order number]") then
				if (i = 1) then
					set playlistOrderNumber to j
				else
					set playlistOrderNumber to songsExported
				end if
				if ((thisPlaylistNumberSongs > 9) and (playlistOrderNumber < 10)) then
					set newNameTMP to (("0" & playlistOrderNumber) as string)
				else if ((thisPlaylistNumberSongs > 99) and (playlistOrderNumber < 100)) then
					set newNameTMP to (("00" & playlistOrderNumber) as string)
				else if ((thisPlaylistNumberSongs > 999) and (playlistOrderNumber < 1000)) then
					set newNameTMP to (("000" & playlistOrderNumber) as string)
				else
					set newNameTMP to (playlistOrderNumber as string)
				end if
			else if (newNameTMP = "[original file name]") then
				set newNameTMP to (item 11 of thisTrackDetails)
				set {newNameTMP, _} to my extract_extension(newNameTMP)
			end if
			set the end of newName to my clean_name(newNameTMP)
		else -- if (newNameTMP is null) then
			set the end of newName to my clean_name(theItem)
		end if
	end repeat
	return newName
end define_from_attributes


(*
  DESCRIPTION: Offers the user a choice when duplicates are detected, and actions that choice.
  @param Str mode = type of item: "playlist" or "song"
  @param Str nameOriginal = the original name of the item
  @param Str nameClean = the cleaned name of the item
  @param Str thePlaylistsCleanOrCwd = for playlists, this is the list `thePlaylistsClean`; for songs, this is the `cwd` path
  @return List - [cleaned name with number appended, {thePlaylistsClean for playlists; null for songs}]
*)
on fix_duplicate(mode, nameOriginal, nameClean, thePlaylistsCleanOrCwd)
	if (mode = "playlist") then
		set plural to "playlists"
		set skipButton to "Skip"
		set nameOriginal to ({"'", nameOriginal, "''"} as string)
	else if (mode = "song") then
		set plural to "songs"
		set skipButton to "Reference previous"
		set {nameClean, nameCleanExtension} to my extract_extension(nameClean)
	else
		error ({"Unknown mode in the fix_duplicate method: '", mode, "'."} as string) number 1
	end if
	
	if (folderChoice = "Same folder") then
		set dupeChoice to skipButton
	else
		set dupeChoice to button returned of (display dialog ({"The clean name of the ", mode, " ", nameOriginal, " is '", nameClean, "', which is taken by another ", mode, ".", return, return, ¬
			"Would you like to skip this ", mode, " or try to fix the name by appending a number to the name?", return, return, ¬
			"[default option: ", skipButton, "]"} as string) with title myTitle buttons {"Cancel", skipButton, "Try to fix"} default button 2 with icon iconError giving up after 60)
		if (dupeChoice = "") then
			set dupeChoice to skipButton
		end if
	end if
	
	if (dupeChoice = "Skip") then
		return {"exit repeat", null}
	else if (dupeChoice = "Reference previous") then
		return {{nameClean, ".", nameCleanExtension} as string, "reference previous"}
	else if (dupeChoice = "Try to fix") then
		repeat with k from 2 to dupeLimit
			set nameClean2 to ({nameClean, "_", k} as string)
			
			set nameOK to false
			if ((mode = "playlist") and (thePlaylistsCleanOrCwd does not contain nameClean2)) then
				set the end of thePlaylistsCleanOrCwd to nameClean2
				set nameOK to true
			else if ((mode = "song") and (my folder_exists(thePlaylistsCleanOrCwd, ({nameClean2, ".", nameCleanExtension} as string), "f")) = false) then
				set nameOK to true
				set nameClean2 to ({nameClean2, ".", nameCleanExtension} as string)
			end if
			
			if (nameOK = true) then
				display dialog ({"The clean name of the ", mode, " '", nameOriginal, "' is now '", nameClean2, "'."} as string) with title myTitle buttons {"Cancel", "Continue"} default button 2 with icon iconWarning giving up after 10
				set k to 1
				exit repeat
			end if
		end repeat
		
		if ((k = dupeLimit) or (nameOK = false)) then
			display dialog ({"There are already ", dupeLimit, " ", plural, " with the base name '", nameClean, "' - skipping the ", mode, " '", nameOriginal, "'."} as string) with title myTitle buttons {"Cancel", "Continue"} default button 2 with icon iconError giving up after 10
			return {"exit repeat", null}
		else
			return {nameClean2, thePlaylistsCleanOrCwd}
		end if
	end if
end fix_duplicate


(*
  DESCRIPTION: Extract the extension from a filename.
  @param Str componentName = tha name conaining a file extension
  @return List - the name without the extension, and the extension without the "."
*)
on extract_extension(componentName)
	set componentExtension to (do shell script ({"x=\"", componentName, "\"; echo ${x##*.}"} as string))
	set componentName to (do shell script ({"x=\"", componentName, "\"; echo ${x%.*}"} as string))
	return {componentName, componentExtension}
end extract_extension


(*
  DESCRIPTION: Truncate a name in the middle so that it is not longer than `maxPathComponentLength `.
  @param Str newNameStr = the item name to truncate
  @param Bool hasExtension = true if the item has a file extension, false otherwise
  @return Str - the truncated name of the folder or song
*)
on truncate_name(newNameStr, hasExtension)
	
	if (hasExtension = false) then
		set newName to newNameStr
		set pathComponentLength to the length of newNameStr
		set pathExtensionLength to 0
	else if (hasExtension = true) then
		set {newName, newNameExtension} to my extract_extension(newNameStr)
		set pathComponentLength to the length of newName
		set pathExtensionLength to the length of newNameExtension
	else
		error ({"Unknown mode in the truncate_name method: '", hasExtension, "'."} as string) number 1
	end if
	
	if ((pathComponentLength + pathExtensionLength) ≤ maxPathComponentLength) then
		return newNameStr
	else
		set ellipsisLength to (length of ellipsisChar)
		set pathComponentMiddle to (round (pathComponentLength / 2) rounding down) + 1
		set charsToRemove to {pathComponentLength - maxPathComponentLength + 1}
		set limitLeft to (pathComponentMiddle - (round (charsToRemove / 2) rounding down) - (round (ellipsisLength / 2) rounding down))
		set limitRight to (pathComponentMiddle + (round (charsToRemove / 2) rounding up) + (round (ellipsisLength / 2) rounding up))
		
		if (hasExtension = true) then
			set limitLeft to (limitLeft - 2)
			set limitRight to (limitRight + 2)
		end if
		
		set newNameStr2 to {(characters 1 thru limitLeft of newName as string), ellipsisChar, (characters limitRight thru -1 of newName as string)} as string
		
		set finalLength to (length of newNameStr2)
		if (finalLength > maxPathComponentLength) then
			display dialog ({"The name \"", newNameStr, "\" could not be truncated to ", maxPathComponentLength, " characters.", return, return, "The final length is ", finalLength, " characters."} as string) with title myTitle buttons {"Cancel", "Continue"} default button 1 with icon iconError giving up after 10
		end if
		
		if (hasExtension = true) then
			return ({newNameStr2, ".", newNameExtension} as string)
		else
			return newNameStr2
		end if
		
	end if
end truncate_name


(*
  DESCRIPTION: Write song details to an M3U file.
  @param File thePlaylistFile = reference to the file to use (must be currently open for writing)
  @param List thisTrackDetails = the extracted metadata for this song
  @param Str newFilePath = path to song's new file after exporting
*)
on write_playlist_file_m3u(thePlaylistFile, thisTrackDetails, newFilePath)
	tell application "Finder"
		write ("#EXTINF:" & (item 4 of thisTrackDetails as string) & "," & (item 2 of thisTrackDetails as string) & " - " & (item 1 of thisTrackDetails as string) & return) to thePlaylistFile
		write (POSIX path of newFilePath & return) to thePlaylistFile
	end tell
end write_playlist_file_m3u



------------------------------
(* progress *)
------------------------------

(*
  DESCRIPTION: Show progress visually.
  @param Int i = current playlist number
  @param Int thePlaylistsNumber = total number of playlists
  @param Str thisPlaylistName = name of current playlist
  @param Int j = current track in playlist
  @param Int thisPlaylistNumberSongs = number of songs in playlist
  @param Str thisTrackName = name of current track
  @param Str thisTrackArtist = artist of current track
  @param Str thisTrackAlbum = album of current track
*)
on progress(i, thePlaylistsNumber, thisPlaylistName, j, thisPlaylistNumberSongs, thisTrackName, thisTrackArtist, thisTrackAlbum)
	
	set progress total steps to thisPlaylistNumberSongs
	
	set percent to ((round ((j / thisPlaylistNumberSongs * 100) * 100)) / 100)
	set progress description to ({"Exporting playlist ", i, " of ", thePlaylistsNumber, " (\"", thisPlaylistName, "\").", return, return, ¬
		"Processing track ", j, " of ", thisPlaylistNumberSongs, " (", percent, "%)"} as string)
	
	set progress additional description to ({return, "Name: ", thisTrackName, ¬
		return, "Artist: ", thisTrackArtist, ¬
		return, "Album: ", thisTrackAlbum} as string)
	
	set progress completed steps to j
	
end progress