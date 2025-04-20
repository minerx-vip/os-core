#!/bin/bash
# set -o errexit
# set -o nounset


echoRed(){
    echo -e "\033[31m$*\033[0m"
}
echoRed_n(){
    echo -e "\033[31m$*\033[0m"
}
echoYellow(){
    echo -e "\033[33m$*\033[0m"
}
echoYellow_n(){
    echo -ne "\033[33m$*\033[0m"
}
echoBlue(){
    echo -e "\033[33m$*\033[0m"
}
echoBlue_n(){
    echo -e "\033[33m$*\033[0m"
}
echoGreen(){
    echo -e "\033[32m$*\033[0m"
}
echoGreen_n(){
    echo -e "\033[32m$*\033[0m"
}
echoCyan(){
    echo -e "\033[36m$*\033[0m"
}
echoCyan_n(){
    echo -n -e "\033[36m$*\033[0m"
}
echoWhite(){
    echo -e "\033[37m$*\033[0m"
}

message=""
farmid=""
use_ip_as_hostname="false"
use_public_ip_as_hostname="false"
force="false"
down_uri="https://minerx-download.oss-cn-shanghai.aliyuncs.com"
backup_down_uri="http://47.97.210.214:8889"


## 遍历参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --use_ip_as_hostname)
            use_ip_as_hostname="true"
            shift
            ;;
        --use_public_ip_as_hostname)
            use_public_ip_as_hostname="true"
            shift
            ;;
        --farmid)
            farmid="$2"
            shift 2 # 跳过参数和值
            ;;
        --force)
            force="true"
            shift
            ;;
        *)
            echo "未知选项: $1"
            exit 1
            ;;
    esac
done

## 获取显卡名称
isWSL="false"
if [[ $(systemd-detect-virt) == "wsl" ]]; then  ## 兼容 WSL 环境
    isWSL="true"
fi

in_container="false"
## 检查是否为容器环境
if [ -f /.dockerenv ] || grep -qE "docker|kubepods" /proc/1/cgroup || [[ ${isWSL} = "true" ]]; then
    echoCyan "Running inside Docker"
    in_container="true"
    apt update
    apt install -y iproute2 dmidecode lsb-release pciutils screen jq supervisor procps gettext libjansson-dev bc 
    apt install -y netcat
fi

##################################################################
## 检查依赖
##################################################################
if [ "$(id -u)" -ne 0 ]; then
    echoRed "请使用 root 用户安装"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    apt update
    apt install jq -y
fi

if ! command -v screen >/dev/null 2>&1; then
    apt update
    apt install screen -y
fi
if ! command -v dmidecode >/dev/null 2>&1; then
    apt update
    apt install dmidecode -y
fi






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
    rm -f "${archive}"

    # 下载并保存
    if wget -t 5 -T 20 -c "${url}" -P /tmp/; then
        echoCyan "下载成功: ${filename}"
        tar xzf ${archive} -C / || { echoYellow "Install failed!"; exit 1; }
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
## 如果没有指定 farmid, 并且配置文件不存在，则退出
if [[ -z ${farmid} ]] && [[ ! -f ${RIG_CONFIG} ]]; then
        echoYellow "Please specify farmid"
        exit 1
fi

## 强制安装 - 先停止服务
if [[ ${force} == 'true' ]]; then
    systemctl daemon-reload
    systemctl stop os-core.service
fi

## 如果指定了 farmid, 则进行重写安装
if [[ ! -z ${farmid} ]]; then
    [[ ! -f /os/config/rig.conf ]] && touch /os/config/rig.conf
    sed -i '/^farm_hash/d' /os/config/rig.conf
    echo "farm_hash=${farmid}" >> /os/config/rig.conf

    sed -i '/^worker_name/d' /os/config/rig.conf
    echo "worker_name=`hostname`" >> /os/config/rig.conf

    sed -i '/^server_url/d' /os/config/rig.conf
    echo 'server_url="http://47.97.210.214:8888"' >> /os/config/rig.conf
    echo 'server_url_domain="https://api.minerx.vip"' >> /os/config/rig.conf
fi


##################################################################
## Handle Hostname
##################################################################
## 使用外网 IP 作为主机名
if [[ ${use_public_ip_as_hostname} == 'true' ]]; then
    PUBLIC_IP=$(curl -s ifconfig.me)
fi


if [[ ${use_ip_as_hostname} == 'true' ]] || [[ ${use_public_ip_as_hostname} == 'true' ]]; then

    if [[ ${use_ip_as_hostname} == 'true' ]]; then
        IP=$(ip route get 8.8.8.8 | awk '{for (i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')
        IFS='.' read -r -a ip_parts <<< "$IP"
        for i in "${!ip_parts[@]}"; do
            ip_parts[$i]=$(printf "%03d" "${ip_parts[$i]}")
        done
        IP_STR="${ip_parts[2]}_${ip_parts[3]}"
    elif [[ ${use_public_ip_as_hostname} == 'true' ]]; then
        IP=$(curl -s ifconfig.me)
        IFS='.' read -r -a ip_parts <<< "$IP"
        for i in "${!ip_parts[@]}"; do
            ip_parts[$i]=$(printf "%03d" "${ip_parts[$i]}")
        done
        IP_STR="${ip_parts[0]}_${ip_parts[1]}_${ip_parts[2]}_${ip_parts[3]}"
    fi
    sed -i '/^worker_name/d' /os/config/rig.conf
    echo "worker_name=\"ip_${IP_STR}\"" >> /os/config/rig.conf
    message="Use ${IP_STR} as the hostname"
fi


##################################################################
## Add environment variables
##################################################################
NEW_PATH="/os/bin/"
BASHRC_FILE="/root/.bashrc"
sed -i "\|export PATH=.*${NEW_PATH}|d" ${BASHRC_FILE}
echo "export PATH=${NEW_PATH}:\$PATH" | tee -a ${BASHRC_FILE} > /dev/null

##################################################################
## ttyd
##################################################################
# 检查 ss 是否可用，不可用则尝试安装
if ! command -v ss >/dev/null 2>&1; then
    echo "🛠️ ss 不存在，尝试安装 iproute2..."
    if command -v apt >/dev/null 2>&1; then
        apt update && apt install -y iproute2
    fi
fi

# 再次检查 ss 是否可用
if command -v ss >/dev/null 2>&1; then
    if ss -lntp | grep -q ":4200"; then
        echo "ttyd is already running"
    else
        cp /os/service/os-ttyd.service /etc/systemd/system/

        if [[ ${in_container} != "true" ]] && [[ ${isWSL} != "true" ]]; then
            systemctl daemon-reload
            systemctl enable os-ttyd.service
            systemctl restart os-ttyd.service
        fi
    fi
fi

##################################################################
## Register to the server
##################################################################
/os/bin/say-hello register

##################################################################
## Install as a systemd service
##################################################################
## 根据是否在Docker中运行来安装服务
if [[ ${in_container} == "true" ]] || [[ ${isWSL} = "true" ]]; then
    echo "Running inside Docker Or WSL"
    # 创建必要的目录
    mkdir -p /var/log/os/

    # 创建 supervisor 配置文件
    echo "创建 supervisor 配置..."
    mkdir -p /etc/supervisor/conf.d/

    cat > /etc/supervisor/conf.d/say-hello.conf << 'EOF'
[program:say-hello]
command=bash -c 'while true; do /os/bin/say-hello; sleep 10; done'
user=root

autostart=true
autorestart=true
stopwaitsecs=60
startretries=100
stopasgroup=true
killasgroup=true

redirect_stderr=true
stdout_logfile=/var/log/os/say-hello.log
EOF

    cat > /etc/supervisor/conf.d/say-stats.conf << 'EOF'
[program:say-stats]
command=bash -c 'while true; do /os/bin/say-stats; sleep 10; done'
user=root

autostart=true
autorestart=true
stopwaitsecs=60
startretries=100
stopasgroup=true
killasgroup=true

redirect_stderr=true
stdout_logfile=/var/log/os/say-stats.log
EOF

    # 创建日志目录
    mkdir -p /var/log/os/
    
    # 启动 supervisor 服务
    echo "启动 supervisor 服务..."
    if pgrep -x "supervisord" > /dev/null; then
        echo "supervisor 已经在运行"
    else
        if [ -f /etc/init.d/supervisor ]; then
            /etc/init.d/supervisor start || true
        else
            service supervisor start || true
            # 如果上面的方法失败，尝试直接启动 supervisord
            supervisord -c /etc/supervisor/supervisord.conf || true
        fi
    fi

    # 等待几秒，确保服务启动
    sleep 3
    
    # 重新加载配置
    echo "加载 supervisor 配置..."
    supervisorctl reread || echo "无法读取配置，可能需要手动启动 supervisord"
    supervisorctl update || echo "无法更新配置，可能需要手动启动 supervisord"

    ## 设置 supervisor 自动启动
    sed -i "/^pgrep supervisord/d" /root/.bashrc
    echo 'pgrep supervisord >/dev/null || /usr/bin/supervisord -c /etc/supervisor/supervisord.conf' >> /root/.bashrc
    echo 'pgrep supervisord >/dev/null || /usr/bin/supervisord -c /etc/supervisor/supervisord.conf' >> /etc/profile
else
    cp /os/service/os-core.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable os-core.service
    systemctl restart os-core.service
fi

echoCyan "------------------------------------------------------------------ Installation successful. ${message}"
