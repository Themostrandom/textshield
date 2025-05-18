local S = minetest.get_translator("textshield")
local badwords = {}

local specific_words = {
    ["wtf"] = true,
    ["mf"] = true,
    ["tf"] = true
}


local history = dofile(minetest.get_modpath("textshield") .. "/history.lua")
dofile(minetest.get_modpath("textshield") .. "/caps_filter.lua")
dofile(minetest.get_modpath("textshield") .. "/antispam.lua")

local lookalike_map = {
    ["!"] = "i",
    ["1"] = "i",
    ["0"] = "o",
    ["@"] = "a",
    ["$"] = "s",
    ["3"] = "e",
    ["7"] = "t",
    ["+"] = "t",
    ["5"] = "s",
    ["4"] = "a",
    ["9"] = "g",
    ["8"] = "b"
}

local BADWORD_DAMAGE = tonumber(minetest.settings:get("badword_damage")) or 6
local BADWORD_WARNING = minetest.settings:get("badword_warning") or "Inappropriate language detected! Please remain respectful."
local SIMILARITY_THRESHOLD = tonumber(minetest.settings:get("similarity_threshold")) or 0.75
local BADWORD_LANGUAGES = minetest.settings:get("badword_languages") or "ar,de,en,es,fr,it,ja,ko,ru,zh"

local function normalize_text(text)
    return (text:lower():gsub(".", function(c)
        return lookalike_map[c] or c
    end))
end

local function load_badwords()
    local langs = {}
    for lang in BADWORD_LANGUAGES:gmatch("([^,]+)") do
        table.insert(langs, lang)
    end
    for _, lang in ipairs(langs) do
        local path = minetest.get_modpath("textshield") .. "/badwords/" .. lang .. ".txt"
        local file = io.open(path, "r")
        if file then
            for line in file:lines() do
                table.insert(badwords, line:lower())
            end
            file:close()
        end
    end
end

load_badwords()

local function is_similar(word, badword)
    if #word < 3 then return false end
    local match_count = 0
    local min_len = math.min(#word, #badword)
    for i = 1, min_len do
        if word:sub(i, i) == badword:sub(i, i) then
            match_count = match_count + 1
        end
    end
    return (match_count / #badword) >= SIMILARITY_THRESHOLD
end

local function contains_badword(message)
    local normalized_message = normalize_text(message)
    for word in normalized_message:gmatch("%w+") do
        word = word:lower()
        for _, badword in ipairs(badwords) do
            if is_similar(word, badword) then
                return true
            end
        end
    end
    return false
end

local function show_warning(player_name)
    minetest.show_formspec(player_name, "textshield:warning", string.format([[
        size[6,3]
        label[0.5,1;%s]
        button_exit[2,2;2,1;ok;Understood]
    ]], BADWORD_WARNING))
end

minetest.register_on_chat_message(function(name, message)
    local trimmed_msg = message:lower():gsub("^%s*(.-)%s*$", "%1")

    if specific_words[trimmed_msg] then
        local player = minetest.get_player_by_name(name)
        if player then
            show_warning(name)
            player:set_hp(player:get_hp() - BADWORD_DAMAGE)
        end
        history.log(name, "Bad word detected: " .. message)
        return true
    end

    if contains_badword(message) then
        local player = minetest.get_player_by_name(name)
        if player then
            show_warning(name)
            player:set_hp(player:get_hp() - BADWORD_DAMAGE)
        end
        history.log(name, "Bad word detected: " .. message)
        return true
    end
end)
