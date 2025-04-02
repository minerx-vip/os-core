#!/bin/bash

# 加载颜色库
source /os/bin/colors

# 创建必要的目录
mkdir -p /var/log/os/

# 清理所有 Dead 状态的 screen 会话
echoCyan "清理旧的 screen 会话..."
screen -wipe > /dev/null 2>&1

# 清理所有现有的 os-core-master 会话
if screen -ls | grep -q "os-core-master"; then
    echoCyan "结束旧的 os-core-master 会话..."
    screen -S "os-core-master" -X quit > /dev/null 2>&1
    sleep 1
fi

# 清理所有现有的 say-hello 和 say-stats 会话
if screen -ls | grep -q "say-hello"; then
    echoCyan "结束旧的 say-hello 会话..."
    screen -S "say-hello" -X quit > /dev/null 2>&1
fi

if screen -ls | grep -q "say-stats"; then
    echoCyan "结束旧的 say-stats 会话..."
    screen -S "say-stats" -X quit > /dev/null 2>&1
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