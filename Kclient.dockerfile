FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy
ARG KCLIENT_RELEASE

RUN \ 
echo "Install Build Deps" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒             Install Build Deps               ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
apt-get update && \ 
DEBIAN_FRONTEND="noninteractive" apt install -y gnupg && \ 
curl -s "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" | apt-key add - && \ 
echo "deb https://deb.nodesource.com/node_18.x jammy main" >"/etc/apt/sources.list.d/nodesource.list" && \ 
apt-get update && \ 
DEBIAN_FRONTEND="noninteractive" apt-get install -y \
  "g++" \
  "gcc" \
  "libpam0g-dev" \
  "libpulse-dev" \
  "make" \
  "nodejs"

RUN \ 
echo "Grab Source" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒                Grab Source                   ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
mkdir -p "/kclient" && \ 
[ -z "${KCLIENT_RELEASE:-}" ] && KCLIENT_RELEASE="$(curl -sX GET "https://api.github.com/repos/linuxserver/kclient/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]')" && \ 
curl -o "/tmp/kclient.tar.gz" -L "https://github.com/linuxserver/kclient/archive/${KCLIENT_RELEASE}.tar.gz" && \ 
tar xf "/tmp/kclient.tar.gz" -C "/kclient/" --strip-components=1

RUN \ 
echo "Install Node Modules" && \ 
echo "██████████████████████████████████████████████████" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "▒▒           Install Node Modules               ▒▒" && \ 
echo "▒▒                                              ▒▒" && \ 
echo "██████████████████████████████████████████████████" && \ 
cd "/kclient" && \ 
npm install && \ 
rm -fv "package-lock.json"
