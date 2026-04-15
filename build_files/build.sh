#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Enable RPM Fusion (free + non-free) and Cisco OpenH264
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf5 -y config-manager setopt fedora-cisco-openh264.enabled=1

#### Games and desktop utilities
dnf5 -y install steam gamescope simple-scan ydotool

#### Build toolchain
# clang-devel provides libclang, required by Rust bindgen (e.g. whisper-rs in voice).
# cmake is required by whisper.cpp (pulled in via whisper-rs).
dnf5 -y install \
    gcc gcc-c++ \
    clang clang-devel \
    cmake make \
    pkgconf-pkg-config

#### Development libraries for local Rust builds (reader, voice)
# glslang provides shader compiler tools required by whisper.cpp's cmake FindVulkan.
# gtk3-devel is needed by rfd (file dialogs) in reader.
dnf5 -y install \
    alsa-lib-devel \
    expat-devel \
    fontconfig-devel \
    freetype-devel \
    gtk3-devel \
    libX11-devel \
    libxcb-devel \
    libxkbcommon-devel \
    vulkan-loader-devel \
    glslang \
    wayland-devel \
    wayland-protocols-devel

#### FFmpeg and codecs (RPM Fusion free + non-free, replaces Brew ffmpeg ecosystem)
dnf5 -y install ffmpeg ffmpeg-devel

#### CLI tools (replacing Brew formulas)
# wl-clipboard provides wl-copy/wl-paste for Wayland (replaces xclip).
dnf5 -y install bat fd-find ripgrep gh helix wl-clipboard
