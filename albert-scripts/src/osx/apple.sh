#!/bin/bash

# @desc: 关闭 macOS 长按选词并加快按键重复速度
# @tags: macos keyboard
function ab.apple.long_click {
  defaults write -g ApplePressAndHoldEnabled -bool false
  # 10 --> 150ms(default: 15, 225ms)
  defaults write -g InitialKeyRepeat -int 12
  # 1 -->  15ms(default: 2, 30ms)
  defaults write -g KeyRepeat -int 2
}

# @desc: 缩短 macOS Dock 自动隐藏动画与延迟
# @tags: macos dock
function ab.apple.close_animation {
  defaults write com.apple.dock autohide-time-modifier -float 0.5
  defaults write com.apple.Dock autohide-delay -float 0
  killall Dock
}

# @desc: fzf 搜索 macOS 应用并输出其 Bundle Identifier
# @tags: macos app bundle
function ab.apple.get_app_id {
  mdfind 'kMDItemKind == "Application"'     | fzf --preview='mdls -r -n kMDItemCFBundleIdentifier {}'     | xargs -I{} mdls -r -n kMDItemCFBundleIdentifier {}
}

# @desc: fzf 搜索本机已安装字体并预览字体家族与文件变体
# @tags: macos font
function ab.apple.font {
  fc-list --format="%{file}: %{family}: style=%{style}\n" | sort | fzf     --height 80%     --layout=reverse     --border     --prompt="搜索字体 (输入 Iosevka): "     --header "快捷键: Enter 确认选择 | ESC 退出"     --preview-window="bottom:50%:wrap"     --preview '
        FAMILY=$(echo {} | cut -d":" -f2 | sed "s/^ //");
        echo "【 字体家族：$FAMILY 】";
        echo "--------------------------------------------------";
        echo "本地物理路径及变体详情：";
        fc-list ":family=$FAMILY" file style | sed "s/: /  ->  风格: /"
    '
}
