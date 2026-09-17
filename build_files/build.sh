#!/bin/bash

set -ouex pipefail

### Package repositories

# The Aurora base image builds its multimedia stack (ffmpeg, libfdk-aac, openh264) from
# negativo17's "fedora-multimedia" repo, which the base image ships *disabled*. negativo17 and
# RPM Fusion are not co-installable: the base image's libfdk-aac (epoch 1) obsoletes both
# fdk-aac and fdk-aac-free, so pulling steam's 32-bit chain out of RPM Fusion leaves
# pipewire-libs.i686 with no provider for libfdk-aac.so.2 and the transaction fails to resolve.
# So: enable negativo17 for the installs that need it, and never add RPM Fusion.
#
# skip_if_unavailable=0 turns an unreachable negativo17 mirror into a loud build failure instead
# of a silent fallback that resolves against the wrong repos.
MULTIMEDIA=(
    --enablerepo=fedora-multimedia
    --setopt=fedora-multimedia.skip_if_unavailable=0
)

dnf5 -y config-manager setopt fedora-cisco-openh264.enabled=1

#### Games and desktop utilities
# steam comes from negativo17; the rest are stock Fedora.
dnf5 -y "${MULTIMEDIA[@]}" install steam gamescope antimicrox simple-scan ydotool

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
    glslc \
    wayland-devel \
    wayland-protocols-devel

#### FFmpeg and codecs (negativo17, matching the ffmpeg already in the base image)
dnf5 -y "${MULTIMEDIA[@]}" install ffmpeg ffmpeg-devel

#### CLI tools (replacing Brew formulas)
# wl-clipboard provides wl-copy/wl-paste for Wayland (replaces xclip).
dnf5 -y install bat fd-find ripgrep gh helix wl-clipboard
