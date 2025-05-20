local storage = minetest.get_mod_storage()
local history = {}

local CMD_TS_DESC = minetest.settings:get("textshield_cmd_ts_desc") or "View a player's textshield history"
local CMD_TS_CLEAR_DESC = minetest.settings:get("textshield_cmd_ts_clear_desc") or "Clear a player's history"
local MSG_USAGE_TS = minetest.settings:get("textshield_msg_usage_ts") or "Usage: /ts <player>"
local MSG_USAGE_TS_CLEAR = minetest.settings:get("textshield_msg_usage_ts_clear") or "Usage: /ts_clear <player>"
local MSG_NO_HISTORY = minetest.settings:get("textshield_msg_no_history") or "No history found for "
local MSG_HISTORY_CLEARED = minetest.settings:get("textshield_msg_history_cleared") or "History for %s cleared."

local MUTE_1H = tonumber(minetest.settings:get("textshield_mute_1h")) or 3600
local MUTE_12H = tonumber(minetest.settings:get("textshield_mute_12h")) or 43200
local MUTE_1D = tonumber(minetest.settings:get("textshield_mute_1d")) or 86400
local MUTE_7D = tonumber(minetest.settings:get("textshield_mute_7d")) or 604800

local function get_warn_count(player_name)
    local key = "warn_count:" .. player_name
    local count = storage:get_int(key)
    return count or 0
end

local function set_warn_count(player_name, count)
    local key = "warn_count:" .. player_name
    storage:set_int(key, count)
end

local function get_mute_end(player_name)
    local key = "mute_end:" .. player_name
    local ts = storage:get_int(key)
    return ts or 0
end

local function set_mute_end(player_name, timestamp)
    local key = "mute_end:" .. player_name
    storage:set_int(key, timestamp)
end

local function is_player_muted(player_name)
    local mute_end = get_mute_end(player_name)
    return os.time() < mute_end
end

local function mute_player(player_name, time_seconds, reason)
    local player = minetest.get_player_by_name(player_name)
    local mute_end_time = os.time() + time_seconds
    set_mute_end(player_name, mute_end_time)

    if player then
        minetest.chat_send_player(player_name, "[TextShield] You have been muted for " .. (time_seconds / 3600) .. " hour(s) due to: " .. reason)
        local privs = minetest.get_player_privs(player_name)
        privs.shout = false
        minetest.set_player_privs(player_name, privs)
    end

    minetest.after(time_seconds, function()
        local current_privs = minetest.get_player_privs(player_name)
        current_privs.shout = true
        minetest.set_player_privs(player_name, current_privs)
        set_mute_end(player_name, 0)
        minetest.chat_send_player(player_name, "[TextShield] Your mute has expired.")
    end)
end

function history.log(player_name, message)
    local key = "log:" .. player_name
    local current = storage:get_string(key)
    local time = os.date("%Y-%m-%d %H:%M:%S")
    local entry = string.format("[%s] %s", time, message)

    local new_log = current ~= "" and (current .. "\n" .. entry) or entry
    storage:set_string(key, new_log)

    local count = get_warn_count(player_name) + 1
    set_warn_count(player_name, count)

	if count == 5 then
		mute_player(player_name, MUTE_1H, "5 warnings")
		history.log(player_name, "Automatically muted for 1 hour (5 warnings)")
	elseif count == 7 then
		mute_player(player_name, MUTE_12H, "7 warnings")
		history.log(player_name, "Automatically muted for 12 hours (7 warnings)")
	elseif count == 10 then
		mute_player(player_name, MUTE_1D, "10 warnings")
		history.log(player_name, "Automatically muted for 1 day (10 warnings)")
	elseif count == 15 then
		mute_player(player_name, MUTE_7D, "15 warnings")
		history.log(player_name, "Automatically muted for 7 days (15 warnings)")
	end

end

function history.get(player_name)
    local key = "log:" .. player_name
    local log = storage:get_string(key)
    if log == "" then
        return {}
    end

    local lines = {}
    for line in log:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    return lines
end

function history.clear(player_name)
    local key = "log:" .. player_name
    storage:set_string(key, "")
    set_warn_count(player_name, 0)
    set_mute_end(player_name, 0)
end

minetest.register_on_chat_message(function(name, message)
    if is_player_muted(name) then
        minetest.chat_send_player(name, "[TextShield] You are muted and cannot send messages.")
        return true
    end
    return false
end)

minetest.register_on_chatcommand(function(player_name, command)
    if is_player_muted(player_name) then
        local blocked_commands = {
            me = true,
            t = true,
            m = true,
            msg = true,
        }
        if blocked_commands[command] then
            minetest.chat_send_player(player_name, "You cannot use this command while muted.")
            return true
        end
    end
    return false
end)


minetest.register_chatcommand("ts", {
    params = "<player>",
    description = CMD_TS_DESC,
    privs = {kick = true},
    func = function(name, param)
        if param == "" then
            return false, minetest.colorize("#FF0000", MSG_USAGE_TS)
        end
        local lines = history.get(param)
        if #lines == 0 then
            return true, minetest.colorize("#FFA500", MSG_NO_HISTORY .. param)
        end
        return true, minetest.colorize("#00FF00", table.concat(lines, "\n"))
    end
})

minetest.register_chatcommand("ts_clear", {
    params = "<player>",
    description = CMD_TS_CLEAR_DESC,
    privs = {ban = true},
    func = function(name, param)
        if param == "" then
            return false, minetest.colorize("#FF0000", MSG_USAGE_TS_CLEAR)
        end
        history.clear(param)
        return true, minetest.colorize("#00FF00", string.format(MSG_HISTORY_CLEARED, param))
    end
})

local function parse_duration(duration_str)
    local num = tonumber(duration_str:sub(1, -2))
    local unit = duration_str:sub(-1)

    if not num or not unit then return nil end

    if unit == "h" then
        return num * 3600
    elseif unit == "d" then
        return num * 86400
    elseif unit == "m" then
        return num * 2592000
    else
        return nil
    end
end

minetest.register_chatcommand("mute", {
    params = "<player> <duration (e.g., 1h, 2d, 1m)> <reason>",
    description = "Mute a player for a specified duration with a reason",
    privs = {kick = true},
    func = function(name, param)
        local target, duration_str, reason = param:match("^(%S+)%s+(%S+)%s+(.+)$")
        if not target or not duration_str or not reason then
            return false, minetest.colorize("#FF0000", "Usage: /mute <player> <duration> <reason>")
        end

        local duration = parse_duration(duration_str)
        if not duration then
            return false, minetest.colorize("#FF0000", "Invalid duration format. Use h (hour), d (day), m (month)")
        end

        mute_player(target, duration, reason)
        history.log(target, string.format("Manually muted for %s due to: %s", duration_str, reason))
        return true, minetest.colorize("#00FF00", target .. " has been muted for " .. duration_str)
    end
})

minetest.register_chatcommand("unmute", {
    params = "<player>",
    description = "Unmute a player manually",
    privs = {kick = true},
    func = function(name, param)
        if param == "" then
            return false, minetest.colorize("#FF0000", "Usage: /unmute <player>")
        end
        set_mute_end(param, 0)
        local privs = minetest.get_player_privs(param)
        privs.shout = true
        minetest.set_player_privs(param, privs)
        history.log(param, "Unmuted manually")
        minetest.chat_send_player(param, "[TextShield] You have been unmuted.")
        return true, minetest.colorize("#00FF00", param .. " has been unmuted.")
    end
})


return history
