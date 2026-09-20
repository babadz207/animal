--[[
    ========================================================================
    DUNGEON QUEST REBORN - KAITUN MAIN LOADSTRING
    ========================================================================
    GitHub Repository: https://github.com/babadz207/animal
    ========================================================================
--]]

local success, content = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/babadz207/animal/main/dungeon_quest_reborn/main.lua?t=" .. tostring(tick()))
end)

if not success or not content or #content == 0 then
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
