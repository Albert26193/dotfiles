#!/bin/bash

function apple_long_click {
  defaults write -g ApplePressAndHoldEnabled -bool false
  # 10 --> 150ms(default: 15, 225ms)
  defaults write -g InitialKeyRepeat -int 12
  # 1 -->  15ms(default: 2, 30ms)
  defaults write -g KeyRepeat -int 2
}

function close_animation {
  # dock
  defaults write com.apple.dock autohide-time-modifier -float 0.5;killall Dock
  defaults write com.apple.Dock autohide-delay -float 0; killall Dock
}

apple_long_click &&
close_animation
