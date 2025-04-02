#!/bin/bash

# 检查进程是否已存在
if pgrep -f "/os/bin/os-core-runner.sh" | grep -v $$ > /dev/null; then
    echo "已有 os-core-runner 守护进程在运行"
    exit 0
fi

# 循环运行 os-core
while true; do
    /os/bin/os-core
    sleep 10
done