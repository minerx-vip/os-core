#!/bin/bash

# 检查进程是否已存在
if pgrep -f "/os/bin/os-core-runner.sh" | grep -v $$ > /dev/null; then
    echo "已有 os-core-runner 守护进程在运行"
    exit 0
fi

# 日志路径
LOG_FILE="/var/log/os-core.log"

# 循环运行 os-core
while true; do
    echo "$(date) - 启动 os-core 服务..." >> $LOG_FILE
    /os/bin/os-core >> $LOG_FILE 2>&1
    echo "$(date) - os-core 服务退出，10秒后重启..." >> $LOG_FILE
    sleep 10
done