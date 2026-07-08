-- Basic library for discord notifications.
-- Very stupid, you need to manually supply the webhook URL in the code below

local internet = require("internet")

local shell = require("shell")
local success, inspect = pcall(function() return require('inspect') end)
if not success then
    print("Downloading inspect library...")
    shell.execute("wget -f https://raw.githubusercontent.com/kikito/inspect.lua/master/inspect.lua")
    inspect = require("inspect")
end

local function notify(username, content)
    -- Webhook URL
    -- #testing, grab from      https://discord.com/channels/1225855237286531082/1225858797952696451/1225858849190183022
    -- #cropbot, grab from      https://discord.com/channels/1225855237286531082/1227474507414114325/1227474603249766452
    -- #core-base, grab from    https://discord.com/channels/1225855237286531082/1225857486544699512/1225858058735980606
    local url = ""

    local body = {
        ["content"] = content,
        ["username"] = username,
        -- ["avatar_url"] = "https://cdn.discordapp.com/emojis/1033221271623839795.webp?size=96&quality=lossless", -- crazy greg face
        -- ["avatar_url"] = "https://ocdoc.cil.li/_media/blocks:robot.png", -- OC robot
        ["avatar_url"] = "https://i.imgur.com/H2Hkn8X.png", -- LSC item icon
    }

    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Source"] = "Minecraft/OpenComputers/CustomScript",
    }

    local success, handle = pcall(function() return internet.request(url, body, headers, "POST") end)
    if not success then
        print("the request itself failed?")
        error(handle)
    end

    local result_body = ""
    for chunk in handle do result_body = result_body..chunk end
    -- print(result_body)

    -- print(inspect(handle))

    -- Grab the metatable for the handle. This contains the internal HTTPRequest object.
    -- Must process the handle before the metatable is populated
    local mt = getmetatable(handle)
    -- The response method grabs the information for
    -- the HTTP response code, the response message, and the
    -- response headers.
    local code, message, headers = mt.__index.response()

    return code
end

local function safe_notify(username, content)
    local success, code = pcall(function() return notify(username, content) end)
    if success then
        return code
    else
        print("WARNING: failed to send notification")
        print(code)
        return -1
    end
end

return {
    ["notify"] = notify,
    ["safe_notify"] = safe_notify,
}