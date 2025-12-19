#!/usr/bin/env sh

sketchybar --add item   topmem right                    \
           --set topmem icon=$MEMORY                   \
                        icon.padding_left=15           \
                        update_freq=15                 \
                        script="$PLUGIN_DIR/topmem.sh"
