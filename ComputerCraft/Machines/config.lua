-- lib/config.lua
-- This creates a table known as Config and defines the functions

local Config = {}

function Config.loadSecrets()
    local path = "config/secret.env"

    if not fs.exists(path) then
        error("Config file not found: " .. path)
    end

    local file = fs.open(path, "r")
    local content = file.readAll()
    file.close()

    return textutils.unserialiseJSON(content)
end

function Config.getApiUrl()
    local secrets = Config.loadSecrets()
    return secrets.url
end

function Config.getSecret()
    local secrets = Config.loadSecrets()
    return secrets.casinoSecret
end

return Config