--[[
    ========================================================================
    DUNGEON QUEST REBORN - KAITUN MAIN LOADSTRING
    ========================================================================
    GitHub Repository: https://github.com/babadz207/animal
    ========================================================================
--]]

local HttpService = game:GetService("HttpService")

local function ResolveLatestCommit()
    local ok, res = pcall(function()
        return game:HttpGet("https://api.github.com/repos/babadz207/animal/commits/main")
    end)
    if ok and res then
        local okJson, data = pcall(function() return HttpService:JSONDecode(res) end)
        if okJson and type(data) == "table" and data.sha then
            return data.sha
        end
    end
    return "d3c735c"
end

local ref = ResolveLatestCommit()
local targetUrl = "https://raw.githubusercontent.com/babadz207/animal/" .. ref .. "/dungeon_quest_reborn/main.lua"

local success, content = pcall(function()
    return game:HttpGet(targetUrl)
end)

if not success or not content or #content == 0 then
    -- Fallback nếu API bị chặn hoặc lỗi
    pcall(function()
        content = game:HttpGet("https://raw.githubusercontent.com/babadz207/animal/main/dungeon_quest_reborn/main.lua")
    end)
end

if not content or #content == 0 then
    warn("[DungeonQuest Kaitun] Không thể tải mã nguồn từ GitHub! Kiểm tra kết nối mạng.")
    return
end

local fn, compileErr = loadstring(content)
if not fn then
    warn("[DungeonQuest Kaitun] Lỗi biên dịch cú pháp: " .. tostring(compileErr))
    error("[DungeonQuest Kaitun] Syntax Error: " .. tostring(compileErr))
    return
end

local runSuccess, runErr = pcall(fn)
if not runSuccess then
    warn("[DungeonQuest Kaitun] Lỗi khi thực thi: " .. tostring(runErr))
end

