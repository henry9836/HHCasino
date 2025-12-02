-- Find the ME Bridge peripheral
local bridge = peripheral.find("meBridge")

if not bridge then
    error("ME Bridge peripheral not found.")
end

-- Define the item and amount you want
local diamondItem = {
    name = "minecraft:diamond", -- The item's registry name
    count = 64                 -- A stack of 64
}

-- Define the side of the ME Bridge where the chest/target inventory is
local targetDirection = "up"

print("Attempting to withdraw 64 Diamonds...")

-- Execute the export (withdraw) operation
local extractedCount, errorMessage = bridge.exportItem(diamondItem, targetDirection)

if extractedCount and extractedCount > 0 then
    print("SUCCESS: Withdrew " .. extractedCount .. " Diamonds to the inventory on the " .. targetDirection .. " side.")
elseif errorMessage then
    print("ERROR: " .. errorMessage)
else
    print("WARNING: Could not withdraw Diamonds. Check item name, count, or if the chest is full.")
end