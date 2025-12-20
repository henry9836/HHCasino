-- Simple coin flipper game we can keep at 50/50 as it only needs to fail once to lose all value
-- To keep profit start a low increase that we don't care too much about like 5 or 10% 
-- then increase expectionally by 10 flips no one should be winning, by 2 flips there's a 75% chance of 
-- house win: https://www.omnicalculator.com/statistics/coin-flip-probability

-- Max bet of 1k
-- 1.9x at the start gives house 5% advantage on first bets
-- each failed streak adds 0.5x to the the multipler
-- when the multipler reaches 2.25x cheat chances into favour 55% of coin flips are now casino winning
-- For each win it multiplies the bet with the current round ((C * 1.45) + 1.9 + losing streak))
-- at 30x drop the odds to 25%

-- Load Libs
local api = require("lib.api")
local config = require("lib.config")

-- Load Config Data
local configUrl = config.getApiUrl();
local configSecret = config.getSecret();

local activeUserId = ""
local activeUserName = ""

-- Computer Monitor
local monitor = peripheral.find("monitor")
monitor.clear()
monitor.setTextScale(2)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.red)
monitor.write("Devil's Toss is starting, please wait...")

-- Game values
local startingMultipler = 1.9
local workingMultipler = startingMultipler

local losingStreakIterator = 0.5
local winningStreakMultipler = 1.45
local currentLosingStreak = 0
local currentLosingStreakModifier = 0.0
local currentWiningStreakModifier = 0.0

local pot = 0
local currentRound = 0
local betPlaced = 0
local maxBetValue = 1000

local oddsToWin = 50
local originalOddsToWin = 50

local userCurrency = 0
local totalBetted = 0
local totalLost = 0
local totalWin = 0

function clearScreen()
    term.clear()
    monitor.clear()

    term.setCursorPos(1, 1)
    monitor.setCursorPos(1, 1)
end

function waitForInteraction()
    clearScreen()

    monitor.setTextScale(3)
    monitor.write("Devil's Toss")
    monitor.setTextScale(1)
    monitor.setCursorPos(1, 2)
    monitor.write("Your next flip could double it all")
    monitor.setTextScale(2)
end

function resetGameState()
    activeUserId = ""
    activeUserName = ""

    startingMultipler = 1.9
    workingMultipler = startingMultipler

    losingStreakIterator = 0.5
    winningStreakMultipler = 1.45
    currentLosingStreak = 0
    currentLosingStreakModifier = 0.0
    currentWiningStreakModifier = 0.0

    pot = 0
    currentRound = 0
    betPlaced = 0
    maxBetValue = 1000

    oddsToWin = 50
    originalOddsToWin = 50

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

function getMultipler()
    return ((currentRound * winningStreakMultipler) + startingMultipler + currentLosingStreakModifier)
end

function presentGameState()

    print("[ Devil's Toss ]")
    print("Your next flip could double it all " .. activeUserName)
    print("Cerberus Coin Balance: " .. userCurrency)

    if currentLosingStreakModifier > 0 then
        print("Losing Streak Comeback Multipler: " .. getMultipler() .. "x")
    else
        print("Multiplier: " .. getMultipler() .. "x")
    end

    if betPlaced == 0 then
        monitor.write("Player placing bet...")
        monitor.write("Current Multipler: " .. getMultipler() .. "x")

        print("")
        print("Type exit to Leave")
        write("Place your bet: $")
    else
        print("")
    end
end

function logState()
    local gameState = {
        currentPot = pot,
        userWallet = userCurrency,
        lastBetPlaced = betPlaced,
        currentMulitper = workingMultipler,
        losingStreak = currentLosingStreak,
        losingStreakMod = currentLosingStreakModifier,
        oddsToWin = oddsToWin,
        round = currentRound,
        totalBets = totalBetted,
        totalLost = totalLost,
        totalWon = totalWin
    }

    api.logAction(configUrl, "game", "Flipper", activeUserId, activeUserName, gameState)
end

function flipCoin()
    local roll = math.random(101)

    if roll <= oddsToWin then
        print("win")
    else
        print("lose")
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

        -- Leaving
        if input == "exit" or input == "9" then
            logState()
            print("Returning card...")
            disk.eject("left")
            break
        end

        -- We are playing
        flipCoin()

        logState()

        sleep(1)
    end
end

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
