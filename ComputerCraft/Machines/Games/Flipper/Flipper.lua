-- Simple coin flipper game we can keep at 50/50 as it only needs to fail once to lose all value
-- To keep profit start a low increase that we don't care too much about like 5 or 10% 
-- then increase expectionally by 10 flips no one should be winning, by 2 flips there's a 75% chance of 
-- house win: https://www.omnicalculator.com/statistics/coin-flip-probability

-- Max bet of 1k
-- 1.9x at the start gives house 5% advantage on first bets
    -- each failed streak adds 0.5x to the the multiplier
    -- when the multiplier reaches 2.25x cheat chances into favour 55% of coin flips are now casino winning
-- For each win it multiplies the bet with the current round ((C * 1.45) + 1.9 + losing streak))
-- at 30x drop the odds to 25%

-- Load Libs
local api = require("lib.api")
local config = require("lib.config")
local crypto = require("lib.crypto")
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

-- Load Config Data
local configUrl = config.getApiUrl();
local configSecret = config.getSecret();

local activeUserId = ""
local activeUserName = ""
local sampleRate = 48000

-- Computer Monitor
local monitor = peripheral.find("monitor")
monitor.clear()
monitor.setCursorPos(1, 1)
monitor.setTextScale(2)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.red)
monitor.write("Devil's Toss is starting, please wait...")

-- Game values
local startingMultiplier = 1.9
local workingMultiplier = 1.9

local losingStreakIterator = 0.35
local winningStreakMultiplier = 1.35
local currentLosingStreak = 0

local currentRound = 0
local betPlaced = 0
local maxBetValue = 5000

local oddsToWin = 45
local originalOddsToWin = 45

local userCurrency = 0
local totalBetted = 0
local totalLost = 0
local totalWin = 0

local function play(filename, originalRate)
    for chunk in io.lines(filename, 16 * 1024) do
        local buffer = decoder(chunk)

        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

function clearScreen()
    term.clear()
    monitor.clear()

    monitor.setTextScale(1)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.red)

    term.setCursorPos(1, 1)
    monitor.setCursorPos(1, 1)
end

function waitForInteraction()
    clearScreen()

    monitor.setTextScale(2)
    monitor.write("[ Devil's Toss ]")
    monitor.setCursorPos(1, 2)
    monitor.write("Your next flip could")
    monitor.setCursorPos(1, 3)
    monitor.write("double it all!")
end

function resetGameState()
    activeUserId = ""
    activeUserName = ""

    workingMultiplier = startingMultiplier

    currentLosingStreak = 0

    currentRound = 0
    betPlaced = 0

    oddsToWin = originalOddsToWin

    userCurrency = 0
    totalBetted = 0
    totalLost = 0
    totalWin = 0
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

function isCardInserted()
    return disk.isPresent("left")
end

function getLosingStreakMultiplier()
    return currentLosingStreak * losingStreakIterator
end

function getMultiplier()
    return ((currentRound * winningStreakMultiplier) + startingMultiplier + getLosingStreakMultiplier())
end

function presentGameState()
    print("[ Devil's Toss ]")
    print("Your next flip could double it all " .. activeUserName)
    print("Cerberus Coin Balance: " .. userCurrency)

    if getLosingStreakMultiplier() > 0 then
        print("Losing Streak Comeback Multiplier: " .. getMultiplier() .. "x")
    else
        print("Multiplier: " .. getMultiplier() .. "x")
    end

    if betPlaced == 0 then
        monitor.write(activeUserName)
        monitor.setCursorPos(1, 2)
        monitor.write("Placing bet...")
        monitor.setCursorPos(1, 3)
        monitor.write("Multiplier: " .. getMultiplier() .. "x")

        print("")
        print("Type exit to Leave")
        write("Place your bet: (max " .. maxBetValue ..")$")
    else
        monitor.write(activeUserName)
        monitor.setCursorPos(1, 2)
        monitor.write("Bet: $" .. betPlaced)
        monitor.setCursorPos(1, 3)
        monitor.write("Next flip: " .. getMultiplier() .. "x")

        print("Cash out value: " .. getWinAmount() .. " Cerberus Coins")
        print("Let it ride for " .. getMultiplier() .. "x?")
        write("[Y/n]? : ")
    end
end

function logState()
    local calcOdds = (oddsToWin .. " / " .. (100 + getRigging()))

    local gameState = {
        currentPotValue = getWinAmount(),
        userWallet = userCurrency,
        lastBetPlaced = betPlaced,
        currentMultipier = workingMultiplier,
        losingStreak = currentLosingStreak,
        losingStreakMod = getLosingStreakMultiplier(),
        oddsToWin = calcOdds,
        round = currentRound,
        totalBets = totalBetted,
        totalLost = totalLost,
        totalWon = totalWin
    }

    api.logAction(configUrl, "game", "Flipper", activeUserId, activeUserName, gameState)
end

function getWinAmount()
    return math.floor(betPlaced * getMultiplier())
end

function getNextMultiplier()
    return (((currentRound + 1) * winningStreakMultiplier) + startingMultiplier + getLosingStreakMultiplier())
end

function getRigging()
     -- Cheat the odds
    local offset = 1

    -- at 2.5x odds go down to 45%
    if getMultiplier() > 2.5 then
        offset = offset + 45
    end

    -- at 30x odds go to 30%
    if getMultiplier() > 30 then
        offset = offset + 30
    end
    
    return offset
end

function flipCoin()
    local roll = math.random(100 + getRigging())

    clearScreen()
    if (currentRound >= 1) then
        monitor.write("LETTING IT RIDE...")
    else
        monitor.write("FLIPPING COIN...")
    end
    monitor.setCursorPos(1, 2)
    monitor.write("Bet: $" .. betPlaced)
    monitor.setCursorPos(1, 3)
    monitor.write("Multiplier: " .. getMultiplier() .. "x")

    print("Flipping...")

    play("/music/flip.dfpwm", 48000)

    sleep(1)

    clearScreen()
    if roll <= oddsToWin then -- WON
        print("The Devil deals you a hot hand, You win!")

        if getMultiplier() > 10 then
            play("/music/bigwin.dfpwm", 48000)
        else
            play("/music/win.dfpwm", 48000)
        end

        currentRound = currentRound + 1
        flashMonitor(activeUserName, "Won: " .. getWinAmount() .. "!", "")

    else -- LOSE
        print("The Devil grins, the house wins")
        play("/music/lose.dfpwm", 48000)

        totalLost = totalLost + betPlaced
        totalBetted = totalBetted + betPlaced
        local winAmount = getWinAmount()

        -- Inform backend
        betPlaced = betPlaced * -1
        local message = crypto.hideMessage(betPlaced, activeUserId, configSecret)
        api.updateMoney(configUrl, activeUserId, betPlaced, message)

        currentLosingStreak = currentLosingStreak + 1
        currentRound = 0
        betPlaced = 0

        flashMonitor("The Devil grins", "The house wins:", betPlaced)
    end

    return false
end

function flashMonitor(line1, line2, line3)
    for i = 1, 3 do
        -- Black text on red background
        monitor.setBackgroundColor(colors.red)
        monitor.setTextColor(colors.black)
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write(line1)
        monitor.setCursorPos(1, 2)
        monitor.write(line2)
        monitor.setCursorPos(1, 3)
        monitor.write(line3)
        os.sleep(0.25)

        -- Red text on black background
        monitor.setBackgroundColor(colors.black)
        monitor.setTextColor(colors.red)
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write(line1)
        monitor.setCursorPos(1, 2)
        monitor.write(line2)
        monitor.setCursorPos(1, 3)
        monitor.write(line3)
        os.sleep(0.25)
    end
end

function gameLoop()
    while true do
        if not isCardInserted() then
            print("Card not inserted, exiting...")
            sleep(1)
            break
        end

        math.randomseed(os.epoch("utc"))

        refreshUserInfo()
        clearScreen()

        presentGameState()
        local input = read()
        local inputNum = tonumber(input)

        -- Leaving
        local successfullyProcessedInput = false
        if input == "exit" or input == "9" then
            logState()

            print("Returning card...")
            disk.eject("left")
            break
        -- Have we inputted a number and not have a bet placed yet, must be starting
        elseif inputNum and betPlaced == 0 then
            betPlaced = math.max(1, math.min(inputNum, maxBetValue))
            successfullyProcessedInput = true
        elseif betPlaced > 0 and input == "n" then
            -- Inform backend
            local message = crypto.hideMessage(getWinAmount(), activeUserId, configSecret)
            api.updateMoney(configUrl, activeUserId, getWinAmount(), message)

            -- Softer reset
            totalWin = totalWin + getWinAmount()
            totalBetted = totalBetted + betPlaced
            currentRound = 0
            currentLosingStreak = 0
            betPlaced = 0
            oddsToWin = originalOddsToWin
            userCurrency = 0
        elseif betPlaced > 0 then -- if we have a betting amount and we got here then we want to flip
            successfullyProcessedInput = true
        end

        -- We are playing
        if successfullyProcessedInput then
            flipCoin()
            logState()
        end

        sleep(1)
    end
end

sleep(1)

while true do
    -- Reset
    clearScreen()
    resetGameState()
    waitForInteraction()

    print("Insert Hades Card then press enter to continue")
    inputName = read()

    -- Check for disk start game if valid
    gameLoop()

    sleep(0.1)
end