#!/bin/bash

# 加载颜色库
source /os/bin/colors

# 创建必要的目录
mkdir -p /var/log/os/

# 检查是否已有 os-core-master 会话
is_running=$(screen -ls | grep os-core-master | wc -l)
if [[ ${is_running} -gt 0 ]]; then
    echoCyan "os-core-master 已经在运行中，不需要再次启动"
    exit 0
fi

# 创建一个新的 screen 会话
echoCyan "创建 os-core-master screen 会话..."
screen -S "os-core-master" -dm

# 设置日志
screen -S "os-core-master" -X logfile "/var/log/os/os-core-master.log"
screen -S "os-core-master" -X log on

# 在 screen 会话中启动循环脚本
screen -S "os-core-master" -X screen bash -c "while true; do 
    echo \"$(date) - 启动 os-core 服务...\" 
    /os/bin/os-core 
    echo \"$(date) - os-core 服务完成，10秒后再次运行\" 
    sleep 10 
done"

echoCyan "os-core-master 已启动，将定期运行 os-core"