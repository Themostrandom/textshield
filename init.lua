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

local accent_map = {
    ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["á"] = "a", ["ã"] = "a",
    ["ç"] = "c",
    ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
    ["î"] = "i", ["ï"] = "i", ["í"] = "i",
    ["ô"] = "o", ["ö"] = "o", ["ò"] = "o", ["ó"] = "o", ["õ"] = "o",
    ["ù"] = "u", ["û"] = "u", ["ü"] = "u", ["ú"] = "u",
    ["ý"] = "y", ["ÿ"] = "y",
    ["À"] = "a", ["Â"] = "a", ["Ä"] = "a", ["Á"] = "a", ["Ã"] = "a",
    ["Ç"] = "c",
    ["É"] = "e", ["È"] = "e", ["Ê"] = "e", ["Ë"] = "e",
    ["Î"] = "i", ["Ï"] = "i", ["Í"] = "i",
    ["Ô"] = "o", ["Ö"] = "o", ["Ò"] = "o", ["Ó"] = "o", ["Õ"] = "o",
    ["Ù"] = "u", ["Û"] = "u", ["Ü"] = "u", ["Ú"] = "u",
    ["Ý"] = "y", ["Ÿ"] = "y",
}


local BADWORD_DAMAGE = tonumber(minetest.settings:get("badword_damage")) or 6
local BADWORD_WARNING = minetest.settings:get("badword_warning") or "Inappropriate language detected! Please remain respectful."
local SIMILARITY_THRESHOLD = tonumber(minetest.settings:get("similarity_threshold")) or 0.75
local BADWORD_LANGUAGES = minetest.settings:get("badword_languages") or "ar,de,en,es,fr,it,ja,ko,ru,zh"

local function utf8_chars(text)
    local i = 1
    local len = #text
    return function()
        if i > len then return nil end
        local c = text:byte(i)
        local char_len = 1
        if c >= 0xF0 then char_len = 4
        elseif c >= 0xE0 then char_len = 3
        elseif c >= 0xC0 then char_len = 2
        end
        local char = text:sub(i, i + char_len - 1)
        i = i + char_len
        return char
    end
end


local function normalize_text(text)
    text = text:lower()
    local result = {}
    for c in utf8_chars(text) do
        local no_accent = accent_map[c] or c
        local normalized = lookalike_map[no_accent] or no_accent
        table.insert(result, normalized)
    end
    return table.concat(result)
end


local function compact_text(text)
    return normalize_text(text:gsub("[^%w]", ""))
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
    local compacted_message = compact_text(message)

    for word in normalized_message:gmatch("%w+") do
        for _, badword in ipairs(badwords) do
            if is_similar(word, badword) then
                return true
            end
        end
    end

    for _, badword in ipairs(badwords) do
        if compacted_message:find(badword, 1, true) then
            return true
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
