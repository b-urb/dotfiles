# Prerequisites

- install brew on macs
- run `brew bundle install`


# How to use

1. Log in to Bitwarden CLI
2. `git clone --recursive`
3. `./install`

## Yabai 

Small tip for the IntelliJ users found on [https://blog.mindtravel.nl/tag/yabai/]:
"Go to IntelliJ IDEA > Preferences > Appearance & behavior > Appearance > UI Options > Always show full path in window header"

Then add to the configuration of yabai:

yabai -m rule --add app="IntelliJ IDEA" manage=off
yabai -m rule --add app="IntelliJ IDEA" title=".*\[(.*)\].*" manage=on
Now yabai will only take control of intelliJ main screen and not try to resize the popups


# About 

My dotfile config with yabai/skhd for macos and i3 on arch. 
