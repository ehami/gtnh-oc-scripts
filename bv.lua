-- A transposer and adapter/machine proxy based controller to ensure maximum efficiency for multiple parallel (wallshared) bacterial vats sharing a single output hatch.
-- The existing controllers did not wait to enable the multis until the hatch was flushed after a recipe, resulting in a slight drop in efficiency for the 2nd and later recipes.
--
-- Setup: 
--  1. Place adapters under each controller. 
--  2. Place an output hatch large enough for at least 4x full efficiency recipes worth of output in the center of the bac vats. 
--  3. Place a transposer below the hatch (or below a linked transvector interface). Use one fast enough to instantly transfer to save time.
--  4. Place a receiving tank or dual interface below the transposer.
--  5. Connect everything with cables.
--  6. Install Open OS, then install and copy this program over, naming it main.lua to enable autostart. Reboot the computer.
--  7. If all went well, the program should attempt to start the BVs, then disable them and wait for them to all complete their recipes and drain the hatch before reenabling them again. 
--
-- Based on https://gtnh.miraheze.org/wiki/Bacterial_Vat#Method_2:_OpenComputers
-- and https://github.com/Navatusein/GTNH-OC-Water-Line-Control/blob/main/lib/component-discover-lib.lua

local component = require("component")
local computer = require("computer")

local transposer = component.proxy(component.list('transposer')())
local max = transposer.getTankCapacity(1)

-- Minimum fluid amount that guarantees maximum output
local min = math.ceil((1-math.sqrt(0.001))*max/2)

print("Discovering All Biovats")

local biovats = {}
local i = 1;
for key, value in pairs(component.list()) do
    if value == "gt_machine" then
        local machineProxy = component.proxy(key, "gt_machine")
        if machineProxy.getName() == "bw.biovat" then
            biovats[i] = machineProxy
            i = i + 1
        end
    end
end

print("Found "..#biovats.." biovats. Target is "..min.."/"..max..". Ctrl + Alt + C to quit.")

while true do
    print("Disabling all multis")
    for _, bv in ipairs(biovats) do
        bv.setWorkAllowed(false)
    end

    print("Waiting for all multis to finish")
    local areAnyVatsActive = true
    while areAnyVatsActive do
        computer.pullSignal(0.05)

        areAnyVatsActive = false
        for _, bv in ipairs(biovats) do
            areAnyVatsActive = areAnyVatsActive or bv.isMachineActive()
        end
    end

    print("Emptying Hatch")
    local level = transposer.getTankLevel(1)
    if level > min then
        transposer.transferFluid(1, 0, level-min)
    end

    print("Enabling all multis")
    for _, bv in ipairs(biovats) do
        bv.setWorkAllowed(true)
    end
    
    print("Waiting for multis to start")
    computer.pullSignal(0.5)
end