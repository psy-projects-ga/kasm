FROM node:12-buster as wwwstage
ARG KASMWEB_RELEASE="9aca68d9fe343215096ec2af5be688fc55e0a73b"

RUN \ 
echo "Build ClientSide" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒               Build ClientSide               ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
export QT_QPA_PLATFORM="offscreen" QT_QPA_FONTDIR="/usr/share/fonts" && \ 
mkdir "/src" && \ 
cd "/src" && \ 
wget "https://github.com/kasmtech/noVNC/tarball/${KASMWEB_RELEASE}" -O - | tar --strip-components=1 -xz && \ 
npm install && \ 
npm run build

RUN \ 
echo "Organize Output" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒                Organize Output               ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
mkdir "/build-out" && \ 
cd "/src" && \ 
rm -rf "node_modules/" && \ 
cp -R ./* "/build-out/" && \ 
cd "/build-out" && \ 
rm *.md && \ 
rm AUTHORS && \ 
cp "index.html" "vnc.html" && \ 
mkdir "Downloads"

FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy
ARG KASMVNC_RELEASE="1.1.0"
COPY --from=wwwstage "/build-out" "/www"

RUN \ 
echo "Install Build Deps" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒             Install Build Deps               ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
apt update && \ 
apt build-dep -y "libxfont-dev" "xorg-server" && \ 
DEBIAN_FRONTEND="noninteractive" apt install -y \
  "autoconf" \
  "automake" \
  "cmake" \
  "git" \
  "grep" \
  "libavcodec-dev" \
  "libdrm-dev" \
  "libepoxy-dev" \
  "libgbm-dev" \
  "libgif-dev" \
  "libgnutls28-dev" \
  "libgnutls28-dev" \
  "libjpeg-dev" \
  "libjpeg-turbo8-dev" \
  "libpciaccess-dev" \
  "libpng-dev" \
  "libssl-dev" \
  "libtiff-dev" \
  "libtool" \
  "libwebp-dev" \
  "libx11-dev" \
  "libxau-dev" \
  "libxcursor-dev" \
  "libxcursor-dev" \
  "libxcvt-dev" \
  "libxdmcp-dev" \
  "libxext-dev" \
  "libxkbfile-dev" \
  "libxrandr-dev" \
  "libxrandr-dev" \
  "libxshmfence-dev" \
  "libxtst-dev" \
  "meson" \
  "nettle-dev" \
  "tar" \
  "tightvncserver" \
  "wget" \
  "wayland-protocols" \
  "xinit" \
  "xserver-xorg-dev"

RUN \ 
echo "Build libjpeg-turbo" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒             Build libjpeg-turbo              ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
mkdir "/jpeg-turbo" && \ 
export JPEG_TURBO_RELEASE="$(curl -sX GET "https://api.github.com/repos/libjpeg-turbo/libjpeg-turbo/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]')" && \ 
curl -o "/tmp/jpeg-turbo.tar.gz" -L "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${JPEG_TURBO_RELEASE}.tar.gz" && \ 
tar xf "/tmp/jpeg-turbo.tar.gz" -C "/jpeg-turbo/" --strip-components=1 && \ 
cd "/jpeg-turbo" && \ 
export MAKEFLAGS="-j$(nproc)" CFLAGS="-fpic" && \ 
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -G"Unix Makefiles" && \ 
make && \ 
make install

RUN \ 
echo "Build KasmVNC" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒                Build KasmVNC                 ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
git clone "https://github.com/kasmtech/KasmVNC.git" "src" && \ 
cd "/src" && \ 
git checkout -f ${KASMVNC_release} && \ 
sed -i -e '/find_package(FLTK/s@^@#@' -e '/add_subdirectory(tests/s@^@#@' "CMakeLists.txt" && \ 
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_VIEWER:BOOL=OFF -DENABLE_GNUTLS:BOOL=OFF . && \ 
make -j4

RUN \ 
echo "Build Xorg" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒                 Build Xorg                   ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
export XORG_VER="1.20.14" && \ 
export XORG_PATCH="$(echo "$XORG_VER" | grep -Po '^\d.\d+' | sed 's#\.##')" && \ 
cd "/src" && \ 
wget --no-check-certificate -O "/tmp/xorg-server-${XORG_VER}.tar.gz" "https://www.x.org/archive/individual/xserver/xorg-server-${XORG_VER}.tar.gz" && \ 
tar --strip-components=1 -C "unix/xserver" -xf "/tmp/xorg-server-${XORG_VER}.tar.gz" && \ 
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
echo "Generate Final Output" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒            Generate Final Output             ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
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
mkdir /build-out && \ 
tar xzf kasmvnc-Linux*.tar.gz -C /build-out/ && \ 
rm -Rf "/build-out/usr/local/man"
