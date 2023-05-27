FROM node:12-buster as wwwstage
ARG KASMWEB_RELEASE="9aca68d9fe343215096ec2af5be688fc55e0a73b"

RUN \ 
printf "%s\n" "Build ClientSide" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒               Build ClientSide               ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
DEBIAN_FRONTEND="noninteractive" apt install -y "wget" && \ 
export QT_QPA_PLATFORM="offscreen" QT_QPA_FONTDIR="/usr/share/fonts" && \ 
mkdir "/src" && cd "/src" && \ 
wget "https://github.com/kasmtech/noVNC/tarball/${KASMWEB_RELEASE}" --show-progress --progress=bar:force:noscroll -qO - | tar --strip-components=1 -xz && \ 
npm install && \ 
npm run build

RUN \ 
printf "%s\n" "Organize Output" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒                Organize Output               ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
mkdir "/build-out" && \ 
cd "/src" && \ 
rm -rf "node_modules/" && \ 
cp -R ./* "/build-out/" && \ 
cd "/build-out" && \ 
rm *.md "AUTHORS" && \ 
cp "index.html" "vnc.html" && \ 
mkdir "Downloads"

FROM ubuntu:jammy
ARG KASMVNC_RELEASE="1.1.0"
COPY --from=wwwstage "/build-out" "/www"

RUN \ 
printf "%s\n" "Install Build Deps" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒             Install Build Deps               ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
printf "%s\n" "deb-src http://archive.ubuntu.com/ubuntu/ jammy main" >>"/etc/apt/sources.list" && \ 
apt update && \ 
apt build-dep -y "libxfont-dev" "xorg-server" && \ 
DEBIAN_FRONTEND="noninteractive" apt install -y \
  "tar" "wget" "curl" "git" "grep" \
  "autoconf" "automake" "cmake" \
  "libavcodec-dev" "libdrm-dev" "libepoxy-dev" "libgbm-dev" \
  "libgif-dev" "libgnutls28-dev" "libgnutls28-dev" "libjpeg-dev" \
  "libjpeg-turbo8-dev" "libpciaccess-dev" "libpng-dev" "libssl-dev" \
  "libtiff-dev" "libtool" "libwebp-dev" "libx11-dev" "libxau-dev" \
  "libxcursor-dev" "libxcursor-dev" "libxcvt-dev" "libxdmcp-dev" \
  "libxext-dev" "libxkbfile-dev" "libxrandr-dev" "libxrandr-dev" \
  "libxshmfence-dev" "libxtst-dev" "meson" "nettle-dev" "tightvncserver" \
  "wayland-protocols" "xinit" "xserver-xorg-dev"

RUN \ 
printf "%s\n" "Build libjpeg-turbo" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒             Build libjpeg-turbo              ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
mkdir "/jpeg-turbo" && cd "/jpeg-turbo" && \ 
export JPEG_TURBO_RELEASE="$(curl -sX GET "https://api.github.com/repos/libjpeg-turbo/libjpeg-turbo/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]')" && \ 
wget "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${JPEG_TURBO_RELEASE}.tar.gz" --show-progress --progress=bar:force:noscroll -qO - | tar --strip-components=1 -xzC "/jpeg-turbo/" && \ 
export MAKEFLAGS="-j$(nproc)" CFLAGS="-fpic" && \ 
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -G"Unix Makefiles" && \ 
make && \ 
make install

RUN \ 
printf "%s\n" "Build KasmVNC" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒                Build KasmVNC                 ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
git clone "https://github.com/kasmtech/KasmVNC.git" "src" && \ 
cd "/src" && \ 
git checkout -f ${KASMVNC_release} && \ 
sed -i -e '/find_package(FLTK/s@^@#@' -e '/add_subdirectory(tests/s@^@#@' "CMakeLists.txt" && \ 
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_VIEWER:BOOL=OFF -DENABLE_GNUTLS:BOOL=OFF . && \ 
make -j4

RUN \ 
printf "%s\n" "Build Xorg" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒                 Build Xorg                   ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
export XORG_VER="1.20.14" && \ 
export XORG_PATCH="$(printf "%s\n" "${XORG_VER}" | grep -Po '^\d.\d+' | sed 's#\.##')" && \ 
cd "/src" && \ 
wget "https://www.x.org/archive/individual/xserver/xorg-server-${XORG_VER}.tar.gz" --no-check-certificate --show-progress --progress=bar:force:noscroll -qO - | tar --strip-components=1 -xzkC "unix/xserver" && \ 
cd "/src/unix/xserver" && \ 
patch -Np1 -i ../"xserver${XORG_PATCH}.patch" && \ 
patch -s -p0 <../"CVE-2022-2320-v1.20.patch" && \ 
autoreconf -i && \ 
./configure --prefix=/opt/kasmweb \
  --with-xkb-path=/usr/share/X11/xkb \
  --with-xkb-output=/var/lib/xkb \
  --with-xkb-bin-directory=/usr/bin \
  --with-default-font-path="/usr/share/fonts/X11/misc,/usr/share/fonts/X11/cyrillic,/usr/share/fonts/X11/100dpi/:unscaled,/usr/share/fonts/X11/75dpi/:unscaled,/usr/share/fonts/X11/Type1,/usr/share/fonts/X11/100dpi,/usr/share/fonts/X11/75dpi,built-ins" \
  --with-sha1=libcrypto \
  --without-dtrace --disable-dri \
  --disable-static \
  --disable-xinerama \
  --disable-xvfb \
  --disable-xnest \
  --disable-xorg \
  --disable-dmx \
  --disable-xwin \
  --disable-xephyr \
  --disable-kdrive \
  --disable-config-hal \
  --disable-config-udev \
  --disable-dri2 \
  --enable-glx \
  --disable-xwayland \
  --enable-dri3 && \ 
find . -name "Makefile" -exec sed -i "s/-Werror=array-bounds//g" {} \; && \ 
make -j4

RUN \ 
printf "%s\n" "Generate Final Output" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒            Generate Final Output             ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
mkdir -p "/src/xorg.build/bin" && cd "/src/xorg.build/bin/" && \ 
ln -s "/src/unix/xserver/hw/vnc/Xvnc" "Xvnc" && \ 
cd .. && mkdir -p "man/man1" && touch "man/man1/Xserver.1" && \ 
cp "/src/unix/xserver/hw/vnc/Xvnc.man" "man/man1/Xvnc.1" && \ 
mkdir "lib" && cd "lib" && \ 
ln -s "/usr/lib/x86_64-linux-gnu/dri" "dri" && \ 
cd "/src" && mkdir -p "builder/www" && \ 
cp -ax /www/* "builder/www/" && \ 
cp "builder/www/index.html" "builder/www/vnc.html" && \ 
make servertarball && \ 
mkdir "/build-out" && \ 
tar xzf kasmvnc-Linux*.tar.gz -C "/build-out/" && \ 
rm -Rf "/build-out/usr/local/man"
