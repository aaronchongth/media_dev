# Media Development

Some tools that I use to work with videos and images, most of them are just wrappers of `ffmpeg`.

## Prerequisites

* [`ffmpeg`](https://www.ffmpeg.org/)

* [Time VLC extension](https://addons.videolan.org/p/1154032) - Vendored in this repository

## Setup

```bash
# Create workspace
git clone https://github.com/aaronchongth/media_dev

# Assuming installing vlc using snap
cd media_dev/extensions
cp time_ext.lua ~/snap/vlc/current/.local/share/vlc/lua/extensions/.
cp time_intf.lua ~/snap/vlc/current/.local/share/vlc/lua/intf/.

sudo apt install ffmpeg
```

# Trim and concatenate

Prepare a time stamp file that looks like this,

```
00:00:10 00:00:20.4
00:01:20 00:02:00
00:30:20.3 00:30:40
```

```bash
cd media_dev/scripts
python3 trim_and_concat.py \
  --input INPUT_VIDEO_PATH \
  --stamps TIME_STAMPS_FILE_PATH \
  --output OUTPUT_VIDEO_PATH
```

# Random `ffmpeg` notes,

* Lossless rotate: `ffmpeg -i input.mp4 -c copy -metadata:s:v:0 rotate=180 output.mp4`
* Cut without losing quality: `ffmpeg -i input.mp4 -ss {} -to {} -c copy output.mp4`
* Rotate arbitrary: `ffmpeg -i input.mp4 -vf "rotate=-3*PI/180" output.mp4`
* Rotate fixed: `ffmpeg -i input.mp4 -vf "transpose=1" output.mp4`
* Split basic: `ffmpeg -i input.mp4 -ss 00:00:00 -to 00:01:13.5 output.mp4`
* Lossless encoding: `ffmpeg -i input.mp4 -codec:v libx264 -crf 0 -preset ultrafast STUFF output.mp4`
