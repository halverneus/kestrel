# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/aurora-dx-nvidia-open:stable

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
#
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

# Kestrel Branding
COPY resources/images/kestrel-logo-named-100.png /usr/share/pixmaps/fedora_logo_med.png
COPY resources/images/kestrel-logo-named-100.png /usr/share/pixmaps/fedora-logo.png
COPY resources/images/kestrel-logo-named.svg /usr/share/pixmaps/fedora-logo.svg
COPY resources/images/kestrel-logo-named-32.png /usr/share/pixmaps/fedora-logo-small.png
COPY resources/images/kestrel-logo-128x128.png /usr/share/pixmaps/fedora-logo-sprite.png
COPY resources/images/kestrel-logo.svg /usr/share/icons/hicolor/scalable/distributor-logo.svg
COPY resources/images/kestrel-logo-256x256.png /usr/share/pixmaps/system-logo.png
COPY resources/images/kestrel-logo-256x256.png /usr/share/pixmaps/system-logo-white.png

# System76 Keyboard Backlight Support
COPY resources/system76-keyboard/udev/99-kbd-backlight.rules /usr/lib/udev/rules.d/99-kbd-backlight.rules
COPY resources/system76-keyboard/cli/set-keyboard-backlight /usr/bin/set-keyboard-backlight
COPY resources/system76-keyboard/widget/org.kde.kbdbacklight /usr/share/plasma/plasmoids/org.kde.kbdbacklight


### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
