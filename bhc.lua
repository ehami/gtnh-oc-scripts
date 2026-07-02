-- Black Hole Compressor Script
-- The primary change versus the wiki version is adding a conditionallyUseCollapser mode, which will conditionally 
-- insert a collapser if there are still pending crafts to run, but will otherwise wait to time out naturally.
-- It is also configured to store black hole seeds and collapsers in the super stocker rather than from main net (this isjust done by setting interfaceSide = stockerSide and obv not using an interface)
-- 
-- Based on https://wiki.gtnewhorizons.com/wiki/Pseudostable_Black_Hole_Containment_Field#Method_2:_OpenComputers
-- Original Credits: Fox
-- 
local component = require('component')
local sides = require('sides')
local bhc = component.gt_machine
local r = component.redstone
local t = component.transposer
local n = 0

-- CTRL+ALT+C to stop the script at any time.

-- ========= CONFIG =========

-- The Maximum Runtime (s) before closing. Include the base 100s.
local maxRuntime = 100

-- The Target Stability (%) for halting decay.
local targetStability = 10

-- Whether or not to use collapsers
local useCollapser = false

-- Whether or not to use a collapser when there are pending crafts (rather than waiting for it to close natuarally)
local conditionallyUseCollapser = true

-- Whether or not to consume extra spacetime to save the last recipe.
local voidProtection = true

  -- Side Options: [north, south, east, west, up, down]

-- Side of Redstone I/O with Wireless Receiver ie, (pending crafting item inputs)
local receiverSide = sides.up

-- Side of Redstone I/O with Wireless Transmitter
local transmitterSide = sides.south

-- Side of Redstone I/O with Black Hole Utility Hatch (Optional)
local hatchSide = sides.east

-- Side of Transposer with ME Interface
local interfaceSide = sides.north

-- Side of Transposer with Super Stock Replenisher
local stockerSide = sides.north

-- Side of Transposer with GT Input Bus
local busSide = sides.down

-- ====== END CONFIG ======

local function calcSpacetime(duration, amount)
  local total = 0
  for i=101, duration do
    total = total + 2^(math.floor((i-101)/30))
  end

  return {amount-total, total}
end

local function parse(number) -- Credits: Navatusein
  return tostring(math.floor(number)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
end

-- THE LOOP
while true do

  -- Reset Transmitter if Necessary
  r.setOutput(transmitterSide, 0)

  -- Subnet has Items and Manual Override is NOT set
  if r.getInput(receiverSide) > 0 then

    -- There is a seed available
    if t.getStackInSlot(interfaceSide, 1) ~= nil then

      -- There is a collapser available
      if t.getStackInSlot(interfaceSide, 2) ~= nil or not useCollapser then

        -- There is enough spacetime for the maxRuntime
        local maxSpacetime = t.getFluidInTank(stockerSide, 1).amount
        local minSpacetime = calcSpacetime(maxRuntime, maxSpacetime)
        if minSpacetime[1] >= 0 then

          -- All Checks Passed
          print(string.format('\nBHC: Target %ss with %sL Spacetime!', maxRuntime, parse(minSpacetime[2])))

          -- Open Black Hole
          print('BHC: Opening Black Hole!')
          t.transferItem(interfaceSide, busSide, 1, 1)
          while not bhc.hasWork() do os.sleep(0.1) end

          if maxRuntime > 100 then
            os.sleep(99 - targetStability)

            -- Enable Spacetime and Start Timer
            print(string.format('BHC: Injecting Spacetime at %s%% Stability!', targetStability))
            r.setOutput(transmitterSide, 15)
            os.sleep(maxRuntime - 100)

            -- Save Last Recipe
            if voidProtection then
              local timeNeeded = (bhc.getWorkMaxProgress() - bhc.getWorkProgress()) / 20
              os.sleep(math.max(timeNeeded - targetStability + 1, 0))
            end

            -- Disable Spacetime
            r.setOutput(transmitterSide, 0)

          else
            os.sleep(60)
            
            -- Try to Save Last Recipe (Not Guaranteed)
            local timeNeeded = math.max(1, bhc.getWorkMaxProgress() / 20)
            local timeRemaining = 40 - (bhc.getWorkMaxProgress() - bhc.getWorkProgress()) / 20
            os.sleep((math.floor(timeRemaining/timeNeeded) * timeNeeded) - 1)
          end

          -- Close Black Hole
          bhc.setWorkAllowed(false)
          if useCollapser then
            print('BHC: Closing Black Hole!')
            t.transferItem(interfaceSide, busSide, 1, 2)

          else
            print('BHC: Waiting for black hole to passively collapse...')
            local c = 0
            while r.getInput(hatchSide) > 0 do -- 15 Minutes Ideally
              print('.')
              
              if conditionallyUseCollapser and r.getInput(receiverSide) > 0 then
                  print('BHC: Using Collapser to close early due to pending work')
                  t.transferItem(interfaceSide, busSide, 1, 2)
                  break    
              end

              os.sleep(20)
              c = c+1
              if c > 47 then break end -- 16 Minutes
            end
          end

          -- Wait For Finish
          while bhc.hasWork() do os.sleep(0.1) end
          bhc.setWorkAllowed(true)
          n=0

        else
          print(string.format('BHC: Missing %sL Spacetime!', parse(-minSpacetime[1])))
        end

      else
        print('BHC: No Collapsers Available!')
      end

    else
      print('BHC: No Seeds Available!')
    end

  elseif n==0 then
      print('BHC: Sleeping...')
      n=1
  end
  os.sleep(3)
end