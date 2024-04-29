FROM mono:latest
LABEL author="https://github.com/aBARICHELLO/godot-ci/graphs/contributors"

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    git-lfs \
    python \
    python-openssl \
    unzip \
    wget \
    zip \
    rsync \
    make \
    curl \
    && rm -rf /var/lib/apt/lists/*

# When in doubt see the downloads page
# https://downloads.tuxfamily.org/godotengine/
ARG GODOT_VERSION="3.4.2"

# Example values: stable, beta3, rc1, alpha2, etc.
# Also change the SUBDIR property when NOT using stable
ARG RELEASE_NAME="stable"

# This is only needed for non-stable builds (alpha, beta, RC)
# e.g. SUBDIR "/beta3"
# Use an empty string "" when the RELEASE_NAME is "stable"
ARG SUBDIR=""
ARG ZIP_GODOT_PLATFORM="linux_headless_64"
ARG FILENAME_GODOT_PLATFORM="linux_headless.64"

RUN wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/mono/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${ZIP_GODOT_PLATFORM}.zip \
    && wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/mono/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_export_templates.tpz

RUN mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}.mono \
    && unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${ZIP_GODOT_PLATFORM}.zip \
    && mv Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${ZIP_GODOT_PLATFORM}/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${FILENAME_GODOT_PLATFORM} /usr/local/bin/godot \
    && mv Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${ZIP_GODOT_PLATFORM}/GodotSharp /usr/local/bin/GodotSharp \
    && unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_export_templates.tpz \
    && mv templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME}.mono \
    && rm -f Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_export_templates.tpz Godot_v${GODOT_VERSION}-${RELEASE_NAME}_mono_${ZIP_GODOT_PLATFORM}.zip

ADD getbutler.sh /opt/butler/getbutler.sh
RUN bash /opt/butler/getbutler.sh
RUN /opt/butler/bin/butler -V

ENV PATH="/opt/butler/bin:${PATH}"

#region .NET Installation
RUN . /etc/os-release && wget https://packages.microsoft.com/config/$ID/$VERSION_ID/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
RUN apt update
RUN apt install -y dotnet-sdk-6.0 dotnet-sdk-7.0 dotnet-sdk-8.0
#endregion

#region FBX GLTF
RUN cd /root/
RUN wget https://github.com/godotengine/FBX2glTF/releases/latest/download/FBX2glTF-linux-x86_64.zip -O /root/FBX2glTF-linux-x86_64.zip
RUN unzip /root/FBX2glTF-linux-x86_64.zip
RUN rm -rf /root/FBX2glTF-linux-x86_64.zip
RUN godot --headless --quit
RUN sed -i -e 's@filesystem/import/fbx/fbx2gltf_path = ""@filesystem/import/fbx/fbx2gltf_path = "/root/FBX2glTF-linux-x86_64/FBX2glTF-linux-x86_64"@g' \
    /root/.config/godot/editor_settings-4.tres
#endregion
