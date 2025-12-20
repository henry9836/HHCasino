-- Simple coin flipper game we can keep at 50/50 as it only needs to fail once to lose all value
-- To keep profit start a low increase that we don't care too much about like 5 or 10% 
-- then increase expectionally by 10 flips no one should be winning, by 2 flips there's a 75% chance of 
-- house win: https://www.omnicalculator.com/statistics/coin-flip-probability

-- Max bet of 1k
-- 1.9x at the start gives house 5% advantage on first bets
-- each failed streak adds 0.5x to the the multipler
-- when the multipler reaches 2.25x cheat chances into favour 55% of coin flips are now casino winning

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

-- Computer Monitor
local monitor = peripheral.find("monitor")
monitor.clear()
monitor.setTextScale(3)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.red)
monitor.write("Devil's Toss is starting, please wait...")

-- Game values
local startingMultipler = 1.9
local workingMultipler = startingMultipler
local losingStreakIterator = 0.5
local currentLosingStreak = 0.0
local betPlaced = 0
local maxBetValue = 1000
local oddsToWin = 50
local originalOddsToWin = 50
local currencyHeld = 0

function clearScreen()
    term.clear()
    monitor.clear()

    term.setCursorPos(1, 1)
    monitor.setCursorPos(1, 1)
end

function waitForInteraction()
    clearScreen()

    monitor.write("Devil's Toss")
    monitor.setCursorPos(1, 2)
    monitor.write("Your next flip could double it all")
end

function resetGameState()
    workingMultipler = startingMultipler
    currentLosingStreak = 0.0
end

while true do
    -- Reset
    clearScreen()
    resetGameState()
    waitForInteraction()

    print("Insert Hades Card then press enter to continue")
    inputName = read()

    -- Check for disk start game if valid

    sleep(0.1)
end
