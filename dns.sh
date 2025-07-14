#!/bin/bash

# 脚本配置
BACKUP_FILE="/etc/resolv.conf.backup"
RESOLV_FILE="/etc/resolv.conf"

# 可选的 DNS 服务器列表
declare -A DNS_OPTIONS=(
  [1]="1.1.1.1 (Cloudflare)"
  [2]="8.8.8.8 (Google)"
  [3]="9.9.9.9 (Quad9)"
  [4]="223.5.5.5 (AliDNS)"
  [5]="114.114.114.114 (114DNS)"
  [6]="自定义"
)

# 检查 systemd-resolved 状态
check_dns_status() {
  echo "---- DNS 状态 ----"
  if systemctl is-active --quiet systemd-resolved; then
    echo "systemd-resolved 服务：运行中（已启用）"
  else
    echo "systemd-resolved 服务：未运行（已禁用）"
  fi
  echo "/etc/resolv.conf 内容："
  cat $RESOLV_FILE 2>/dev/null || echo "未找到 $RESOLV_FILE 文件"
  echo "-------------------"
}

# 备份 resolv.conf
backup_resolv() {
  if [ -f "$RESOLV_FILE" ]; then
    cp $RESOLV_FILE $BACKUP_FILE
    echo "已备份 $RESOLV_FILE 至 $BACKUP_FILE"
  else
    echo "$RESOLV_FILE 文件不存在，无法备份"
  fi
}

# 恢复 resolv.conf
restore_resolv() {
  if [ -f "$BACKUP_FILE" ]; then
    cp $BACKUP_FILE $RESOLV_FILE
    echo "已恢复 DNS 配置"
  else
    echo "未找到备份文件 $BACKUP_FILE"
  fi
}

# 禁用 systemd-resolved
disable_systemd_resolved() {
  systemctl disable --now systemd-resolved
  echo "已禁用并关闭 systemd-resolved"
}

# 启用 systemd-resolved
enable_systemd_resolved() {
  systemctl enable --now systemd-resolved
  echo "已启用并启动 systemd-resolved"
}

# 设置 DNS
set_dns() {
  echo "请选择要设置的 DNS："
  for key in "${!DNS_OPTIONS[@]}"; do
    echo "$key) ${DNS_OPTIONS[$key]}"
  done

  read -p "输入编号: " dns_choice

  if [[ "$dns_choice" == "6" ]]; then
    read -p "请输入自定义 DNS 地址（多个用空格隔开）: " custom_dns
    dns_addresses=$custom_dns
  else
    case "$dns_choice" in
      1) dns_addresses="1.1.1.1 1.0.0.1" ;;
      2) dns_addresses="8.8.8.8 8.8.4.4" ;;
      3) dns_addresses="9.9.9.9 149.112.112.112" ;;
      4) dns_addresses="223.5.5.5 223.6.6.6" ;;
      5) dns_addresses="114.114.114.114 114.114.115.115" ;;
      *) echo "无效输入"; return ;;
    esac
  fi

  rm -f $RESOLV_FILE
  for ip in $dns_addresses; do
    echo "nameserver $ip" >> $RESOLV_FILE
  done
  echo "DNS 已设置为：$dns_addresses"
}

# 网络连通性测试
test_network() {
  echo "测试网络连通性..."
  echo "ping 1.1.1.1 ..."
  if ping -c 2 -W 2 1.1.1.1 > /dev/null; then
    echo "Ping 1.1.1.1 成功"
  else
    echo "Ping 1.1.1.1 失败"
  fi

  echo "ping 8.8.8.8 ..."
  if ping -c 2 -W 2 8.8.8.8 > /dev/null; then
    echo "Ping 8.8.8.8 成功"
  else
    echo "Ping 8.8.8.8 失败"
  fi

  echo "curl https://www.google.com -I ..."
  if curl -I --connect-timeout 5 https://www.google.com 2>&1 | grep -q "HTTP/"; then
    echo "curl 测试成功"
  else
    echo "curl 测试失败，可能被墙或 DNS 被污染"
  fi
}

# 本机代理功能状态检测
check_local_proxy() {
  echo "本机代理功能状态检测（非VPS专用）..."
  if curl -I --connect-timeout 5 https://www.google.com 2>&1 | grep -q "HTTP/"; then
    echo "代理功能正常（能访问 Google）"
  else
    echo "代理功能异常（无法访问 Google）"
  fi
}

# DNS 响应延迟测试
test_dns_latency() {
  echo "DNS 响应延迟测试："
  declare -A dns_latency

  for key in "${!DNS_OPTIONS[@]}"; do
    [[ "$key" == "6" ]] && continue
    ip=$(echo "${DNS_OPTIONS[$key]}" | grep -oE '^[0-9.]+')
    latency=$(dig +stats +timeout=2 @"$ip" www.google.com | grep "Query time" | awk '{print $4}')
    latency=${latency:-超时}
    echo "$ip => $latency ms"
  done
}

# 主菜单
while true; do
  check_dns_status
  echo "请选择操作："
  echo "1) 备份当前 /etc/resolv.conf"
  echo "2) 恢复 DNS 备份"
  echo "3) 禁用 systemd-resolved"
  echo "4) 启用 systemd-resolved"
  echo "5) 设置 DNS（支持多种）"
  echo "6) 测试网络连通性"
  echo "7) 本机代理功能状态检测（非VPS专用）"
  echo "8) 测试 DNS 延迟"
  echo "9) 退出"
  read -p "输入数字并回车: " choice

  case $choice in
    1) backup_resolv ;;
    2) restore_resolv ;;
    3) disable_systemd_resolved ;;
    4) enable_systemd_resolved ;;
    5) set_dns ;;
    6) test_network ;;
    7) check_local_proxy ;;
    8) test_dns_latency ;;
    9) echo "退出"; break ;;
    *) echo "无效输入" ;;
  esac

  echo ""
  read -p "按回车键继续..." temp
done
