# Base image
FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/lutrisuser
ENV WINEPREFIX=/data/wine/wineprefix
ENV WINE_NAME=wine-10.8-staging-tkg-ntsync-x86_64
ENV LUTRIS_WINE_PATH="$HOME/.local/share/lutris/runners/wine"
ENV LUTRIS_YAML_PATH="$HOME/.local/share/lutris/yaml"
ENV WINE_TKG_PATH="$LUTRIS_WINE_PATH/$WINE_NAME"
ENV PATH="$WINE_TKG_PATH/bin:/usr/games:$PATH"

# Add i386 architecture for Wine
RUN dpkg --add-architecture i386

# Install dependencies and Wine
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash curl wget gnupg software-properties-common \
        python3 python3-pip python3-setuptools xdg-utils \
        winbind libx11-dev libxext-dev libxrender-dev libxrandr-dev \
        ca-certificates p7zip-full xz-utils libfuse2 \
        fonts-liberation fonts-dejavu mesa-utils sudo lsb-release \
        wine64 wine32 libgl1-mesa-glx libglu1-mesa dbus-x11 xterm \
        libgl1-mesa-glx:i386 libgl1-mesa-dri:i386 mesa-vulkan-drivers \
        mesa-vulkan-drivers:i386 libvulkan1 libvulkan1:i386 \
        libc6:i386 libfreetype6:i386 libx11-6:i386 libxext6:i386 \
        libxrandr2:i386 libxrender1:i386 ttf-mscorefonts-installer \
        libgtk-3-0 gvfs adwaita-icon-theme-full at-spi2-core pciutils librsvg2-common && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash lutrisuser && \
    echo "lutrisuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to lutrisuser to install Wine directly in runners
USER lutrisuser
WORKDIR $HOME

RUN mkdir -p $WINE_TKG_PATH && \
    TMPDIR=$(mktemp -d) && \
    curl -L https://github.com/Kron4ek/Wine-Builds/releases/download/10.8/wine-10.8-staging-tkg-ntsync-amd64-wow64.tar.xz \
        | tar -xJ -C $TMPDIR && \
    mv $TMPDIR/wine-10.8-staging-tkg-ntsync-amd64-wow64/* $WINE_TKG_PATH/ && \
    rm -rf $TMPDIR && \
    chmod -R a+rX $WINE_TKG_PATH

# Ensure local Lutris YAML directory exists
RUN mkdir -p "$LUTRIS_YAML_PATH"

# Install Lutris
RUN sudo add-apt-repository -y ppa:lutris-team/lutris && \
    sudo apt-get update && sudo apt-get install -y lutris

# Install Entrypoint
USER root

# Copy Lutris YAML files
RUN mkdir -p /opt/lutrisdata
COPY prime-wine-lutris.yaml /opt/lutrisdata/

# Entrypoint script
RUN cat << 'EOF' > /opt/lutrisdata/entrypoint.sh
#!/bin/bash
set -e

# Copy YAML to home
cp -f /opt/lutrisdata/prime-wine-lutris.yaml "$HOME/"

export WINE="$WINE_TKG_PATH/bin/wine"
export WINESERVER="$WINE_TKG_PATH/bin/wineserver"
export WINEDEBUG=-all
export NO_AT_BRIDGE=1
export GVFS_DISABLE_UDEV=1

mkdir -p "$WINEPREFIX"
chmod -R u+rwX "$WINEPREFIX" 2>/dev/null || true

echo ">>> Starting dbus session..."
eval "$(dbus-launch --sh-syntax)"
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID

echo ">>> Ensuring Wine prefix exists..."
if [ ! -f "$WINEPREFIX/system.reg" ]; then
    $WINE wineboot --init
    # Windows packages
    winetricks -q win10 corefonts vcrun2022 wine-mono
    # Graphics packages
    winetricks -q dxvk vkd3d
fi

echo ">>> Launching Lutris..."
exec lutris
EOF

RUN chmod +x /opt/lutrisdata/entrypoint.sh

# Run Lutris as user (required)
USER lutrisuser

# Persistent Wine prefixes
WORKDIR /data/wine
VOLUME ["/data/wine"]

CMD ["/opt/lutrisdata/entrypoint.sh"]
