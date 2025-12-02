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

function Bridge.dumpAllItemsJSON()
    local items = Bridge.dumpAllItems()
    return textutils.serializeJSON(items)
end

return Bridge;
