`slicing-copy.lua` is a Lua script modiftied with [Kagami/mpv_slicing](https://github.com/Kagami/mpv_slicing).
The script is for mpv to cut fragments of the video.

#### Usage

Make sure you have FFmpeg installed. Put `slicing-copy.lua` to `~/.config/mpv/scripts/` or `~/.mpv/scripts/` directory to autoload the script or load it manually with `--script=<path>`.

Press `c` first time to mark the start of the fragment. Press it again to mark the end of the fragment and write it to the disk. Press `C` to clear the fragment. Press `a` to toggle uncompressed audio capturing (default on). By default output videos will be placed in the home directory.

You could change key bindings and all parameters of the output video by editing your `input.conf` and `lua-settings/slicing.conf`, see [slicing-copy.lua](slicing-copy.lua) for details.

#### License

mpv_slicing - Cut video fragments with mpv

Written in 2015 by Kagami Hiiragi <kagami@genshiken.org>
Modified in 2019 by Snylonue <snylonue@gmail.com>

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.

You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
