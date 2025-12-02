-- Load Libs
local api = require("lib.api")
local crypto = require("lib.crypto")
local config = require("lib.config")

-- Load Config Data
local configUrl = config.getApiUrl();
local configSecret = config.getSecret();

-- Test things out for now
local name = "NitroIsAMadMan"
local userId = api.register(configUrl, name);

if userId == "" then
    print("NO USER ID FOUND!!!")
    return
end
`
local data = api.getUserInfo(configUrl, userId)
if data.error then
    print("DATA INVALID!")
    return
end
print(data)

local message = crypto.hideMessage(250, userId, configSecret)
if api.updateMoney(configUrl, userId, 250, message) then
    print("Successfull ran the test :3")
else
    print("I HAVE FAILED ><")
end

print("FINAL")
local data = api.getUserInfo(configUrl, userId)
if data.error then
    print("DATA INVALID!")
    return
end
print(data)
