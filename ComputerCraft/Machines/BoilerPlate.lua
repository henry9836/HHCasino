-- Load secrets
local secretsFile = fs.open("config/secret.env", "r")
local secretContent = secretsFile.readAll()
secretsFile.close()

local secrets = textutils.unserialiseJSON(secretContent)

local URL = secrets.url
local SECRET = secrets.casinoSecret

-- Define the HideMessage function in Lua
function HideMessage(amountRequested, userId)
    -- Concatenate EnvSecret with amountRequested
    local secret = SECRET .. tostring(amountRequested)

    -- Step 1: XOR Encryption
    local encryptedSecret = ""
    local userIdStr = tostring(userId)
    local userIdLen = #userIdStr
    local count = 1 -- Lua is 1-based index

    print(secret)
    for i = 1, #secret do
        local element = string.byte(secret, i)
        local keyElement = string.byte(userIdStr, count)
        local xorResult = bit.bxor(element, keyElement)
        encryptedSecret = encryptedSecret .. string.char(xorResult)

        count = count + 1
        if count > userIdLen then
            count = 1
        end
    end
    print(encryptedSecret)

    -- Step 2: Junk data generation
    local resultString = ""
    local junkUserIndex = math.random(1, userIdLen)
    local junkKey = tonumber(string.sub(userIdStr, junkUserIndex, junkUserIndex))
    if junkKey < 3 then junkKey = 3 end
    if junkKey > 9 then junkKey = 9 end

    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    local encryptedIndex = 1

    local junkIndex = 1
    while encryptedIndex <= #encryptedSecret do
        if (junkIndex - 1) % junkKey == 0 then
            resultString = resultString .. string.sub(encryptedSecret, encryptedIndex, encryptedIndex)
            encryptedIndex = encryptedIndex + 1
        else
            local randomCharIndex = math.random(1, #chars)
            local randomChar = string.sub(chars, randomCharIndex, randomCharIndex)
            resultString = resultString .. randomChar
        end
        junkIndex = junkIndex + 1
    end

    resultString = "$" .. tostring(junkUserIndex - 1) .. ":" .. resultString
    print(resultString)
    return resultString
end

local userId = 1750222654637 -- Replace with actual userId
local amount = 100 -- Replace with actual amount
local message = HideMessage(amount, userId)

local requestData = {
    userId = userId,
    amount = amount,
    secret = message
}

local jsonText = textutils.serializeJSON(requestData)
local headers = {
    ["Content-Type"] = "application/json"
}

print("Attempting to create new user")
local response = http.get(URL.."/register")
if response then
    local status = response.getResponseCode()
    local body = response.readAll()
    print("Status:", status)
    print("Response:", body)
    response.close()
else
    print("Request failed.")
end

print("Attempting to add cash money")
response = http.post(URL.."/update", jsonText, headers)
if response then
    local status = response.getResponseCode()
    local body = response.readAll()
    print("Status:", status)
    print("Response:", body)
    response.close()
else
    print("Request failed.")
end

print("Checking our balance")
response = http.get(URL.."/get-currency/"..userId)
if response then
    local status = response.getResponseCode()
    local body = response.readAll()
    print("Status:", status)
    print("Response:", body)
    response.close()
else
    print("Request failed.")
end

print("end")
