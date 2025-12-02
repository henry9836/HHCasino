-- Load Libs
local api = require("lib.api")
local crypto = require("lib.crypto")
local config = require("lib.config")
local bridge = require("lib.meBridger")

-- Load Config Data
local configUrl = config.getApiUrl();
local configSecret = config.getSecret();

local activeUserId = ""
local activeUserName = ""

local previousMeState = {}

activeColors = 0
bundledOutputSide = "back"
lastInteractionTime = 0
timeoutDelay = 10

function UpdateMeState()
    previousMeState = {}
    for _, item in pairs(bridge.dumpAllItems()) do
	    table.insert(previousMeState, {name = item.name, amount = item.amount})
    end
end

function ToggleDoors(bShouldClose)
   if (bShouldClose == true) then
       activeColors = bit.bor(activeColors, colors.pink)
   else
       activeColors = bit.band(activeColors, bit.bnot(colors.pink))
   end
   redstone.setBundledOutput(bundledOutputSide, activeColors) 
end

function GetNewCard()
   clearScreen()
   print("Requesting new card please wait...")
   activeColors = bit.bor(activeColors, colors.white)
   redstone.setBundledOutput(bundledOutputSide, activeColors)
   print("Please pickup your new card from the withdrawal chest and insert into the disk drive")
   print("Press any key to continue")
   os.pullEvent("key")
   activeColors = bit.band(activeColors, bit.bnot(colors.white))
   redstone.setBundledOutput(bundledOutputSide, activeColors)
end

function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

function isCardInserted()
    return disk.isPresent("left")
end

function showMenu()
    clearScreen()
    print("=== Hade's Infernal Reserve Casino ATM ===")
    if isCardInserted() then
        -- Quickly load in the info if we have not yet
        if (activeUserId == "") then
            -- Update to what card data is
            local diskFile = fs.open("disk/hadesuser", "r")
            activeUserId = diskFile.readAll()
            diskFile.close()

            if (activeUserId == "") then
                print("Error 8")
                sleep(3)
                return false
            end

           local data =  api.getUserInfo(configUrl, activeUserId)
           if data.error then
                print("Error 9")
                sleep(3)
                return false
            end

            activeUserName = data.Name
        end

        print("User: " .. activeUserName .. " | Acc: " .. activeUserId)
        print("1. Check Balance")
        print("2. Deposit Items")
        print("9. Exit")
    else
        print("1. Get new card")
        print("2. Use current card")
        print("9. Exit")
    end
    
    print("")
    print("Choose an option (1-9):")
end

function updateInteractionTime()
    lastInteractionTime = os.clock()
end

function checkTimeout()
    local currentTime = os.clock()
    if currentTime - lastInteractionTime > timeoutDelay then
        -- Open doors after timeout
        ToggleDoors(true)
        print("Timeout reached - doors opened")
        sleep(2)
        return true
    end
    return false
end

function waitForInteraction()
    clearScreen()
    print("=== Hade's Infernal Reserve Casino ATM ===")
    print("")
    print("Insert Hade's Infernal Reserve Bank Card on the left if you are an existing customer")
    print("")
    print("Press any key to begin!")
    
    -- Wait for any key press
    os.pullEvent("key")
    updateInteractionTime()
end

function UpdateAPIVaultState()
    print("Please wait... Syncing...")
    local items = {}
    for _, item in pairs(bridge.dumpAllItems()) do
	    table.insert(items, {name = item.name, amount = item.amount})
    end

    api.sendVaultStateUpdate(items, configUrl)
    print("Done.")
    sleep(1)
end

function RegisterNewUser()
    while true do -- Check for card and wait till user puts it in
        if isCardInserted() then
            break
        end
        clearScreen()
        print("=== Hade's Infernal Reserve Casino ATM ===")
        print("Error: no card inserted")
        print("")
        print("Insert card and then press any key to continue")
        os.pullEvent("key")
    end
    clearScreen()
    print("=== Hade's Infernal Reserve Casino ATM ===")
    print("New User Card Registration")


    local inputName = ""
    while inputName == "" do
        write("Enter Desired Name: ")
        inputName = read()
    end

    clearScreen()
    print("=== Hade's Infernal Reserve Casino ATM ===")
    print("New User Card Registration")
    write("Registering new user, please wait...");

    -- Register with API
    local userId = api.register(configUrl, inputName);
    if userId == "" then
        print("Error 5")
        sleep(3)
        clearScreen()
        return
    end

    -- Write UserId to disk
    local diskFile = fs.open("disk/hadesuser", "w")
    diskFile.write(tostring(userId))
    diskFile.close()

    -- Update the local vars
    activeUserName = inputName
    activeUserId = userId

    clearScreen()
    print("=== Hade's Infernal Reserve Casino ATM ===")
    print("")
    write("Welcome to Hade's Infernal Reserve " .. activeUserName);
    sleep(1)
    print("Press any key to continue...")
    os.pullEvent("key")
end

function calculateDifferences()
    local prevMap = {}
    local diffTable = {}
    local currentMeState = {}

    for _, item in pairs(bridge.dumpAllItems()) do
        table.insert(currentMeState, {name = item.name, amount = item.amount})
    end

    -- Convert previousMeState into a map for fast lookup
    for _, item in pairs(previousMeState) do
        prevMap[item.name] = item.amount
    end

    -- Process currentMeState
    for _, item in pairs(currentMeState) do
        local prevAmount = prevMap[item.name] or 0
        local diff = item.amount - prevAmount
        if diff ~= 0 then
            table.insert(diffTable, { name = item.name, difference = diff })
        end

        -- Remove from prevMap to track items that disappeared completely
        prevMap[item.name] = nil
    end

    -- Handle items that existed before but are now gone (withdrawn completely)
    for name, prevAmount in pairs(prevMap) do
        table.insert(diffTable, { name = name, difference = -prevAmount })
    end

    return diffTable
end


function handleMenuChoice(choice)
    updateInteractionTime()

    if isCardInserted() then -- Has Card

        -- Quickly load in the info if we have not yet
        if (activeUserId == "") then
            -- Update to what card data is
            local diskFile = fs.open("disk/hadesuser", "r")
            activeUserId = diskFile.read()
            diskFile.close()

            if (activeUserId == "") then
                print("Error 6")
                sleep(3)
                return false
            end

           local data =  api.getUserInfo(configUrl, activeUserId)
           if data.error then
                print("Error 7")
                sleep(3)
                return false
            end

            activeUserName = data.Name
        end

        if choice == "1" then
            clearScreen()

            local data = api.getUserInfo(configUrl, activeUserId)
            if data.error then
                print("Error 8")
                sleep(3)
                return false
            end
            print("=== Hade's Infernal Reserve Casino ATM ===")
            print("User: " .. activeUserName .. " | Acc: " .. activeUserId)
            write("Cerberus Coins: " .. data.Currency)
            print("")
            print("Press any key to return")
            os.pullEvent("key")
            return true
        elseif choice == "2" then
            UpdateMeState()
            clearScreen()
            write("Place all items you wish to deposit into the chest on the right\n")
            write("Once the chest is empty, press enter to continue.\n")
            print("")
            write("!!! ====== WARNING ====== !!!\n")
            write("DO NOT press enter until the chest is EMPTY.\n")
            write("If you press enter before the chest is empty, items may NOT be deposited into your account!\n")
            write("Once you have placed everything and the chest is empty, press enter to continue safely.\n")
            write("!!! ====== WARNING ====== !!!\n")
            print("")
            print("Press enter to continue when chest is empty")
            read()
            sleep(1)

            clearScreen()
            print("Logging Difference:")
            -- Calc new item counts
            local diff = calculateDifferences()
            for _, item in pairs(diff) do
                print(item.name, item.difference)
            end

            -- Log on backend
            UpdateAPIVaultState()

            print("Press enter to continue")
            read()
            return true
        elseif choice == "9" then
            clearScreen()
            print("Returning card...")
            disk.eject("left")
            sleep(1)
            print("Hade's Infernal Reserve thanks you for using this ATM")
            ToggleDoors(false) -- Open doors when exiting
            sleep(1)
            return false
        end
    else -- No card
        if choice == "1" then
            GetNewCard()
            RegisterNewUser()
            return true
        elseif choice == "2" then
            clearScreen()
            print("Insert card on the left and then press any key to continue...")
            os.pullEvent("key")
            return true
        elseif choice == "9" then
            print("Exiting...")
            ToggleDoors(false) -- Open doors when exiting
            sleep(1)
            return false
        else
            clearScreen()
            print("Invalid option! Please choose 1-4")
            sleep(1)
        end
    end
    
    return true
end

-- Main program loop
function main()
    while true do
        -- Reset values
        activeUserId = ""
        activeUserName = ""
        UpdateMeState()

        -- Initially open doors
        ToggleDoors(false)

        -- Wait for user interaction
        waitForInteraction()

        -- Close the doors
        ToggleDoors(true)
        
        -- User is now active, show menu
        local keepRunning = true
        
        while keepRunning do
            showMenu()
            
            -- Wait for input with timeout checking
            local startTime = os.clock()
            local input = nil
            
            -- Create a timeout loop for input
            while true do
                local timer = os.startTimer(0.1) -- Check every 0.1 seconds
                local event, param = os.pullEvent()
                
                if event == "char" then
                    input = param
                    break
                elseif event == "timer" and param == timer then
                    if checkTimeout() then
                        keepRunning = false
                        break
                    end
                end
            end
            
            if input and keepRunning then
                keepRunning = handleMenuChoice(input)
            end
        end
        
        -- Brief pause before going back to waiting state
        sleep(1)
    end
end

-- Start the program
main()
