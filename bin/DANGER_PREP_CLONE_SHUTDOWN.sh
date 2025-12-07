#!/bin/bash

## 如果发现退出码为1则停止运行
# set -o errexit
set -e
## 如果发现空的变量则停止运行
# set -o nounset
set -u


echo "⚠️ 警告：执行此脚本后，将停止当前所有服务和挖矿程序，并在执行完成后自动关机。"
echo "⚠️ 在将此系统克隆到其他机器之前，请确保本机无法正常启动，否则克隆结果将无效。"
echo ""
echo "⏳ 5 秒后开始执行操作，按 Ctrl+C 取消..."
for i in {5..1}; do
    echo -n "$i "
    sleep 1
done
echo ""
echo "开始执行..."


## 启用自动开机并停止当前
systemctl enable os-core.service
systemctl stop os-core.service

## 准备配置文件
cd /os/config
grep -E 'farm_hash|server_url_domain|server_url|down_uri_ip' rig.conf > linshi.conf && mv linshi.conf rig.conf
conf_lines=$(wc -l < rig.conf)
if [[ $conf_lines -ne 3 ]]; then
    echo "❌ 配置文件行数错误，应为3行，当前为 $conf_lines 行"
    exit 1
fi
echo "✅ 配置检查通过, 即将关机..."
sleep 3
poweroff