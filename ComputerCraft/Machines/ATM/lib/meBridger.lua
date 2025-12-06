local Bridge = {}

Bridge.meBridge = peripheral.find("meBridge")

function Bridge.dumpAllItems()
    return Bridge.meBridge.listItems()
end

function Bridge.dumpAllItemsToScreen()
    local items = Bridge.dumpAllItems();

    for _ , item in pairs(items) do
        print(item.name ..  ":" .. item.amount)
    end
end

function Bridge.dumpAllItemsJson()
    local items = Bridge.dumpAllItems()
    local filteredData = {}

    for _, item in pairs(items) do
        table.insert(filteredData, {
            name = item.name,
            amount = item.amount
        })
    end

    return textutils.serializeJSON(filteredData)
end

function Bridge.withdrawItem(itemName, amount)
    local extractedCount, errorMessage = Bridge.meBridge.exportItem(diamondItem, "back")
    if errorMessage then
        print(errorMessage)
        print("Please enter to continue")
        read()
        return false
    end
    return true
end

return Bridge;
