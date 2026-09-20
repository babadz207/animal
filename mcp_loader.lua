--[[
    Roblox Executor MCP - Universal Online Loader
    Author: babadz207
    Repository: https://github.com/babadz207/animal
--]]

getgenv().MCP_Loaded = nil
getgenv().MCP_ForceReload = true

-- Preferred bridge address
getgenv().BridgeURL = getgenv().BridgeURL or "127.0.0.1:16384"

print("[Roblox-MCP] Đang tải connector từ GitHub...")
local success, connectorCode = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/babadz207/animal/main/connector.luau")
end)

if success and connectorCode then
    print("[Roblox-MCP] Tải connector thành công! Đang kết nối tới " .. tostring(getgenv().BridgeURL) .. "...")
    local fn, err = loadstring(connectorCode)
    if fn then
        task.spawn(fn)
        print("[Roblox-MCP] Đã khởi chạy connector thành công!")
    else
        warn("[Roblox-MCP] Lỗi biên dịch connector: " .. tostring(err))
    end
else
    warn("[Roblox-MCP] Lỗi khi tải connector từ GitHub: " .. tostring(connectorCode))
end
