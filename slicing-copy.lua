local msg = require "mp.msg"
local utils = require "mp.utils"
local options = require "mp.options"

local cut_pos = nil
local copy_audio = true
local command_template = {
    ss = "$shift",
    i = "$in",
    t = "$duration",
    c = {
        v = "$vcodec",
        a = "$acodec",
    },
    o = "$out.$ext",
}
local o = {
    ffmpeg_path = "ffmpeg",
    vcodec = "copy",
    acodec = "copy",
}
options.read_options(o)

function timestamp(duration)
    local hours = duration / 3600
    local minutes = duration % 3600 / 60
    local seconds = duration % 60
    return string.format("%02d:%02d:%02.03f", hours, minutes, seconds)
end
function osd(str)
    return mp.osd_message(str, 3)
end
function get_homedir()
    -- It would be better to do platform detection instead of fallback but
    -- it's not that easy in Lua.
    return os.getenv("HOME") or os.getenv("USERPROFILE") or ""
end
function trim(str)
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end
function get_outname(shift, endpos)
    local name = mp.get_property("filename")
    local dotidx = name:reverse():find(".", 1, true)
    if dotidx then name = name:sub(1, -dotidx-1) end
    name = name:gsub(" ", "_")
    name = name .. "_" .. string.format("%s-%s", timestamp(shift), timestamp(endpos))
    name = name:gsub(":", "-")
    return name
end
function cut(shift, endpos)
    local inpath = utils.join_path(
        utils.getcwd(),
        mp.get_property("stream-path")
    )
    local outpath = utils.join_path(
        get_homedir(),
        get_outname(shift, endpos)
    )
    local cmds = {
        o.ffmpeg_path,
        "-v", "warning",
        "-y",
        "-stats",
        "-ss", command_template.ss:gsub("$shift", shift),
        "-i", command_template.i:gsub("$in", inpath, 1),
        "-t", command_template.t:gsub("$duration", endpos - shift),
        "-c:v", command_template.c.v:gsub("$vcodec", o.vcodec),
        "-c:a", command_template.c.a:gsub("$acodec", o.acodec),
        copy_audio and "" or "-an",
        command_template.o:gsub("$out", outpath):gsub("$ext", mp.get_property("file-format"))
    }
    for i, v in ipairs(cmds) do
        if v == "" then
            table.remove(cmds, i)
            break
        end
    end
    -- there is a strange number 1 at the end of the array
    -- remove it
    table.remove(cmds)
    msg.debug("Run commands: " .. table.concat(cmds, " "))
    local res, err = mp.command_native({
        name = "subprocess",
        args = cmds,
        capture_stdout = true,
        capture_stderr = true,
    })
    if err then
        msg.error("Failed to run commands: " .. utils.to_string(err))
    else
        msg.info("Run commands successfully: " .. res.stderr:gsub("^%s*(.-)%s*$", "%1"))
    end
end
function toggle_mark()
    local pos = mp.get_property_number("time-pos")
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
        msg.error("Failed to get timestamp")
    end
end
function toggle_audio()
    copy_audio = not copy_audio
    osd("Audio capturing is " .. (copy_audio and "enabled" or "disabled"))
end
function clear_toggle_mark()
    cut_pos = nil
    osd("Cut fragment is cleared")
end

mp.add_key_binding("c", "slicing_mark", toggle_mark)
mp.add_key_binding("a", "slicing_audio", toggle_audio)
mp.add_key_binding("C", "clear_slicing_mark", clear_toggle_mark)