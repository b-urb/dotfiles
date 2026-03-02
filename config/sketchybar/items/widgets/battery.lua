local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local PMSET_CMD = "/usr/bin/pmset -g batt"
local IOREG_BATTERY_CMD = "/usr/sbin/ioreg -rc AppleSmartBattery"
  .. " | /usr/bin/awk '/\"CurrentCapacity\"/ {cur=$3} /\"MaxCapacity\"/ {max=$3}"
  .. " /\"IsCharging\"/ {chg=$3} /\"ExternalConnected\"/ {ac=$3}"
  .. " END { if (max > 0) { printf \"%d|%s|%s\\n\", int((cur/max)*100 + 0.5), chg, ac } }'"

local battery = sbar.add("item", "widgets.battery", {
  position = "right",
  icon = {
    font = {
      style = settings.font.style_map["Regular"],
      size = 19.0,
    }
  },
  label = { font = { family = settings.font.numbers } },
  update_freq = 180,
  popup = { align = "center" }
})

local remaining_time = sbar.add("item", {
  position = "popup." .. battery.name,
  icon = {
    string = "Time remaining:",
    width = 100,
    align = "left"
  },
  label = {
    string = "??:??h",
    width = 100,
    align = "right"
  },
})

local function update_battery()
  sbar.exec(IOREG_BATTERY_CMD, function(batt_info)
    local icon = "!"
    local label = "?"
    local color = colors.green

    local summary = (batt_info or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local charge_s, charging_s, external_s = summary:match("^(%d+)|([^|]*)|([^|]*)")
    local charge = tonumber(charge_s)
    if charge then
      label = charge .. "%"
    end

    local charging = charging_s == "Yes" or external_s == "Yes"

    if charging then
      icon = icons.battery.charging
    else
      if charge and charge > 80 then
        icon = icons.battery._100
      elseif charge and charge > 60 then
        icon = icons.battery._75
      elseif charge and charge > 40 then
        icon = icons.battery._50
      elseif charge and charge > 20 then
        icon = icons.battery._25
        color = colors.orange
      else
        icon = icons.battery._0
        color = colors.red
      end
    end

    local lead = ""
    if charge and charge < 10 then
      lead = "0"
    end

    battery:set({
      icon = {
        string = icon,
        color = color
      },
      label = { string = lead .. label },
    })
  end)
end

battery:subscribe({"routine", "power_source_change", "system_woke"}, update_battery)
update_battery()

battery:subscribe("mouse.clicked", function(env)
  local drawing = battery:query().popup.drawing
  battery:set( { popup = { drawing = "toggle" } })

  if drawing == "off" then
    sbar.exec(PMSET_CMD, function(batt_info)
      batt_info = batt_info or ""
      local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
      local label = found and remaining .. "h" or "No estimate"
      remaining_time:set( { label = label })
    end)
  end
end)

sbar.add("bracket", "widgets.battery.bracket", { battery.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.battery.padding", {
  position = "right",
  width = settings.group_paddings
})
