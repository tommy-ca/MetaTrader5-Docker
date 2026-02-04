FROM ghcr.io/linuxserver/baseimage-kasmvnc:debianbookworm

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Metatrader Docker:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="gmartin"

ENV TITLE=Metatrader5
ENV WINEPREFIX="/config/.wine"
ENV WINEDEBUG=-all

# Install all packages in a single layer to reduce image size
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    supervisor \
    procps \
    && mkdir -pm755 /etc/apt/keyrings \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key -o /etc/apt/keyrings/winehq-archive.key \
    && curl -fsSL https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources -o /etc/apt/sources.list.d/winehq-bookworm.sources \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install --install-recommends -y winehq-stable \
    && pip install --break-system-packages --no-cache-dir mt5linux==0.1.9 rpyc==6.0.2 plumbum==1.10.0 numpy==2.0.2 pyxdg==0.28 prometheus_client psutil requests \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download dependencies during build to bake them into the image
RUN mkdir -p /defaults/installers \
    && curl -o /defaults/installers/mono.msi https://dl.winehq.org/wine/wine-mono/10.3.0/wine-mono-10.3.0-x86.msi \
    && echo "cece5c63180094dffdf01d0fbe362a4b606e5280b98cdfd1b8568cdf9b572f98  /defaults/installers/mono.msi" | sha256sum -c - \
    && curl -L -o /defaults/installers/python-installer.exe https://www.python.org/ftp/python/3.9.13/python-3.9.13.exe \
    && echo "f363935897bf32adf6822ba15ed1bfed7ae2ae96477f0262650055b6e9637c35  /defaults/installers/python-installer.exe" | sha256sum -c - \
    && curl -o /defaults/installers/mt5setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe \
    && echo "d437fd760587d24e094864215b86a441cc64ab897cace2b2a21a46614b3f4e36  /defaults/installers/mt5setup.exe" | sha256sum -c -

COPY --chmod=755 Metatrader /Metatrader
COPY root/defaults /defaults
COPY --chmod=755 scripts /scripts

# Healthcheck uses the unified validation tool
HEALTHCHECK --interval=30s --timeout=30s --start-period=300s --retries=3 \
  CMD python3 /scripts/validate_connectivity.py --json || exit 1

# Expose VNC (3000), RPyC Bridge (8001), Prometheus Metrics (9100)
EXPOSE 3000 8001 9100
VOLUME /config
