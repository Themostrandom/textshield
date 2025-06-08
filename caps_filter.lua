local history = dofile(minetest.get_modpath("textshield") .. "/history.lua")

local MSG_CAPS_WARNING_LABEL = minetest.settings:get("textshield_caps_warning_label")
    or "Please do not write in ALL CAPS, it is considered shouting."
local MSG_CAPS_WARNING_BUTTON = minetest.settings:get("textshield_caps_warning_button") or "Understood"
local MSG_LOG_EXCESSIVE_CAPS = minetest.settings:get("textshield_log_excessive_caps") or "Excessive caps: "

local function is_all_caps(message)
    local letters = {}
    for c in message:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if c:match("[%aА-Яа-яЁё]") then
            table.insert(letters, c)
        end
    end

    if #letters < 5 then return false end

    local joined = table.concat(letters)
    return joined == joined:upper()
end



local function show_caps_warning(player_name)
    local formspec = string.format([[
        size[6,3]
        label[0.5,1;%s]
        button_exit[2,2;2,1;ok;%s]
    ]], MSG_CAPS_WARNING_LABEL, MSG_CAPS_WARNING_BUTTON)
    minetest.show_formspec(player_name, "textshield:caps", formspec)
end

minetest.register_on_chat_message(function(name, message)
    if is_all_caps(message) then
        local player = minetest.get_player_by_name(name)
        if player then
            show_caps_warning(name)
            player:set_hp(player:get_hp() - 2)
        end
        history.log(name, MSG_LOG_EXCESSIVE_CAPS .. message)
        return true
    end
end)
