FROM ubuntu:jammy
ARG KCLIENT_RELEASE

RUN \ 
printf "%s\n" "Install Build Deps" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒             Install Build Deps               ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
apt-get update && \ 
DEBIAN_FRONTEND="noninteractive" apt install -y "gnupg" "wget" && \ 
wget "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" -qO - | apt-key add - && \ 
printf "%s\n" "deb https://deb.nodesource.com/node_18.x jammy main" >"/etc/apt/sources.list.d/nodesource.list" && \ 
apt-get update && \ 
DEBIAN_FRONTEND="noninteractive" apt-get install -y \
  "curl" \
  "g++" \
  "gcc" \
  "libpam0g-dev" \
  "libpulse-dev" \
  "make" \
  "nodejs"

RUN \ 
printf "%s\n" "Grab Source" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒                Grab Source                   ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
mkdir -p "/kclient" && \ 
[ -z "${KCLIENT_RELEASE:-}" ] && KCLIENT_RELEASE="$(curl -sX GET "https://api.github.com/repos/linuxserver/kclient/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]')" && \ 
wget "https://github.com/linuxserver/kclient/archive/${KCLIENT_RELEASE}.tar.gz" --show-progress --progress=bar:force:noscroll -qO - | tar --strip-components=1 -xzC "/kclient/"

RUN \ 
printf "%s\n" "Install Node Modules" \
  "██████████████████████████████████████████████████" \
  "▒▒                                              ▒▒" \
  "▒▒           Install Node Modules               ▒▒" \
  "▒▒                                              ▒▒" \
  "██████████████████████████████████████████████████" && \ 
cd "/kclient" && \ 
npm install && \ 
rm -fv "package-lock.json"
