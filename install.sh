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
## Sync Time
##################################################################

# 时间服务器列表
servers=("http://www.apple.com" "http://www.baidu.com" "http://www.google.com")

# 允许的时间差（秒）
time_tolerance=5

# 获取 HTTP 时间
get_http_time() {
    local server=$1
    local http_time

    # 获取 HTTP 响应的日期头信息并转换为时间戳
    http_time=$(curl -sI "$server" | grep -i "^date:" | awk '{for (i=2; i<=NF; i++) printf $i" "; print ""}' | xargs -I{} date -d "{}" +%s 2>/dev/null)

    if [[ -z "$http_time" ]]; then
        echo "Failed to fetch time from $server"
        return 1
    fi

    echo "$http_time"
    return 0
}

# 同步时间函数
sync_time() {
    local http_time=$1
    if date -s "@$http_time" >/dev/null 2>&1; then
        echo "Successfully synced time to $(date '+%Y-%m-%d %H:%M:%S')"
    else
        echo "Failed to sync time"
    fi
}

# 主函数
main() {
    # 获取本地时间戳
    local_time=$(date +%s)

    for server in "${servers[@]}"; do
        echo "Trying to fetch time from $server"
        http_time=$(get_http_time "$server")

        if [[ $? -eq 0 && -n "$http_time" ]]; then
            time_diff=$((local_time - http_time))
            time_diff=${time_diff#-} # 取绝对值

            # echo "Local time: $(date -d "@$local_time" '+%Y-%m-%d %H:%M:%S')"
            # echo "Server time: $(date -d "@$http_time" '+%Y-%m-%d %H:%M:%S')"
            # echo "Time difference: ${time_diff}s"

            # 如果时间差超过允许范围，则同步时间
            if ((time_diff > time_tolerance)); then
                echo "Time difference exceeds ${time_tolerance}s. Synchronizing..."
                sync_time "$http_time"
            else
                echo "Time is within acceptable range. No synchronization needed."
                break
            fi
        fi
    done

    echo "All servers failed to provide valid time. No synchronization performed."
}
main

##################################################################
## Install
##################################################################
VER=$(curl -s ${down_uri}/VERSION | awk -F= '{print $2}')
FILENAME="os-${VER}.tar.gz"
URL="${down_uri}/${FILENAME}"

## Download && Extract
echoCyan "Latest version: ${VER}"

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
sudo cp /os/service/os-core.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable os-core.service
sudo systemctl restart os-core.service

echoCyan "------------------------------------------------------------------ ${VER} Installation successful. ${message}"
