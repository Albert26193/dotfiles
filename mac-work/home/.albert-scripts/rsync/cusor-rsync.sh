#!/bin/bash

function rsync_cursor_settings {
	SRC_DIR="$HOME/Library/Application Support/Cursor/User"
	DEST_DIR="$HOME/Documents/cursor-config-mbp1"

	([[ ! -d "$SRC_DIR" ]] || [[ ! -d "$DEST_DIR" ]]) && {
		printf "%s\n" "dir not exists"
		return 1
	}

	rsync -av --delete \
		"$SRC_DIR/settings.json" \
		"$SRC_DIR/keybindings.json" \
		"$DEST_DIR/"

	return 0
}

# rsync_cursor_settings
