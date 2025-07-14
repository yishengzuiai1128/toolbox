#!/bin/bash

BACKUP_FILE="/etc/resolv.conf.bak"
RESOLV_CONF="/etc/resolv.conf"
SYSTEMD_RESOLVED_SERVICE="systemd-resolved.service"

DNS_SERVERS=(
  "1) Cloudflare 1.1.1.1"
  "2) Google DNS 8.8.8.8"
  "3) Quad9 9.9.9.9"
  "4) OpenDNS 208.67.222.222"
  "5) AdGuard DNS 94.140.14.14"
  "6) Custom DNS"
)

function check_dns_status() {
  echo "---- DNS 状态 ----"
  if systemctl is-active --quiet $SYSTEMD_RESOLVED_SERVICE; then
    echo "systemd-resolved 服务：正在运行"
  else
    echo "systemd-resolved 服务：未运行（这可能是正常的，具体视你是否使用了 systemd-resolved 管理DNS）"
  fi
  echo -e "/etc/resolv.conf 内容："
  cat $RESOLV_CONF
  echo "-------------------"
}

function backup_resolv_conf() {
  if [ -f "$BACKUP_FILE" ]; then
    echo "备份文件已存在：$BACKUP_FILE"
  else
    cp $RESOLV_CONF $BACKUP_FILE
    echo "已备份当前 $RESOLV_CONF 到 $BACKUP_FILE"
  fi
}

function restore_resolv_conf() {
  if [ -f "$BACKUP_FILE" ]; then
    cp $BACKUP_FILE $RESOLV_CONF
    echo "已恢复备份的 $RESOLV_CONF"
  else
    echo "未找到备份文件 $BACKUP_FILE，无法恢复"
  fi
}

function disable_systemd_resolved() {
  echo "正在禁用 systemd-resolved 服务..."
  systemctl disable --now $SYSTEMD_RESOLVED_SERVICE
  echo "禁用完成。"
}

function set_dns() {
  echo "请选择要设置的 DNS 服务器："
  for server in "${DNS_SERVERS[@]}"; do
    echo "$server"
  done
  read -rp "输入数字并回车: " choice
  case $choice in
    1) dns_ip="1.1.1.1" ;;
    2) dns_ip="8.8.8.8" ;;
    3) dns_ip="9.9.9.9" ;;
    4) dns_ip="208.67.222.222" ;;
    5) dns_ip="94.140.14.14" ;;
    6) 
      read -rp "请输入自定义 DNS IP 地址: " dns_ip
      ;;
    *)
      echo "无效选择，取消设置。"
      return
      ;;
  esac

  echo -e "nameserver $dns_ip\nnameserver 8.8.8.8" > $RESOLV_CONF
  echo "已将 /etc/resolv.conf 设置为使用 DNS 服务器：$dns_ip 和 8.8.8.8"
}

function test_network() {
  echo "开始测试网络连通性..."
  
  echo "Ping 1.1.1.1 ..."
  if ping -c 2 -W 2 1.1.1.1 >/dev/null 2>&1; then
    echo "Ping 1.1.1.1 成功"
  else
    echo "Ping 1.1.1.1 失败"
  fi
  
  echo "Ping 8.8.8.8 ..."
  if ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "Ping 8.8.8.8 成功"
  else
    echo "Ping 8.8.8.8 失败"
  fi
  
  echo "通过 curl 测试 https://www.google.com ..."
  if curl -Ik --connect-timeout 10 https://www.google.com >/dev/null 2>&1; then
    echo "curl 测试成功"
  else
    echo "curl 测试失败"
  fi
}

function check_local_proxy_status() {
  echo "本机代理功能状态检测（非VPS专用）"
  read -rp "请输入要检测的代理服务器IP或域名（默认 www.google.com）: " proxy_host
  proxy_host=${proxy_host:-www.google.com}

  echo "检测 $proxy_host 的网络连通性..."

  if ping -c 2 -W 2 "$proxy_host" >/dev/null 2>&1; then
    echo "Ping $proxy_host 成功"
  else
    echo "Ping $proxy_host 失败"
  fi

  if curl -Ik --connect-timeout 10 "https://$proxy_host" >/dev/null 2>&1; then
    echo "curl https://$proxy_host 测试成功"
  else
    echo "curl https://$proxy_host 测试失败"
  fi

  echo "请根据以上测试结果判断本机代理功能是否正常。"
}

while true; do
  check_dns_status

  echo "请选择操作："
  echo "1) 备份当前 /etc/resolv.conf"
  echo "2) 恢复 DNS 备份"
  echo "3) 禁用 systemd-resolved 服务"
  echo "4) 设置 DNS 服务器"
  echo "5) 测试网络连通性"
  echo "6) 本机代理功能状态检测（非VPS专用）"
  echo "7) 退出"
  read -rp "输入数字并回车: " action

  case $action in
    1) backup_resolv_conf ;;
    2) restore_resolv_conf ;;
    3) disable_systemd_resolved ;;
    4) set_dns ;;
    5) test_network ;;
    6) check_local_proxy_status ;;
    7) echo "退出脚本。"; exit 0 ;;
    *) echo "无效输入，请重新选择。" ;;
  esac

  echo ""
done
