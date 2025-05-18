local history = dofile(minetest.get_modpath("textshield") .. "/history.lua")

local last_message_time = {}
local SPAM_DELAY = tonumber(minetest.settings:get("textshield_spam_delay")) or 2

local MSG_SPAM_WARNING_LABEL = minetest.settings:get("textshield_spam_warning_label")
    or "Please do not spam the chat or repeat characters."
local MSG_SPAM_WARNING_BUTTON = minetest.settings:get("textshield_spam_warning_button") or "Understood"
local MSG_LOG_SPAM_FAST = minetest.settings:get("textshield_log_spam_fast") or "Spam detected (message too fast): "
local MSG_LOG_SPAM_REPEAT = minetest.settings:get("textshield_log_spam_repeat") or "Spam detected (repeated characters): "

local function show_spam_warning(player_name)
    local formspec = string.format([[
        size[6,3]
        label[0.5,1;%s]
        button_exit[2,2;2,1;ok;%s]
    ]], MSG_SPAM_WARNING_LABEL, MSG_SPAM_WARNING_BUTTON)
    minetest.show_formspec(player_name, "textshield:spam", formspec)
end

local function has_repeated_chars(message)
    return message:find("(.)%1%1%1%1%1%1") ~= nil
end

minetest.register_on_chat_message(function(name, message)
    local now = minetest.get_gametime()
    local last = last_message_time[name] or 0

    if now - last < SPAM_DELAY then
        local player = minetest.get_player_by_name(name)
        if player then
            show_spam_warning(name)
            player:set_hp(player:get_hp() - 2)
        end
        history.log(name, MSG_LOG_SPAM_FAST .. message)
        return true
    end

    if has_repeated_chars(message) then
        local player = minetest.get_player_by_name(name)
        if player then
            show_spam_warning(name)
            player:set_hp(player:get_hp() - 2)
        end
        history.log(name, MSG_LOG_SPAM_REPEAT .. message)
        return true
    end

    last_message_time[name] = now
end)
