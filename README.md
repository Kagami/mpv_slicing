`slicing-copy.lua` is a Lua script forked from [Kagami/mpv_slicing](https://github.com/Kagami/mpv_slicing).
The script is for mpv to cut fragments of the video.

#### Usage

Make sure you have FFmpeg installed. Put `slicing_copy.lua` to `~/.config/mpv/scripts/` or `~/.mpv/scripts/` directory to autoload the script or load it manually with `--script=<path>`.

Press `c` first time to mark the start of the fragment. Press it again to mark the end of the fragment and write it to the disk. Press `C` to clear the fragment. Press `a` to toggle audio capturing (default on).

Logs can be found in console (press `~` to open and `esc` to close by default), which might contains something useful.

You could change key bindings and all parameters of the output video by editing your `input.conf` and `script-opts/slicing_copy.conf`, see [slicing_copy.lua](slicing_copy.lua) and [mpv manual](https://mpv.io/manual/master/#lua-scripting-on-update]]\)) for details.

#### Limitation

If `--merge-files` is passed to mpv, the script won't work.

The script will pass `-referer` and `-user_agent` to ffmpeg to support some online videos (since commit [`f9248e4`](https://github.com/snylonue/mpv_slicing_copy/commit/f9248e452d4f50e13152169c7417cb6003e6925d)), but filenames could be unfriendly.

Output videos will be placed in `cutfragments` in mpv configuration directory by default instead of the home directory since commit [`7b3ef36`](https://github.com/snylonue/mpv_slicing_copy/commit/7b3ef36fbe854f238e296a8b16af25bc281142c9).  
Before [`f4a46ab`](https://github.com/snylonue/mpv_slicing_copy/commit/f4a46abafacc0e0d110c4c04ab8d2710eb6afbc4), neither the script nor ffmpeg will check or create the directory. After it, the directory would be checked (though not created) and a warning message would be printed in console if something went wrong. You could always change the directory by editing option `target_dir` in `script-opts/slicing_copy.conf` or [source code](slicing_copy.lua).

#### License

mpv_slicing_copy - Cut video fragments with mpv

Written in 2015 by Kagami Hiiragi <kagami@genshiken.org>

Modified in 2019 by Snylonue <snylonue@gmail.com>

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.

You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
