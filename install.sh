#!/bin/bash
set -o errexit
set -o nounset
# echoYellow(){
#     echo -e "\033[33m$*\033[0m"
# }
# echoCyan(){
#     echo -e "\033[36m$*\033[0m"
# }

message=""
farmid=""
use_ip_as_hostname="false"


## 遍历参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --use_ip_as_hostname)
            use_ip_as_hostname="true"
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

VER=$(curl -s https://down.minerx.vip/VERSION | awk -F= '{print $2}')
FILENAME="os-${VER}.tar.gz"
URL="https://down.minerx.vip/${FILENAME}"

## Download && Extract
echo "Latest version: ${VER}"

ARCHIVE="/tmp/${FILENAME}"
sudo rm -f ${ARCHIVE}
sudo wget -t 5 -T 20 -c "${URL}" -P /tmp/ || { echo "Download failed!"; exit 1; }
sudo tar xzf ${ARCHIVE} -C / || { echo "Install failed!"; exit 1; }


## If farmid is specified, perform an overwrite installation.
RIG_CONFIG="/os/config/rig.conf"
if [[ -z ${farmid} ]]; then
    if [[ ! -f ${RIG_CONFIG} ]]; then
        echo "Please specify farmid"
        exit 1
    fi
else
    echo "farm_hash=${farmid}" > /os/config/rig.conf
    echo "worker_name=`hostname`" >> /os/config/rig.conf
    echo 'server_url="https://api.minerx.vip"' >> /os/config/rig.conf
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
sudo cp /os/service/os-core.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable os-core.service
sudo systemctl stop os-core.service
sudo systemctl start os-core.service

echo "------------------------------------------------------------------ ${VER} Installation successful. ${message}"
