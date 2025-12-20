-- lib/api.lua
-- This creates a table known as API and defines the functions and talks to our api endpoint

local Api = {}

Api.vaultChunkSize = 100

Api.headers = {
    ["Content-Type"] = "application/json"
}

function Api.register(url, inName)
    print("Attempting to create new user...")
    local NewUserId = ""
    local regData = {
        name = inName
    }
    local jsonReqText = textutils.serializeJSON(regData)
    
    local response = http.post(url.."/register", jsonReqText, Api.headers)
    if response then
        local status = response.getResponseCode()
        local body = response.readAll()
        --print("Status:", status)
        --print("Response:", body)

        local data = textutils.unserializeJSON(body)

        response.close()

        if data.userId then
            NewUserId = data.userId
            return NewUserId;
        else
            print("NO DATA")
        end
    else
        print("Request failed.")
    end

    return "USER NOT FOUND"
end

function Api.updateMoney(url, inUserId, inAmount, message)
    --print("Attempting to add cash money...")
    local requestData = {
        userId = inUserId,
        amount = inAmount,
        secret = message
    }
    local jsonText = textutils.serializeJSON(requestData)

    response = http.post(url.."/update", jsonText, Api.headers)
    if response then
        local status = response.getResponseCode()
        local body = response.readAll()
        --print("Status:", status)
        --print("Response:", body)
        response.close()

        return true
    else
        print("Request failed.")
    end

    return false
end

function Api.getUserInfo(url, userId)
    response = http.get(url.."/user/"..userId)
    if response then
        local status = response.getResponseCode()
        local body = response.readAll()
        --print("Status:", status)
        --print("Response:", body)
        local data = textutils.unserializeJSON(body)
        response.close()

        if data then
            return data
        else
            print("NO DATA")
        end
    else
        print("Request failed.")
    end
    return ""
end

function Api.sendVaultStateUpdate(items, url)
    local chunk = {}
    print("")
    for i, item in ipairs(items) do
        table.insert(chunk, item)
        
        -- Is our chunk big enough or out of items
        if #chunk >= Api.vaultChunkSize or i == #items then
            local payload = textutils.serializeJSON({items = chunk})
            local response = http.post(url.."/vault", payload, Api.headers)
            
            if response then
                write(".")
                response.close()
            else
                write("!")
            end

            chunk = {}
        end
    end
end

function Api.searchMusicFile(filename, url)
    local response = http.get(url.."/search/"..filename)
    if not response then
        print("Failed to contact cdn")
        return nil
    end

    local status = response.getResponseCode()
    local body = response.readAll()
    response.close()

    if status ~= 200 then
        print("Failed to find file " .. filename)
        return nil
    end

    -- data api
    -- {
    --   "path" = "music/32000/hills.dfpwm",
    --   "sample-rate" = "32000"
    -- }

    local data = textutils.unserializeJSON(body)
    if not data then
        print("Failed to parse file data")
        return nil
    end
    return data
end

function Api.logAction(url, actionType, machine, userId, userName, actionValue)
    if not url or not actionType or not machine or not userId or not userName or type(actionValue) ~= "table" then
        print("Api.logAction: Missing or invalid parameters")
        return false
    end

    -- Build the payload table
    local payload = {
        actionType = actionType,
        machine = machine,
        userId = userId,
        username = userName,
        value = actionValue
    }

    -- Serialize payload to JSON
    local payloadJson = textutils.serializeJSON(payload)

    -- Send POST request
    local response = http.post(url.."/logaction", payloadJson, {
        ["Content-Type"] = "application/json"
    })

    if not response then
        print("Api.logAction: Failed to contact server")
        return false
    end

    local status = response.getResponseCode()
    local body = response.readAll()
    response.close()

    if status ~= 200 then
        print("Api.logAction: Server returned status " .. status .. ", body: " .. body)
        return false
    end

    return true
end


return Api
