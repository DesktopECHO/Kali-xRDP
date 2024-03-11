#!/bin/bash

system32_path="/mnt/c/Windows/System32"
if [ -n "${PATH##*${system32_path}}" -a -n "${PATH##*${system32_path}:*}" ]; then
    export PATH=$PATH:${system32_path}
fi

games_path="/usr/games"
if [ -n "${PATH##*${games_path}}" -a -n "${PATH##*${games_path}:*}" ]; then
    export PATH=$PATH:${games_path}
fi

# Ensure base distro defaults xdg path are set if nothing filed up some
# defaults yet.
if [ -z "$XDG_DATA_DIRS" ]; then
    export XDG_DATA_DIRS="/usr/local/share:/usr/share"
fi

export QT_SCALE_FACTOR=HISCALE
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_X11_NO_MITSHM=1
export QT_ACCESSIBILITY=0
export QTWEBENGINE_CHROMIUM_FLAGS="--single-process"
export NO_AT_BRIDGE=1
export MOZ_FORCE_DISABLE_E10S=1
export MOZ_LAYERS_ALLOW_SOFTWARE_GL=1
export LIBXCB_ALLOW_SLOPPY_LOCK=1
export DESKTOP_SESSION=xfce
export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
export XDG_CONFIG_HOME=$HOME/.config
export XDG_RUNTIME_DIR=$HOME/.local
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export GTK2_RC_FILES=$HOME/.config/gtkrc-2.0
export GDK_SCALE=HISCALE
export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1
export GVFS_REMOTE_VOLUME_MONITOR_IGNORE=1
