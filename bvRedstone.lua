-- A transposer and redstone (machine control + activity detector covers) controller to ensure maximum efficiency for multiple parallel (wallshared) bacterial vats sharing a single output hatch.
-- Unlike the adjacent bv.lua program, this one can run on a microcontroller.
-- The existing controllers did not wait to enable the multis until the hatch was flushed after a recipe, resulting in a slight drop in efficiency for the 2nd and later recipes.
--
-- Setup: 
--  1. Install machine control covers on one side of each BV. They should be set to "Enable with Redstone" and "Safe Mode". Be sure to set strong output mode on the conduit if going thru a block.
--  2. Install activity detector covers on another side of each BV. Set them to "Machine Idle" and "Inverted". Set them to strong output with a soldering iron.
--  3. Connect all covers with enderio covered conduits. I set the machine control covers to the lime color and the activity covers to orange. Optionally, connect colored lamps to each channel for monitoring.
--  4. Place an output hatch large enough for at least 4x full efficiency recipes worth of output in the center of the bac vats. 
--  5. Either flash a microcontroller with this code or run it on a computer. 
--      - I'd rec a microcontroller. Tested microcontroller specs:
--          -  RITEG Upgrade
--          - Transposer (2,621,440 L/s (ZPM))
--          - Transposer (2,621,440 L/s (ZPM))
--          - Redstone Card Tier 1
--          - CPU Tier 1
--          - Memory Tier 1.5
--          - EEPROM flashed with this program
--      - However, if using a computer, uncomment the requires() below (keep commented out for a microcontroller).
--  6. Place a transposer (or the microcontroller) below the hatch (or below a linked transvector interface). Use one fast enough to instantly transfer to save time.
--  7. Place a receiving tank or dual interface below the transposer.
--  8. Connect the redstone conduits to the microcontroller/computer sides configured below. Note the sides are "from the computer's point of view", and will be reversed when looking at the face of the computer. 
--  9. Power on the computer/microcontroller.
--  7. If all went well, the program should attempt to start the BVs, then disable them and wait for them to all complete their recipes and drain the hatch before reenabling them again. 
-- 
-- Based on https://gtnh.miraheze.org/wiki/Bacterial_Vat#Method_2:_OpenComputers

-- local component = require("component")
-- local computer = require("computer")

local redstone = component.proxy(component.list('redstone')())
local transposer = component.proxy(component.list('transposer')())

-- "Note also that the side is relative to the computer's orientation, i.e. sides.south is in front of the computer, 
-- not south in the world. Likewise, sides.left is to the left of the computer, so when you look at the computer's 
-- front, it'll be to your right."
-- down: 0, up: 1, back: 2, front: 3, right: 4, left: 5

-- Connected to Machine Controller Covers on all BVs. They should be set to "Enable with Redstone" and "Safe Mode". Be sure to set strong output mode on the conduit.
local redstoneOutputSide = 5 -- sides.left

-- Connected to Activity Detector Covers on all BVs. They should be set to "Machine Idle" and "Inverted". Set them to strong output with a soldering iron.
local redstoneInputSide = 4 --sides.right

-- Hatch Side
local fluidInputSide = 1 --sides.up

-- Dump tank/interface Side
local fluidOutputSide = 0 --sides.down

local max = transposer.getTankCapacity(fluidInputSide)
-- Minimum fluid amount that guarantees maximum output
local min = math.ceil((1-math.sqrt(0.001))*max/2)

while true do
    -- print("Disabling multis")
    redstone.setOutput(redstoneOutputSide, 0)

    -- print("Waiting for multis to finish")
    local areAnyVatsActive = true
    while areAnyVatsActive do
        computer.pullSignal(0.05)

        -- print("Redstone input: "..redstone.getInput(redstoneInputSide))
        areAnyVatsActive = redstone.getInput(redstoneInputSide) ~= 0
    end

    -- print("Emptying Hatch")
    local level = transposer.getTankLevel(fluidInputSide)
    if level > min then
        transposer.transferFluid(fluidInputSide, fluidOutputSide, level-min)
    end

    -- print("Enabling multis")
    redstone.setOutput(redstoneOutputSide, 15)

    -- print("Waiting for multis to start")
    computer.pullSignal(0.5)
end