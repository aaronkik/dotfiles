#!/bin/sh

# ~/.macos — https://mths.be/macos

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

defaults write com.apple.Accessibility EnhancedBackgroundContrastEnabled -float 1

defaults write com.apple.AdLib allowApplePersonalizedAdvertising -float 0
defaults write com.apple.AdLib allowIdentifierForAdvertising -float 0

defaults write com.apple.controlcenter NSStatusItem-Visible-Battery -float 1

defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder FXRemoveOldTrashItems -float 1
defaults write com.apple.finder ShowRecentTags -float 0
defaults write com.apple.finder ShowStatusBar -float 1

defaults write com.apple.menuextra.clock ShowSeconds -float 1

defaults write com.apple.WindowManager EnableTiledWindowMargins -float 0

# Enable swipe between pages
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true

# Enable keyboard navigation: Settings -> Keyboard -> Keyboard navigation
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

# Use FN keys as standard keys
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

# Disable Man page shortcuts interaction with JetBrains IDE shortcuts.
# https://biercoff.com/cmd-shift-a-opens-terminal/
# https://gist.github.com/theodson/b4282a3b6e54091db4d52a4c3c10ad25
defaults write pbs NSServiceStatus '{
  "com.apple.Terminal - Open man Page in Terminal - openManPage" = {
    "presentation_modes" = {
      "ContextMenu" = false;
      "ServicesMenu" = false;
    };
    "enabled_context_menu" = false;
    "enabled_services_menu" = false;
  };
  "com.apple.Terminal - Search man Page Index in Terminal - searchManPages" = {
    "presentation_modes" = {
      "ContextMenu" = false;
      "ServicesMenu" = false;
    };
    "enabled_context_menu" = false;
    "enabled_services_menu" = false;
  };
}'

## Reset terminal settings
rm ~/Library/Preferences/com.apple.Terminal.plist

echo "Importing Terminal.app themes..."
TERMINAL_THEMES_DIR="$HOME/.custom_config/Terminal.app/themes"

for theme_file in "$TERMINAL_THEMES_DIR"/*.terminal; do
    if [ -f "$theme_file" ]; then
        theme_name=$(basename "$theme_file" .terminal)
        echo "Importing theme: $theme_name"

        /usr/libexec/PlistBuddy -c "Add :'Window Settings':'$theme_name' dict" ~/Library/Preferences/com.apple.Terminal.plist 2>/dev/null
        /usr/libexec/PlistBuddy -c "Merge '$theme_file' :'Window Settings':'$theme_name'" ~/Library/Preferences/com.apple.Terminal.plist
    fi
done

defaults write com.apple.Terminal "Default Window Settings" -string "catppuccin-frappe"
defaults write com.apple.Terminal "Startup Window Settings" -string "catppuccin-frappe"

