-- Created for troubleshooting IC2 Crop breeding
-- Intended to be run from an OC tablet with a Geoolyzer, Keyboard, and Chatbox
-- It logs information about the block at the player's foot position
-- and prints it to the chat when changed from the previous value.

local component = require("component")
local sides = require("sides")
local computer = require('computer')
local shell = require('shell')

local geolyzer = component.geolyzer
local chat = component.chat

local success, inspect = pcall(function() return require('inspect') end)
if not success then
    print("Downloading inspect library...")
    shell.execute("wget -f https://raw.githubusercontent.com/kikito/inspect.lua/master/inspect.lua")
    inspect = require("inspect")
end

chat.setName("Inspector Tablet")
chat.setDistance(3)

computer.beep(1000, 0.125)

local block = {}

while true do
    os.sleep(0.5)

    local time = "T" .. math.floor(os.time()) .. " "
    local rawResult = geolyzer.analyze(sides.down)

    print(time .. "Result: " .. rawResult.name)

    if inspect(block) == inspect(rawResult) then
        computer.beep(200, 0.1)
    else
        block = rawResult
        computer.beep(1000, 0.125)
        chat.say(inspect(block))
        chat.say("===============================================")
    end
end
