#!/bin/bash

# 加载颜色库
source /os/bin/colors

# 检查进程是否已存在
if pgrep -f "/os/bin/os-core-runner.sh" | grep -v $$ > /dev/null; then
    echo "已有 os-core-runner 守护进程在运行"
    exit 0
fi

# 创建必要的目录
mkdir -p /var/log/os/

# 检查是否已有 os-core-master 会话
is_running=$(screen -ls | grep os-core-master | wc -l)
if [[ ${is_running} -eq 0 ]]; then
    echoCyan "创建 os-core-master screen 会话..."
    
    # 创建一个新的 screen 会话
    screen -S "os-core-master" -dm
    
    # 设置日志
    screen -S "os-core-master" -X logfile "/var/log/os/os-core-master.log"
    screen -S "os-core-master" -X log on
    
    # 在 screen 会话中启动循环脚本
    screen -S "os-core-master" -X screen bash -c "while true; do echo \"$(date) - 启动 os-core 服务...\"; /os/bin/os-core; echo \"$(date) - os-core 服务完成，30分钟后再次运行\"; sleep 1800; done"
    
    echoCyan "os-core-master 已启动，将每 30 分钟运行一次 os-core"
else
    echoCyan "os-core-master 已经在运行中"
fi

# 立即运行一次 os-core
echoCyan "立即运行一次 os-core..."
/os/bin/os-core

# 保持脚本运行，每小时检查一次 screen 会话是否存在
while true; do
    # 检查 os-core-master 会话是否存在
    is_running=$(screen -ls | grep os-core-master | wc -l)
    if [[ ${is_running} -eq 0 ]]; then
        echoYellow "检测到 os-core-master 会话不存在，重新启动..."
        
        # 创建一个新的 screen 会话
        screen -S "os-core-master" -dm
        
        # 设置日志
        screen -S "os-core-master" -X logfile "/var/log/os/os-core-master.log"
        screen -S "os-core-master" -X log on
        
        # 在 screen 会话中启动循环脚本
        screen -S "os-core-master" -X screen bash -c "while true; do echo \"$(date) - 启动 os-core 服务...\"; /os/bin/os-core; echo \"$(date) - os-core 服务完成，30分钟后再次运行\"; sleep 1800; done"
        
        echoCyan "os-core-master 已重新启动"
    fi
    
    # 每小时检查一次
    sleep 10
done