# Media Development

Some tools that I use to work with videos and images, most of them are just wrappers of `ffmpeg`.

## Prerequisites

* [`ffmpeg`](https://www.ffmpeg.org/)

* [Time VLC extension](https://addons.videolan.org/p/1154032) - Vendored in this repository

## Setup

```bash
# Create workspace
mkdir -p ~/workspaces/media_ws/src
git clone https://github.com/aaronchongth/media_dev

# Assuming installing vlc using snap
cd ~/workspaces/media_ws/src/media_dev/extensions
cp time_ext.lua ~/snap/vlc/current/.local/share/vlc/lua/extensions/.
cp time_intf.lua ~/snap/vlc/current/.local/share/vlc/lua/intf/.
```
