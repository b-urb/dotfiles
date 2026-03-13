local source = debug.getinfo(1, "S").source
local helpers_dir = source:sub(1, 1) == "@" and source:sub(2):match("(.*/)") or nil
local home_dir = os.getenv("HOME")

if not home_dir and source:sub(1, 1) == "@" then
  home_dir = source:sub(2):match("^(.-)/%.config/")
end

if home_dir then
  package.cpath = package.cpath .. ";" .. home_dir .. "/.local/share/sketchybar_lua/?.so"
end

if helpers_dir then
  os.execute("(cd " .. string.format("%q", helpers_dir) .. " && make)")
else
  os.execute("(cd helpers && make)")
end
