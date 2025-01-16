#!/bin/bash
set -o errexit
set -o nounset
echoYellow(){
    echo -e "\033[33m$*\033[0m"
}
echoCyan(){
    echo -e "\033[36m$*\033[0m"
}

message=""
farmid=""
use_ip_as_hostname="false"
user_gitee="false"


## 遍历参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --use_ip_as_hostname)
            use_ip_as_hostname="true"
            shift
            ;;
        --user_gitee)
            user_gitee="true"
            shift
            ;;
        --farmid)
            farmid="$2"
            shift 2 # 跳过参数和值
            ;;
        *)
            echo "未知选项: $1"
            exit 1
            ;;
    esac
done


if [[ ${user_gitee} == "true" ]]; then
    ## Get the latest version - Gitee
    releases=$(curl -s https://gitee.com/api/v5/repos/xiaoliuxiao6/os/releases)
    VER=$(echo ${releases} | jq -r '.[-1].tag_name')
    URL="https://gitee.com/minerx-vip/os-core/releases/download/${VER}/${FILENAME}"
else
    ## Get the latest version - Github
    releases=$(curl -s https://api.github.com/repos/minerx-vip/os-core/releases/latest)
    VER=$(echo ${releases} | jq -r '.tag_name')
    URL="https://github.com/minerx-vip/os-core/releases/download/${VER}/os-${VER}.tar.gz"
fi


## Download && Extract
echoCyan "Latest version: ${VER}"
FILENAME="os-${VER}.tar.gz"
ARCHIVE="/tmp/${FILENAME}"
sudo rm -f ${ARCHIVE}
sudo wget -t 5 -T 20 -c "${URL}" -P /tmp/ || { echoYellow "Download failed!"; exit 1; }
sudo tar xzf ${ARCHIVE} -C / || { echoYellow "Install failed!"; exit 1; }


## If farmid is specified, perform an overwrite installation.
RIG_CONFIG="/os/config/rig.conf"
if [[ -z ${farmid} ]]; then
    if [[ ! -f ${RIG_CONFIG} ]]; then
        echoYellow "Please specify farmid"
        exit 1
    fi
else
    echo "farm_hash=${farmid}" > /os/config/rig.conf
    echo 'server_url="http://110.249.214.76:30012"' >> /os/config/rig.conf
fi


## Handle Hostname
if [[ ${use_ip_as_hostname} == 'true' ]]; then
    IP=$(ip route get 8.8.8.8 | grep -oP '(?<=src\s)\d+(\.\d+){3}')
    IFS='.' read -r -a ip_parts <<< "$IP"
    for i in "${!ip_parts[@]}"; do
        ip_parts[$i]=$(printf "%03d" "${ip_parts[$i]}")
    done
    IP_STR="${ip_parts[0]}_${ip_parts[1]}_${ip_parts[2]}_${ip_parts[3]}"

    sed -i '/^worker_name/d' /os/config/rig.conf
    echo "worker_name=\"ip_${IP_STR}\"" >> /os/config/rig.conf
    message="Use ${IP_STR} as the hostname"
fi


## Add environment variables
NEW_PATH="/os/bin/"
BASHRC_FILE="/etc/bash.bashrc"
sudo sed -i "\|export PATH=.*${NEW_PATH}|d" ${BASHRC_FILE}
echo "export PATH=${NEW_PATH}:\$PATH" | sudo tee -a ${BASHRC_FILE} > /dev/null


## Install as a systemd service
## 临时注释
sudo cp /os/service/os-service.service /etc/systemd/system/
sudo systemctl daemon-reload
# sudo systemctl enable os-service.service
# sudo systemctl stop os-service.service
# sudo systemctl start os-service.service

echoCyan "------------------------------------------------------------------ ${VER} Installation successful. ${message}"
