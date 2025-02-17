FROM ubuntu:jammy
LABEL author="https://github.com/aBARICHELLO/godot-ci/graphs/contributors"

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    git-lfs \
    unzip \
    wget \
    zip \
    adb \
    openjdk-17-jdk-headless \
    rsync \
    make \
    curl \
    && rm -rf /var/lib/apt/lists/*

ARG GODOT_VERSION="4.2.2"
ARG RELEASE_NAME="stable"
ARG SUBDIR=""
ARG GODOT_TEST_ARGS=""
ARG GODOT_PLATFORM="linux.x86_64"

RUN wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_${GODOT_PLATFORM}.zip \
    && wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}${SUBDIR}/Godot_v${GODOT_VERSION}-${RELEASE_NAME}_export_templates.tpz \
    && mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME} \
    && unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_${GODOT_PLATFORM}.zip \
    && mv Godot_v${GODOT_VERSION}-${RELEASE_NAME}_${GODOT_PLATFORM} /usr/local/bin/godot \
    && unzip Godot_v${GODOT_VERSION}-${RELEASE_NAME}_export_templates.tpz \
    && mv templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME} \
    && rm -f Godot_v${GODOT_VERSION}-${RELEASE_NAME}_export_templates.tpz Godot_v${GODOT_VERSION}-${RELEASE_NAME}_${GODOT_PLATFORM}.zip

ADD getbutler.sh /opt/butler/getbutler.sh
RUN bash /opt/butler/getbutler.sh
RUN /opt/butler/bin/butler -V

ENV PATH="/opt/butler/bin:${PATH}"

# Download and setup android-sdk
ENV ANDROID_HOME="/usr/lib/android-sdk"
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip \
    && unzip commandlinetools-linux-*_latest.zip -d cmdline-tools \
    && mv cmdline-tools $ANDROID_HOME/ \
    && rm -f commandlinetools-linux-*_latest.zip

ENV PATH="${ANDROID_HOME}/cmdline-tools/cmdline-tools/bin:${PATH}"

RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "build-tools;33.0.2" "platforms;android-33" "cmdline-tools;latest" "cmake;3.22.1" "ndk;25.2.9519653"

# Adding android keystore and settings
RUN keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 \
    && mv debug.keystore /root/debug.keystore

RUN godot -v -e --quit --headless ${GODOT_TEST_ARGS}
RUN echo 'export/android/android_sdk_path = "/usr/lib/android-sdk"' >> ~/.config/godot/editor_settings-4.tres
RUN echo 'export/android/debug_keystore = "/root/debug.keystore"' >> ~/.config/godot/editor_settings-4.tres
RUN echo 'export/android/debug_keystore_user = "androiddebugkey"' >> ~/.config/godot/editor_settings-4.tres
RUN echo 'export/android/debug_keystore_pass = "android"' >> ~/.config/godot/editor_settings-4.tres
RUN echo 'export/android/force_system_user = false' >> ~/.config/godot/editor_settings-4.tres
RUN echo 'export/android/timestamping_authority_url = ""' >> ~/.config/godot/editor_settings-4.tres
RUN echo 'export/android/shutdown_adb_on_exit = true' >> ~/.config/godot/editor_settings-4.tres

#region FBX GLTF
RUN cd /root/
RUN wget https://github.com/godotengine/FBX2glTF/releases/latest/download/FBX2glTF-linux-x86_64.zip -O /root/FBX2glTF-linux-x86_64.zip
RUN unzip /root/FBX2glTF-linux-x86_64.zip
RUN rm -rf /root/FBX2glTF-linux-x86_64.zip
RUN godot --headless --quit
RUN sed -i -e 's@filesystem/import/fbx/fbx2gltf_path = ""@filesystem/import/fbx/fbx2gltf_path = "/root/FBX2glTF-linux-x86_64/FBX2glTF-linux-x86_64"@g' \
    /root/.config/godot/editor_settings-4.tres
#endregion
