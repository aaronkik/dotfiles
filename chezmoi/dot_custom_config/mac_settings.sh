#!/bin/sh

# ~/.macos — https://mths.be/macos

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

set_terminal_font_and_size='
tell application "Terminal"
    set current settings of front window to settings set "Basic"
    set font name of front window to "FiraCode Nerd Font Retina"
    set font size of front window to 18
end tell
'

osascript -e "$set_terminal_font_and_size"

###############################################################################
# Kill affected applications                                                  #
###############################################################################

# for app in "Terminal"; 
#     do killall "${app}" &> /dev/null
# done

# echo "\033[33mAffected applications killed. Some of these changes may require a logout/restart to take effect.\033[m"