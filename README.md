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
pip3 install ffmpeg-python
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
