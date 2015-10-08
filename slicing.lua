local msg = require "mp.msg"
local options = require "mp.options"

local cut_pos = nil
local copy_audio = false
local o = {
    target_dir = "~",
    vcodec = "rawvideo",
    acodec = "pcm_s16le",
    prevf = "",
    vf = "format=yuv444p16,scale=in_color_matrix=$matrix,format=bgr24",
    postvf = "",
    opts = "",
    ext = "avi",
    command_template = [[
        ffmpeg -loglevel warning
        -ss $shift -i '$in' -t $duration
        -c:v $vcodec -c:a $acodec $audio
        -vf $prevf$vf$postvf $opts '$out.$ext'
    ]],
}
options.read_options(o)

function timestamp(duration)
    local hours = duration / 3600
    local minutes = duration % 3600 / 60
    local seconds = duration % 60
    return string.format("%02d:%02d:%02.03f", hours, minutes, seconds)
end

function log(str)
    return mp.osd_message(str)
end

function escape(str)
    return str:gsub("'", "'\\''")
end

function get_csp()
    local csp = mp.get_property("colormatrix")
    if csp == "bt.601" then return "bt601"
        elseif csp == "bt.709" then return "bt709"
        elseif csp == "smpte-240m" then return "smpte240m"
        else error("unknown colorspace " .. csp)
    end
end

function get_outname(shift, endpos)
    local name = mp.get_property("filename")
    local dotidx = name:reverse():find(".", 1, true)
    if dotidx then name = name:sub(1, -dotidx-1) end
    name = name:gsub(" ", "_")
    name = name .. string.format(".%s-%s", timestamp(shift), timestamp(endpos))
    return name
end

function cut(shift, endpos)
    local cmd = o.command_template:gsub("%s+", " ")
    local inpath = escape(mp.get_property("path"))
    -- TODO: Windows?
    local outpath = escape(string.format(
        "%s/%s",
        o.target_dir:gsub("~", os.getenv("HOME")),
        get_outname(shift, endpos)))

    cmd = cmd:gsub("$shift", shift)
    cmd = cmd:gsub("$duration", endpos - shift)
    cmd = cmd:gsub("$vcodec", o.vcodec)
    cmd = cmd:gsub("$acodec", o.acodec)
    cmd = cmd:gsub("$audio", copy_audio and "" or "-an")
    cmd = cmd:gsub("$prevf", o.prevf)
    cmd = cmd:gsub("$vf", o.vf)
    cmd = cmd:gsub("$postvf", o.postvf)
    cmd = cmd:gsub("$matrix", get_csp())
    cmd = cmd:gsub("$opts", o.opts)
    -- Beware that input/out filename may contain replacing patterns.
    cmd = cmd:gsub("$ext", o.ext)
    cmd = cmd:gsub("$out", outpath)
    cmd = cmd:gsub("$in", inpath, 1)

    msg.info(cmd)
    os.execute(cmd)
end

function toggle_mark()
    local pos = mp.get_property_number("time-pos")
    if cut_pos then
        local shift, endpos = cut_pos, pos
        if shift > endpos then
            shift, endpos = endpos, shift
        end
        if shift == endpos then
            log("Cut fragment is empty")
        else
            cut_pos = nil
            log(string.format(
                "Cut fragment: %s - %s",
                timestamp(shift), timestamp(endpos)))
            cut(shift, endpos)
        end
    else
        cut_pos = pos
        log(string.format("Marked %s as start position", timestamp(pos)))
    end
end

function toggle_audio()
    copy_audio = not copy_audio
    log("Audio capturing is " .. (copy_audio and "enabled" or "disabled"))
end

mp.add_key_binding("c", "slicing_mark", toggle_mark)
mp.add_key_binding("a", "slicing_audio", toggle_audio)
