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

Command = { name = "", args = {""} }

function Command:new(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    if name then
        o.name = name
        o.args[1] = name
    end
    return o
end
function Command:arg(...)
    for _, v in ipairs({...}) do
        self.args[#self.args + 1] = v
    end
    return self
end
function Command:as_array()
    return self.args
end
function Command:as_str()
    return table.concat(self.args, " ")
end

local function timestamp(duration)
    local hours = math.floor(duration / 3600)
    local minutes = math.floor(duration % 3600 / 60)
    local seconds = duration % 60
    return string.format("%02d:%02d:%02.03f", hours, minutes, seconds)
end

local function osd(str)
    return mp.osd_message(str, 3)
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
        o.target_dir,
        get_outname(shift, endpos)
    )
    local cmds = Command:new(o.ffmpeg_path)
        :arg("-v", "warning")
        :arg("-y")
        :arg("-stats")
        :arg("-ss", (command_template.ss:gsub("$shift", shift)))
        :arg("-i", inpath)
        :arg("-t", (command_template.t:gsub("$duration", endpos - shift)))
        :arg("-c:v", o.vcodec)
        :arg("-c:a", o.acodec)
        :arg((copy_audio and {nil} or {"-an"})[1])
        :arg(outpath)
    msg.info("Run commands: " .. cmds:as_str())
    local res, err = mp.command_native({
        name = "subprocess",
        args = cmds:as_array(),
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
    if not pos then
        osd("Failed to get timestamp")
        msg.error("Failed to get timestamp: " .. err)
        return
    end
    if cut_pos then
        local shift, endpos = cut_pos, pos
        if shift > endpos then
            shift, endpos = endpos, shift
        elseif shift == endpos then
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
end

local function toggle_audio()
    copy_audio = not copy_audio
    osd("Audio capturing is " .. (copy_audio and "enabled" or "disabled"))
end

local function clear_toggle_mark()
    cut_pos = nil
    osd("Cleared cut fragment")
end

options.read_options(o)
o.target_dir = mp.command_native({ "expand-path", (o.target_dir:gsub('"', "")) })
mp.add_key_binding("c", "slicing_mark", toggle_mark)
mp.add_key_binding("a", "slicing_audio", toggle_audio)
mp.add_key_binding("C", "clear_slicing_mark", clear_toggle_mark)