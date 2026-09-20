--[[
    Roblox Executor MCP - Universal Online Loader
    Author: babadz207
    Repository: https://github.com/babadz207/animal
--]]

getgenv().MCP_Loaded = nil
getgenv().MCP_ForceReload = true

-- Preferred bridge address
getgenv().BridgeURL = getgenv().BridgeURL or "10.0.2.2:16384"

local hasWs = (type(WebSocket) == "table" or type(websocket) == "table" or (syn and type(syn.websocket) == "table"))
local hasReq = (type(request) == "function" or type(http_request) == "function" or (syn and type(syn.request) == "function"))
local execName = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"

print(string.format("[Roblox-MCP] Executor: %s | WebSocket: %s | Request: %s", tostring(execName), tostring(hasWs), tostring(hasReq)))

print("[Roblox-MCP] Đang tải connector mới nhất từ GitHub...")
local success, connectorCode = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/babadz207/animal/main/connector.luau?nocache=" .. tostring(os.time()))
end)

if success and connectorCode then
    print("[Roblox-MCP] Tải connector thành công! Đang kết nối tới " .. tostring(getgenv().BridgeURL) .. "...")
    local fn, err = loadstring(connectorCode)
    if fn then
        task.spawn(function()
            local ok, runErr = pcall(fn)
            if not ok then
                warn("[Roblox-MCP] Lỗi thực thi connector: " .. tostring(runErr))
            end
        end)
        print("[Roblox-MCP] Đã khởi chạy connector thread!")
    else
        warn("[Roblox-MCP] Lỗi biên dịch connector: " .. tostring(err))
    end
else
    warn("[Roblox-MCP] Lỗi khi tải connector từ GitHub: " .. tostring(connectorCode))
end
