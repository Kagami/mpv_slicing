local msg = require "mp.msg"
local utils = require "mp.utils"
local options = require "mp.options"

local cut_pos = nil
local copy_audio = true
local command_template = {
    ss = "$shift",
    t = "$duration",
}
local o = {
    ffmpeg_path = "ffmpeg",
    -- make sure the dir is exist. The script will not check it
    target_dir = "~~/cutfragments",
    vcodec = "copy",
    acodec = "copy",
}
options.read_options(o)

local function timestamp(duration)
    local hours = duration / 3600
    local minutes = duration % 3600 / 60
    local seconds = duration % 60
    return string.format("%02d:%02d:%02.03f", hours, minutes, seconds)
end

local function osd(str)
    return mp.osd_message(str, 3)
end

local function replace(str, from, to)
    local res = str:gsub(from, to)
    return res
end

local function get_outname(shift, endpos)
    local name = mp.get_property("filename/no-ext")
    local fmt = mp.get_property("file-format")
    name = string.format("%s_%s-%s", name, timestamp(shift), timestamp(endpos))
    name = name:gsub(":", "-")
    return string.format("%s.%s", name, fmt)
end

local function cut(shift, endpos)
    local inpath = mp.get_property("stream-open-filename")
    local outpath = utils.join_path(
        mp.command_native({"expand-path", replace(o.target_dir, '"', "")}),
        get_outname(shift, endpos)
    )
    local cmds = {
        o.ffmpeg_path,
        "-v", "warning",
        "-y",
        "-stats",
        "-ss", command_template.ss:gsub("$shift", shift),
        "-i", inpath,
        "-t", command_template.t:gsub("$duration", endpos - shift),
        "-c:v", o.vcodec,
        "-c:a", o.acodec,
    }
    if not copy_audio then
        table.insert(cmds, "-an")
    end
    table.insert(cmds, outpath)
    msg.info("Run commands: " .. table.concat(cmds, " "))
    local res, err = mp.command_native({
        name = "subprocess",
        args = cmds,
        capture_stdout = true,
        capture_stderr = true,
    })
    if err then
        msg.error(utils.to_string(err))
    else
        msg.info((res.stderr:gsub("^%s*(.-)%s*$", "%1")))
    end
end

local function toggle_mark()
    local pos, err = mp.get_property_number("time-pos")
    if pos then
        if cut_pos then
            local shift, endpos = cut_pos, pos
            if shift > endpos then
                shift, endpos = endpos, shift
            end
            if shift == endpos then
                osd("Cut fragment is empty")
            else
                cut_pos = nil
                osd(string.format("Cut fragment: %s-%s", timestamp(shift), timestamp(endpos)))
                cut(shift, endpos)
            end
        else
            cut_pos = pos
            osd(string.format("Marked %s as start position", timestamp(pos)))
        end
    else
        msg.error("Failed to get timestamp: " .. err)
    end
end

local function toggle_audio()
    copy_audio = not copy_audio
    osd("Audio capturing is " .. (copy_audio and "enabled" or "disabled"))
end

local function clear_toggle_mark()
    cut_pos = nil
    osd("Cleared cut fragment")
end

mp.add_key_binding("c", "slicing_mark", toggle_mark)
mp.add_key_binding("a", "slicing_audio", toggle_audio)
mp.add_key_binding("C", "clear_slicing_mark", clear_toggle_mark)