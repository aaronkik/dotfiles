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
