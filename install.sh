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
down_uri="https://minerx-download.oss-cn-shanghai.aliyuncs.com"
backup_down_uri="http://47.97.210.214:8889"


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

##################################################################
## 下载文件并提取
##################################################################
download_file() {
    local uri=$1
    local version_file="${uri}/VERSION"
    local filename
    local url
    local archive

    # 获取版本号
    local ver=$(curl -s "$version_file" | awk -F= '{print $2}')
    [[ -z "$ver" ]] && return 1
    filename="os-${ver}.tar.gz"
    url="${uri}/${filename}"
    archive="/tmp/${filename}"  # 在这里给 archive 赋值

    echoCyan "最新版本: ${ver}"

    # 删除已有的下载文件
    sudo rm -f "${archive}"

    # 下载并保存
    if sudo wget -t 5 -T 20 -c "${url}" -P /tmp/; then
        echoCyan "下载成功: ${filename}"
        sudo tar xzf ${archive} -C / || { echoYellow "Install failed!"; exit 1; }
        return 0
    else
        echoYellow "下载失败: ${filename}"
        return 1
    fi
}

# 检查主下载 URI
if ! download_file "${down_uri}"; then
    # 主下载失败，尝试备用 URI
    echoYellow "主下载 URI 失败，尝试备用 URI..."

    if ! download_file "${backup_down_uri}"; then
        echoRed "备用下载 URI 也失败了！"
        exit 1
    fi
fi


##################################################################
## If farmid is specified, perform an overwrite installation.
##################################################################
RIG_CONFIG="/os/config/rig.conf"
if [[ -z ${farmid} ]]; then
    if [[ ! -f ${RIG_CONFIG} ]]; then
        echoYellow "Please specify farmid"
        exit 1
    fi
else
    echo "farm_hash=${farmid}" > /os/config/rig.conf
    echo "worker_name=`hostname`" >> /os/config/rig.conf
    echo 'server_url="https://api.minerx.vip"' >> /os/config/rig.conf
fi


##################################################################
## Handle Hostname
##################################################################
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


##################################################################
## Add environment variables
##################################################################
NEW_PATH="/os/bin/"
BASHRC_FILE="/etc/bash.bashrc"
sudo sed -i "\|export PATH=.*${NEW_PATH}|d" ${BASHRC_FILE}
echo "export PATH=${NEW_PATH}:\$PATH" | sudo tee -a ${BASHRC_FILE} > /dev/null


##################################################################
## Install as a systemd service
##################################################################
sudo cp /os/service/os-core.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable os-core.service
sudo systemctl restart os-core.service

echoCyan "------------------------------------------------------------------ Installation successful. ${message}"
