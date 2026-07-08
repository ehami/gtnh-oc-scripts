-- A barebones Lapotronic Supercapacitor monitoring script with Discord notifications.
-- It stops working due to large number handling when the max/stored EU is too large.
-- No wireless EU handling

local notifier = require('notifier')
local component = require('component')

local lsc = component.gt_machine

local NAME = 'George the Lapotronic Supercapacitor'

notifier.safe_notify(NAME, 'Power monitor program starting up')

-- what % as decimal to warn below
local threshold = 0.15

-- set to 1 to cause fake power shortage
local DEBUG_MODE = 0

-- how long to wait between checking power levels
local SLEEP_TIME_SECONDS = 10

local in_alarm = false
local alarm_started_at = 0

local debug_counter = 0

while true do
  print("time step: " .. os.time())
  debug_counter = debug_counter + DEBUG_MODE

  local stored = lsc.getEUStored()
  local max = lsc.getEUCapacity()

  -- unsure if this will still work at super large #s
  local current = stored / max
  local currentPercent = current * 100

  -- weird conversion factor because https://ocdoc.cil.li/api:non-standard-lua-libs#operating_system_facilities
  local time_since_alarm_started = (os.time() - alarm_started_at) * 1000 / 60 / 60 / 20

  -- for debugging (causes a fake power shortage event then fixes itself later)
  if debug_counter > 20 then
    threshold = 0.1
  elseif debug_counter > 5 then
    threshold = 1.1 -- impossible to satisfy
  end

  if stored < threshold * max then
    if in_alarm then
      print("    still in alarm! since " .. time_since_alarm_started .. " power% is " .. currentPercent .. "%")
    else
      print("!!! alarm started")
      in_alarm = true
      alarm_started_at = os.time()
      notifier.safe_notify(NAME, 'Power has reached unsafe levels (<' .. (threshold*100) .. '%)! EU Stored: ' .. lsc.getStoredEUString() .. ' of max ' .. lsc.getEUCapacityString())
    end    
  else
    if in_alarm then
      in_alarm = false
      print("power returned to normal levels")
      notifier.safe_notify(NAME, 'Power returned to normal levels after ' .. time_since_alarm_started .. ' IRL seconds')
      time_since_alarm_started = 0
    else
      print("    normal operation: " .. currentPercent .. "%")
    end
  end

  os.sleep(SLEEP_TIME_SECONDS)
end