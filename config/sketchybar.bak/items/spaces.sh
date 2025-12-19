#!/usr/bin/env sh

sketchybar --add   space          space_template left                \
           --set   space_template icon.highlight_color=0xff9dd274    \
                                  label.drawing=off                  \
                                  drawing=off                        \
                                  updates=on                         \
                                  label.font="$FONT:Black:13.0"      \
                                  icon.font="$FONT:Bold:17.0"        \
                                  script="$PLUGIN_DIR/space.sh"      \
                                  icon.padding_right=6               \
                                  icon.padding_left=3                \
                                  background.padding_left=2          \
                                  background.padding_right=2         \
                                  icon.background.height=2           \
                                  icon.background.color=$ICON_COLOR  \
                                  icon.background.color=$ICON_COLOR  \
                                  icon.background.y_offset=-13       \
                                  click_script="$SPACE_CLICK_SCRIPT" \
                                                                     \
           --clone spaces.label label_template                     \
           --set   spaces.label label=idle                          \
                                  label.width=38                     \
                                  label.align=center                 \
                                  position=left                      \
                                  drawing=on                         \
           --clone spaces.term  space_template                     \
           --set   spaces.term  associated_space=1                 \
                                  icon=$SPACES_TERM                  \
                                  icon.highlight_color=$GREEN        \
                                  icon.background.color=$GREEN       \
                                  drawing=on                         \
                                                                     \
           --clone spaces.code  space_template                     \
           --set   spaces.code  associated_space=2                 \
                                  icon=$SPACES_CODE                   \
                                  icon.highlight_color=$ORANGE       \
                                  icon.background.color=$ORANGE      \
                                  drawing=on                         \
                                                                     \
           --clone spaces.web   space_template                     \
           --set   spaces.web   associated_space=3                 \
                                  icon=$SPACES_WEB                   \
                                  icon.highlight_color=$BLUE         \
                                  icon.background.color=$BLUE        \
                                  drawing=on                         \
                                                                     \
                                                                     \
           --clone spaces.chat space_template                     \
           --set   spaces.chat associated_space=4                 \
                                  icon=$SPACES_CHAT                 \
                                  icon.highlight_color=$YELLOW       \
                                  icon.background.color=$YELLOW      \
                                  drawing=on                         \
           --clone spaces.todo space_template                     \
           --set   spaces.todo associated_space=5                 \
                                  icon=$SPACES_TODO                  \
                                  icon.highlight_color=$YELLOW       \
                                  icon.background.color=$YELLOW      \
                                  drawing=on                         \
                                                                     \
           --clone spaces.idle1  space_template                     \
           --set   spaces.idle1 associated_space=6                 \
                                  icon=$SPACES_IDLE                  \
                                  icon.highlight_color=$YELLOW       \
                                  icon.background.color=$YELLOW      \
                                  drawing=on                         \
           --clone spaces.idle2  space_template                     \
           --set   spaces.idle2  associated_space=7                 \
                                  icon=$SPACES_IDLE                  \
                                  icon.highlight_color=$YELLOW       \
                                  icon.background.color=$YELLOW      \
                                  drawing=on                         \
           --clone spaces.idle3  space_template                     \
           --set   spaces.idle3  associated_space=8                 \
                                  icon=$SPACES_IDLE                  \
                                  icon.highlight_color=$YELLOW       \
                                  icon.background.color=$YELLOW      \
                                  drawing=on                         \
                                                                     \
           --add   bracket        idle_spaces                        \
                                  spaces.idle1                      \
                                  spaces.idle2                      \
                                  spaces.idle3                      \
	  --set         idle_spaces background.color=0xffffffff \
                                        background.corner_radius=4  \
                                        background.height=25 \
                                                                     \
                                                                     \
           --clone spaces.music space_template                     \
           --set   spaces.music associated_space=10                 \
                                  icon=$SPACES_MUSIC                 \
                                  icon.highlight_color=$YELLOW       \
                                  icon.background.color=$YELLOW      \
                                  drawing=on                         \
                                                                     \
