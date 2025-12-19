#!/usr/bin/env sh

HAS_BATTERY=$(if [ "$(pmset -g batt | grep "Battery")" = "" ]; then echo "false"; else echo "true"; fi)
SVIM_POPUP_SCRIPT="sketchybar --set system.svim popup.drawing=off"

sketchybar --add       event              window_focus                                  \
           --add       event              wifi                                          \
           --add       event              battery                                       \
                                                                                        \
                                                                                        \
           --add       item               system.yabai q                                \
           --set       system.yabai       script="$PLUGIN_DIR/yabai.sh"                 \
                                          icon.font="$FONT:Bold:16.0"                   \
                                          label.drawing=off                             \
                                          icon.width=30                                 \
                                          icon=$YABAI_GRID                              \
                                          icon.color=$GREEN                             \
                                          updates=on                                    \
           --subscribe system.yabai       window_focus mouse.clicked                    \
                                                                                        \
           --clone     system.label       label_template                                \
           --set       system.label       label=Window                                  \
                                          position=q                                    \
                                          drawing=on                                    \
                                          icon.drawing=off                              \
                                          icon.background.drawing=on                    \
                                          icon.background.color=$TRANSPARENT            \
                                          icon.background.image.scale=0.5               \
                                          background.padding_right=1                    \
                                          script="$PLUGIN_DIR/window_title.sh"          \
           --subscribe system.label       front_app_switched                            \
                                                                                        \
           --add       alias              "Control Center,Battery" e                    \
           --set "Control Center,Battery" update_freq=4                                 \
                                          drawing=$HAS_BATTERY                          \
                                          label.drawing=off                             \
                                          background.padding_right=-3                   \
                                          background.padding_left=-9                    \
                                          click_script="sketchybar --trigger battery;
                                                        $POPUP_CLICK_SCRIPT"            \
                                          popup.align=right                             \
                                                                                        \
           --add       item               battery.details popup."Control Center,Battery"\
           --set       battery.details    updates=$HAS_BATTERY                          \
                                          script="$PLUGIN_DIR/battery.sh"               \
                                          label.padding_right=8                         \
           --subscribe battery.details    battery                                       \
                                                                                        \
           --add       alias              "Control Center,WiFi" e                       \
           --set    "Control Center,WiFi" update_freq=4                                 \
                                          icon.drawing=off                              \
                                          label.drawing=off                             \
                                          background.padding_left=-4                    \
                                          background.padding_right=-4                   \
                                          click_script="sketchybar --trigger wifi;
                                                        $POPUP_CLICK_SCRIPT"            \
                                          popup.align=right                             \
                                                                                        \
           --add       item               wifi.details popup."Control Center,WiFi"      \
           --set       wifi.details       updates=on                                    \
                                          script="$PLUGIN_DIR/wifi.sh"                  \
                                          label.padding_right=5                         \
           --subscribe wifi.details       wifi                                          \
                                                                                        \
           --add       alias              "Control Center,Sound" e                      \
           --set   "Control Center,Sound" update_freq=4                                 \
                                          icon.drawing=off                              \
                                          label.drawing=off                             \
                                          background.padding_left=-4                    \
                                          background.padding_right=-4                   \
                                          click_script="$POPUP_CLICK_SCRIPT"            \
                                          popup.horizontal=on                           \
                                          popup.align=right                             \
                                          popup.background.image.scale=0.5              \
                                          popup.background.color=$TRANSPARENT           \
                                                                                        \
           --add       item               system.mic e                                  \
           --set       system.mic         update_freq=100                               \
	                                  icon.padding_left=1                           \
                                          label.drawing=off                             \
                                          script="$PLUGIN_DIR/mic.sh"                   \
           --subscribe system.mic         mouse.clicked                                 \
                                                                                        \
           --add       bracket            system                                        \
                                          system.label                                  \
                                          system.yabai                                  \
                                          system.mic                                    \
                                          "Control Center,Sound"
