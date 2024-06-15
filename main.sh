#!/bin/bash

# 检查用户权限
if [ $(whoami) != "root" ]; then
  echo "请使用 root 用户运行此脚本。"
  exit 1
fi

# 检查并安装 WireGuard
check_and_install_wireguard() {
  if ! command -v wg &> /dev/null; then
    echo "未检测到 WireGuard，正在安装..."
    apt update && apt install -y wireguard
    echo "WireGuard 安装完成。"
  else
    echo "WireGuard 已安装。"
  fi
}

# 展示所有隧道信息
show_tunnels() {
  echo "当前 WireGuard 隧道信息："
  wg show
}

# 创建新隧道
create_tunnel() {
  # 检测当前目录是否存在WireGuard的publickey和privatekey文件
  if [ ! -f "./privatekey" ] || [ ! -f "./publickey" ]; then
    # 如果不存在则创建
    wg genkey | tee privatekey | wg pubkey > publickey
    echo "没有检测到wireguard密钥文件，正在创建中"
  else
    echo "检测到密钥文件，正在读取。"
  fi

  privatekey_content=$(<privatekey)

  # 询问用户输入WireGuard配置文件名
  read -p "请输入要创建的WireGuard配置文件名（完整文件名，包括后缀）：" config_file

  # 检查文件名是否包含非法字符
  if [[ $config_file =~ [^a-zA-Z0-9_\-\.]+ ]]; then
    echo "文件名包含非法字符，请重新输入。"
    return
  fi

  # 询问用户输入服务器IP和端口
  read -p "请输入服务器IP地址：" server_ip
  read -p "请输入服务器端口号：" server_port
  read -p "请输入隧道本地IP地址：" local_ip
  read -p "请输入本地服务端口号：" local_port
  read -p "请输入对方wireguard公钥：" peer_public_key

  # 验证对方 WireGuard 公钥
  if ! echo "$peer_public_key" | wg pubkey > /dev/null 2>&1; then
    echo "无效的 WireGuard 公钥，请检查并重新输入。"
    return
  fi

  while true; do
    # 显示配置信息
    echo "请确认以下配置信息是否正确："
    echo "配置文件名: $config_file"
    echo "服务器IP地址: $server_ip"
    echo "服务器端口号: $server_port"
    echo "隧道本地IP地址: $local_ip"
    echo "本地服务端口号: $local_port"
    echo "对方WireGuard公钥: $peer_public_key"
    
    read -p "以上信息是否正确？(y/n): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
      # 生成配置文件内容
      config_data="[Interface]\nPrivateKey = $privatekey_content\nAddress = $local_ip/24\nListenPort = $local_port\n\n[Peer]\nPublicKey = $peer_public_key\nAllowedIPs = 0.0.0.0/0,::/0\nEndpoint = $server_ip:$server_port"

      # 将配置文件内容写入到文件
      echo -e $config_data > $config_file
      echo "WireGuard配置文件已生成并保存到 $config_file"

      # 启用并启动 WireGuard 配置
      systemctl enable $config_file@wg-quick
      systemctl start $config_file@wg-quick

      echo "WireGuard隧道已启动"
      break
    else
      # 询问用户需要修改哪项配置
      echo "请选择需要修改的项："
      echo "1) 配置文件名"
      echo "2) 服务器IP地址"
      echo "3) 服务器端口号"
      echo "4) 隧道本地IP地址"
      echo "5) 本地服务端口号"
      echo "6) 对方WireGuard公钥"
      read -p "请输入对应的数字: " option
      case $option in
        1)
          read -p "请输入新的配置文件名（完整文件名，包括后缀）：" config_file
          if [[ $config_file =~ [^a-zA-Z0-9_\-\.]+ ]]; then
            echo "文件名包含非法字符，请重新输入。"
          fi
          ;;
        2)
          read -p "请输入新的服务器IP地址：" server_ip
          ;;
        3)
          read -p "请输入新的服务器端口号：" server_port
          ;;
        4)
          read -p "请输入新的隧道本地IP地址：" local_ip
          ;;
        5)
          read -p "请输入新的本地服务端口号：" local_port
          ;;
        6)
          read -p "请输入新的对方WireGuard公钥：" peer_public_key
          if ! echo "$peer_public_key" | wg pubkey > /dev/null 2>&1; then
            echo "无效的 WireGuard 公钥，请检查并重新输入。"
          fi
          ;;
        *)
          echo "无效的选项，请重新选择。"
          ;;
      esac
    fi
  done
}

# 生成并打印公私钥
generate_and_print_keys() {
  private_key=$(wg genkey)
  public_key=$(echo "$private_key" | wg pubkey)
  echo "生成的私钥: $private_key"
  echo "生成的公钥: $public_key"
}

# 主菜单
clear_screen() {
    printf "\033c"
}

# 函数：居中输出文本
center_text() {
    local text="$1"
    local term_width=$(tput cols)
    local padding=$(( ($term_width - ${#text}) / 2 ))
    printf "%*s%s\n" $padding "" "$text"
}

while true; do
    clear_screen
    center_text "\033[1;33m=== 欢迎使用WireGuard管理脚本 ===\033[0m"
    echo -e "\033[0;34mversion: v1.0\033[0m"
    echo -e "\033[0;34mrepo link: https://github.com/sam13142023/Wireguard-shell\033[0m"
    echo ""
    echo "请选择你所需的功能:"
    echo "1) 检查并安装 WireGuard"
    echo "2) 展示所有隧道信息"
    echo "3) 创建新隧道"
    echo "4) 生成并打印公私钥"
    echo "5) 退出脚本"
    read -p "请输入对应的数字: " choice
    case $choice in
        1)
            check_and_install_wireguard
            ;;
        2)
            show_tunnels
            ;;
        3)
            create_tunnel
            ;;
        4)
            generate_and_print_keys
            ;;
        5)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo "无效的选项，请重新选择。"
            ;;
    esac
    read -p "按 Enter 继续..."
done
