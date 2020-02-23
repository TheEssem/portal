FROM node:alpine

RUN echo -e "\nhttp://dl-cdn.alpinelinux.org/alpine/edge/testing/\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories

# Install Chromium, audio and other misc packages, cleanup, create Chromium policies folders, workarounds
RUN apk --no-cache upgrade && \
    apk add --no-cache \
        dbus \
        dbus-x11 \
        xvfb \
        xdotool \
        openbox \
        ttf-liberation \
        ttf-freefont \
        ttf-droid-nonlatin \
        ttf-dejavu \
        font-noto-emoji \
        font-noto \
        pulseaudio \
        gst-plugins-base \
        gst-plugins-good \
        gst-plugins-bad \
        gst-plugins-ugly \ 
        gst-libav \
        gstreamer-doc \
        gstreamer-tools \
        gst-plugins-good-gtk \
        gst-plugins-good-qt \
        ffmpeg \
        chromium \
        sudo \
        grep \
        procps \
        xdg-utils \
        libappindicator \
    && mkdir -p /var/run/dbus \
    && mkdir -p /etc/chromium/policies/managed /etc/chromium/policies/recommended \
    && mkdir /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix && chown root /tmp/.X11-unix
    
# Install Widevine component for Chromium
RUN WIDEVINE_VERSION=$(wget --quiet -O - https://dl.google.com/widevine-cdm/versions.txt | tail -n 1) \
    && wget "https://dl.google.com/widevine-cdm/$WIDEVINE_VERSION-linux-x64.zip" -O /tmp/widevine.zip \
    && mkdir -p /tmp/WidevineCdm/_platform_specific/linux_x64 \
    && unzip -p /tmp/widevine.zip manifest.json > /tmp/WidevineCdm/manifest.json \
    && unzip -p /tmp/widevine.zip LICENSE.txt > /tmp/WidevineCdm/LICENSE.txt \
    && unzip -p /tmp/widevine.zip libwidevinecdm.so > /tmp/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so \
    && mv /tmp/WidevineCdm /usr/lib/chromium/WidevineCdm \
    && rm /tmp/widevine.zip

# Add normal user
RUN adduser glados -s /bin/sh -D \
    && addgroup glados audio

# Copy information
WORKDIR /home/glados/.internal
COPY . .

# Chromium Policies & Preferences
COPY ./configs/chromium_policy.json /etc/chromium/policies/managed/policies.json
COPY ./configs/master_preferences.json /etc/chromium/master_preferences
# Pulseaudio Configuration
COPY ./configs/pulse_config.pa /tmp/pulse_config.pa
# Openbox Configuration
COPY ./configs/openbox_config.xml /var/lib/openbox/openbox_config.xml

# Install deps, build then cleanup
RUN yarn && yarn build && yarn cache clean && rm -rf src

ENTRYPOINT [ "sh", "./start.sh" ]
