local api = require("lib.api")
local config = require("lib.config")
local crypto = require("lib.crypto")
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

-- Save the original pullEvent function
local originalPullEvent = os.pullEvent

-- Disable Ctrl + T termination
os.pullEvent = os.pullEventRaw

-- Load Config Data
local configUrl = config.getApiUrl();
local configSecret = config.getSecret();

local sampleRate = 48000
local maxBetValue = 10000
local activeUserId = ""
local activeUserName = ""
local userCurrency = 0
local betPlaced = 0
local totalBetted = 0
local totalLost = 0
local totalWon = 0
local totalJackpot = 0
local totalInOrder = 0
local totalTriple = 0
local totalDoubles = 0

-- Ripped out of bandit cubed :3
local pos1pos = 0
local pos2pos = 0
local pos3pos = 0
local pos1 = "-"
local pos2 = "-"
local pos3 = "-"
local characterset = {"2", "3", "4", "5", "6", "7", "8", "9", "1", "J", "Q", "K", "D"}

function play(filename, originalRate)
    for chunk in io.lines(filename, 16 * 1024) do
        local buffer = decoder(chunk)

        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

function toggleLight(state)
    redstone.setOutput("top", state)
end

function flashlight(amount)
    for i = 1, amount do
        toggleLight(true)
        sleep(0.25)
        toggleLight(false)
        sleep(0.25)
    end
end

function clearScreen()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.yellow)

    term.clear()
    term.setCursorPos(1, 1)
end

function isCardInserted()
    return disk.isPresent("bottom")
end

function resetMachine()
    activeUserId = ""
    activeUserName = ""
    userCurrency = 0

    betPlaced = 0
    totalBetted = 0
    totalLost = 0
    totalWin = 0
    totalJackpot = 0
    totalInOrder = 0
    totalTriple = 0
    totalDoubles = 0
end

function refreshUserInfo()
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
    end

    local data =  api.getUserInfo(configUrl, activeUserId)
    if data.error then
        print("Error 9")
        sleep(3)
        return false
    end

    activeUserName = data.Name
    userCurrency = data.Currency

    return true
end

function presentGameState()
    print(" [ LUCKY DRAGON ] ~ rawr")
    print(" Welcome " .. activeUserName)
    print(" Balance: " .. userCurrency)
    print(" --------------------- ")
    print(" [ PAYOUTS ]")
    print(" [DDD] Triple Dragon 50x")
    print(" [123] Any In-Order 25x")
    print(" [QQQ] Triple Any 10x")
    print(" [DD5] Double Side by Side 2x")
    print(" --------------------- ")
    print("type exit to leave")
    write("Input bet $")
end

function drawsslot()
    print(" [ LUCKY DRAGON ] ~ rawr")
    print(" Good luck " .. activeUserName)
    print(" Balance: " .. userCurrency)
    print(" --------------------- ")
    write("-= [")
    write(pos1)
    write("] [")
    write(pos2)
    write("] [")
    write(pos3)
    write("] =-")
    print("")
end

function shuffle()
  for i = (math.random(7, 30)),1,-1
  do
    clearScreen()
    pos1pos = math.random(1, 13)
    pos2pos = math.random(1, 13)
    pos3pos = math.random(1, 13)
    pos1 = (characterset[pos1pos])
    pos2 = (characterset[pos2pos])
    pos3 = (characterset[pos3pos])
    drawsslot()
    sleep(0.1)
  end
end

function processWin(multipler)
    local amountToAdd = betPlaced * multipler
    totalWon = totalWon + amountToAdd

    -- Inform backend
    local message = crypto.hideMessage(amountToAdd, activeUserId, configSecret)
    api.updateMoney(configUrl, activeUserId, amountToAdd, message)
end

function processLoss()
    totalLost = totalLost + betPlaced
    local amountToLose = betPlaced * -1

    -- Inform backend
    local message = crypto.hideMessage(amountToLose, activeUserId, configSecret)
    api.updateMoney(configUrl, activeUserId, amountToLose, message)
end

function spin()
    totalBetted = totalBetted + betPlaced
    play("/music/slots.dfpwm")
    shuffle()
    clearScreen()
    drawsslot()
    if ((pos1 == pos2) or (pos2 == pos3)) then
        if ((pos1 == pos2) and (pos2 == pos3)) then
            if (pos1 == "D") then
                -- JACKPOT
                jackpotEffect()
                totalJackpot = totalJackpot + 1
                processWin(50)
                return
            else 
                -- Triple Any
                winEffect()
                totalTriple = totalTriple + 1
                processWin(10)
                return
            end 
        else
            -- 2x
            winEffect()
            totalDoubles = totalDoubles + 1
            processWin(2)
            return
        end
    else
        if((pos2 == characterset[pos1pos+1]) and (pos3 == characterset[pos2pos+1])) then
            if (pos1 == characterset[pos2pos-1]) then
                -- Any In Order
                winEffect()
                totalInOrder = totalInOrder + 1
                processWin(25)
                return
            end
        end
    end

    processLoss()
    loseEffect()
    sleep(0.5)
end

function flashSlotsRed(amount)
  for i = amount,1,-1
  do
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.black)
    clearScreen()
    print("")
    print("-=  BAD LUCK!  =-")
    sleep(0.25)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    clearScreen()
    drawsslot()
    sleep(0.25)
  end
  clearScreen()
end

function flashSlotsGreen(amount)
  for i = amount,1,-1
  do
    term.setBackgroundColor(colors.green)
    term.setTextColor(colors.black)
    clearScreen()
    print("")
    print("-=  YOU WIN!  =-")
    sleep(0.25)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    clearScreen()
    drawsslot()
    sleep(0.25)
  end
  clearScreen()
end


function jackpotEffect()
    play("music/jackpot.dfpwm")
    flashlight(6)
    flashSlotsGreen(6)
end

function winEffect()
    play("music/win.dfpwm")
    flashlight(2)
    flashSlotsGreen(2)
end

function loseEffect()
    play("music/lose.dfpwm")
    flashSlotsRed(2)
end

function logState()
    local gameState = {
        userWallet = userCurrency,
        lastBetPlaced = betPlaced,
        totalBets = totalBetted,
        totalLost = totalLost,
        totalWon = totalWon,
        totalJackpots = totalJackpot,
        totalInOrder = totalInOrder,
        totalTriple = totalTriple,
        totalDoubles = totalDoubles
    }

    api.logAction(configUrl, "game", "Lucky Dragon", activeUserId, activeUserName, gameState)
end

function gameLoop()
    while true do
        if not isCardInserted() then
            print("Card not inserted, exiting...")
            sleep(1)
            break
        end

        math.randomseed(os.epoch("utc"))

        if not refreshUserInfo() then
            break
        end

        clearScreen()
        presentGameState()

        local input = read()
        local inputNum = tonumber(input)

        if input == "exit" then
            logState()
            resetMachine()

            print("Returning card...")
            disk.eject("bottom")
            break
        elseif inputNum then
            betPlaced = math.floor(math.min(math.max(1, math.min(inputNum, maxBetValue)), userCurrency))
            if betPlaced > 0 then
               spin()
               logState()
            end
        end
        
        sleep(0.1)
    end
end

function waitForInteraction()
    print(" [ LUCKY DRAGON ]")
    print("Insert Hades Card then press enter to continue")
    inputName = read()

    if inputName == configSecret then
        os.pullEvent = originalPullEvent
    end
end

while true do
    clearScreen()
    waitForInteraction()
    resetMachine()

    gameLoop()

    sleep(0.1)
end
