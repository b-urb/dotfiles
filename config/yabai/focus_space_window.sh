#!/bin/bash

# Get the YABAI_SPACE_ID from the script's arguments
YABAI_SPACE_ID="$1"

# Get the space index for the given YABAI_SPACE_ID
SPACE_INDEX=$(yabai -m query --spaces | jq --arg space_id "$YABAI_SPACE_ID" 'map(select(.id == ($space_id | tonumber)))[0].index')


# Use the space index to get the window id to focus
WINDOW_ID_TO_FOCUS=$(yabai -m query --windows --space $SPACE_INDEX | jq --argjson space_index "$SPACE_INDEX" 'map(select(.space == $space_index))[0].id')

# Focus the window
yabai -m window --focus "$WINDOW_ID_TO_FOCUS"

