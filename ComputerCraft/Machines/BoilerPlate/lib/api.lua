-- lib/api.lua
-- This creates a table known as API and defines the functions and talks to our api endpoint

local Api = {}

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
        print("Status:", status)
        print("Response:", body)

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
    print("Attempting to add cash money...")
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
        print("Status:", status)
        print("Response:", body)
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
        print("Status:", status)
        print("Response:", body)
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

return Api