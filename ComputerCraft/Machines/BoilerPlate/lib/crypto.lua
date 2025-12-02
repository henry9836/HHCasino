-- lib/crypto.lua
-- This creates a table known as Crypto and defines the functions

local Crypto = {}

function Crypto.hideMessage(amountRequested, userId, key)
    -- Concatenate EnvSecret with amountRequested
    local secret = key .. tostring(amountRequested)

    -- Step 1: XOR Encryption
    local encryptedSecret = ""
    local userIdStr = tostring(userId)
    local userIdLen = #userIdStr
    local count = 1 -- Lua is 1-based index

   -- print(secret)
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
    --print(encryptedSecret)

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

    -- Step 3: Wrap it all up
    resultString = "$" .. tostring(junkUserIndex - 1) .. ":" .. resultString
    --print(resultString)
    return resultString
end

return Crypto