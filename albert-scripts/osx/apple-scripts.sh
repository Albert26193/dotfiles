#!/bin/bash

function ab.apple.long_click {
  defaults write -g ApplePressAndHoldEnabled -bool false
  # 10 --> 150ms(default: 15, 225ms)
  defaults write -g InitialKeyRepeat -int 12
  # 1 -->  15ms(default: 2, 30ms)
  defaults write -g KeyRepeat -int 2
}

function ab.apple.close_animation {
  # dock
  defaults write com.apple.dock autohide-time-modifier -float 0.5;killall Dock
  defaults write com.apple.Dock autohide-delay -float 0; killall Dock
}

function ab.apple.kill_amethyst {
  ps -ef | grep -i "[a]meth" | awk '{print $2}' | xargs -I {} kill -9 {}
}

# zellij
function ab.apple.ze_killall {
  zellij ls | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}' | xargs -I {} zellij delete-session {}
}

# aerospace
ab.apple.aerospace_write_dock() {
  defaults write com.apple.dock expose-group-apps -bool true && killall Dock
}

# get apple app id
function ab.apple.get_app_id {
   mdfind 'kMDItemKind == "Application"' \
    | fzf --preview='mdls -r -n kMDItemCFBundleIdentifier {}' \
    | xargs -I{} mdls -r -n kMDItemCFBundleIdentifier {}
}

# albert apple font
function ab.apple.font {
  # 1. 格式化输出：文件路径 | 字体家族 | 风格样式
  # 2. 通过 fzf 进行搜索
  # 3. 选中后，利用预览窗口展示该字体家族下的所有物理文件和变体
  fc-list --format="%{file}: %{family}: style=%{style}\n" | sort | fzf \
    --height 80% \
    --layout=reverse \
    --border \
    --prompt="搜索字体 (输入 Iosevka): " \
    --header "快捷键: Enter 确认选择 | ESC 退出" \
    --preview-window="bottom:50%:wrap" \
    --preview '
        # 提取选中的字体家族名称
        FAMILY=$(echo {} | cut -d":" -f2 | sed "s/^ //");
        echo "【 字体家族：$FAMILY 】";
        echo "--------------------------------------------------";
        echo "本地物理路径及变体详情：";
        # 搜索该家族下的所有具体物理文件和风格变体
        fc-list ":family=$FAMILY" file style | sed "s/: /  ->  风格: /"
    '
}
