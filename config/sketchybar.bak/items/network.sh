#!/usr/bin/env sh

sketchybar --clone network.label label_template                  \
           --set   network.label label=net                       \
                                 position=right                   \
                                 drawing=on                      \
                                                                 \
           --add   item          network.vpn right               \
           --set   network.vpn   update_freq=15                  \
                                 icon.color=$RED                 \
                                 icon.highlight_color=$GREEN     \
                                 icon.font="$FONT:Bold:16.0"     \
                                 script="$PLUGIN_DIR/vpn.sh"     \
                                                                 \
           --add   item          network.up right                 \
           --set   network.up    label.font="$FONT:Heavy:9"      \
                                 icon.font="$FONT:Heavy:9"       \
                                 icon=$NETWORK_UP                \
                                 icon.highlight_color=$BLUE      \
                                 width=0                         \
                                 y_offset=5                      \
                                 update_freq=2                   \
                                 script="$PLUGIN_DIR/network.sh" \
                                                                 \
           --add   item          network.down right               \
           --set   network.down  label.font="$FONT:Heavy:9"      \
                                 icon.font="$FONT:Heavy:9"       \
                                 icon=$NETWORK_DOWN              \
                                 icon.highlight_color=$RED       \
                                 y_offset=-5                     \
                                                                 \
           --add   bracket       network                         \
                                 network.label                   \
                                 network.vpn                     \
                                 network.up                      \
                                 network.down                    \
                                                                 \
           --set   network       background.drawing=on
