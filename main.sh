#!/bin/bash

# 检查用户权限
if [ $(whoami) != "root" ]; then
  echo "请使用 root 用户运行此脚本。 / Please run this script as root."
  exit 1
fi

# 检查并安装 WireGuard
check_and_install_wireguard() {
  if ! command -v wg &> /dev/null; then
    echo "未检测到 WireGuard，正在安装... / WireGuard not detected, installing..."
     #自动检测操作系统，并根据不同的操作系统进行不同的安装操作
    if [ -f /etc/debian_version ]; then
      apt-get update
      apt-get install -y wireguard
    elif [ -f /etc/redhat-release ]; then
      yum install -y epel-release
      yum install -y wireguard-tools
    else
      echo "无法识别的操作系统。 / Unrecognized operating system."
      exit 1
    fi

    if ! command -v wg &> /dev/null; then
      echo "WireGuard安装失败。请检查日志以解决问题。 / WireGuard installation failed. Please check the logs to resolve the issue."
      exit 1
    else
      echo "WireGuard已成功安装。 / WireGuard has been successfully installed."
    fi
  else
    echo "检测到已安装的 WireGuard。 / Detected already installed WireGuard."
  fi
}

# 展示所有隧道信息
show_tunnels() {
  echo "当前 WireGuard 隧道信息： / Current WireGuard tunnels:"
  wg show
}

# 创建新隧道
create_tunnel() {
  # 检测当前目录是否存在WireGuard的publickey和privatekey文件
  if [ ! -f "./privatekey" ] || [ ! -f "./publickey" ]; then
    # 如果不存在则创建
    wg genkey | tee privatekey | wg pubkey > publickey
    echo "没有检测到wireguard密钥文件，正在创建中 / No WireGuard key files detected, creating..."
  else
    echo "检测到密钥文件，正在读取。 / Key files detected, reading..."
  fi

  privatekey_content=$(<privatekey)

  # 询问用户输入WireGuard配置文件名
  read -p "请输入要创建的WireGuard配置文件名（完整文件名，包括后缀）：" config_file

  # 检查文件名是否包含非法字符
  if [[ $config_file =~ [^a-zA-Z0-9_\-\.]+ ]]; then
    echo "文件名包含非法字符，请重新输入。 / Filename contains illegal characters, please re-enter."
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
    echo "无效的 WireGuard 公钥，请检查并重新输入。 / Invalid WireGuard public key, please check and re-enter."
    return
  fi

  while true; do
    # 显示配置信息
    echo -n "请确认以下配置信息是否正确 / Please confirm if the following configuration information is correct:"
    echo "："
    echo -n "配置文件名 / File name: $config_file"
    echo " / $config_file"
    echo -n "服务器IP地址 / Server IP address: $server_ip"
    echo " / $server_ip"
    echo -n "服务器端口号 / Server port: $server_port"
    echo " / $server_port"
    echo -n "隧道本地IP地址 / Local tunnel IP address: $local_ip"
    echo " / $local_ip"
    echo -n "本地服务端口号 / Local service port: $local_port"
    echo " / $local_port"
    echo -n "对方WireGuard公钥 / Peer WireGuard public key: $peer_public_key"
    echo " / $peer_public_key"
    
    read -p "以上信息是否正确？(y/n): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
      # 生成配置文件内容
      config_data="[Interface]\nPrivateKey = $privatekey_content\nAddress = $local_ip/24\nListenPort = $local_port\n\n[Peer]\nPublicKey = $peer_public_key\nAllowedIPs = 0.0.0.0/0,::/0\nEndpoint = $server_ip:$server_port"
      # 将配置文件内容写入到文件
      config_file_path="/etc/wireguard/${config_file}"
      echo -e "$config_data" > "$config_file_path"
      # 检查配置文件是否存在
      if [ -f "$config_file_path" ]; then
        echo "WireGuard 配置文件已成功写入到 /etc/wireguard/ 目录下。"
      else
        echo "WireGuard 配置文件写入失败，请检查权限和磁盘空间。"
        return 1
      fi
      # 启用并启动 WireGuard 配置
      systemctl enable "${config_file}@wg-quick"
      systemctl start "${config_file}@wg-quick"
      echo "WireGuard 隧道已启动 / WireGuard tunnel started"

      break
    else
      # 询问用户需要修改哪项配置
      echo "请选择需要修改的项： / Please select which item you would like to modify:"
      echo "1) 配置文件名 / Configuration file name"
      echo "2) 服务器IP地址 / Server IP address"
      echo "3) 服务器端口号 / Server port"
      echo "4) 隧道本地IP地址 / Local tunnel IP address"
      echo "5) 本地服务端口号 / Local service port"
      echo "6) 对方WireGuard公钥 / Peer WireGuard public key"
      read -p "请输入对应的数字: " option

      case $option in
        1)
          read -p "请输入新的配置文件名（完整文件名，包括后缀）：" config_file
          if [[ $config_file =~ [^a-zA-Z0-9_\-\.]+ ]]; then
            echo "文件名包含非法字符，请重新输入。 / Filename contains illegal characters, please re-enter."
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
            echo "无效的 WireGuard 公钥，请检查并重新输入。 / Invalid WireGuard public key, please check and re-enter."
          fi
          ;;
        *)
          echo "无效的选项，请重新选择。 / Invalid option, please choose again."
          ;;
      esac
    fi
  done
}


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
update() {
  # 获取最新版本脚本
  curl -L https://github.com/sam13142023/Wireguard-shell/raw/main/main.sh -o wireguard.sh.tmp

  # 检查版本
  if [[ $? -ne 0 ]]; then
    echo "获取最新脚本失败！"
    return 1
  fi

  # 比较版本
  local current_version=$(grep "version: v" wireguard.sh | awk '{print $2}')
  local new_version=$(grep "version: v" wireguard.sh.tmp | awk '{print $2}')

  if [[ "$current_version" < "$new_version" ]]; then 
    # 版本不同，更新脚本
    mv wireguard.sh.tmp wireguard.sh
    echo "脚本已更新！/ Upgrade Successfully"
  else
    echo "脚本已经是最新版本。/ Shell already at the newest version "
    rm wireguard.sh.tmp
  fi
}
generate_and_print_keys() {
  private_key=$(wg genkey)
  public_key=$(echo "$private_key" | wg pubkey)
  echo "生成的私钥: $private_key"
  echo "生成的公钥: $public_key"
}
# 主菜单
while true; do
    clear_screen
    center_text "=== 欢迎使用WireGuard管理脚本 / Welcome to the WireGuard Management Script ==="
    echo -e "\033[0;34mversion: v1.1.1 \033[0m"
    echo -e "\033[0;34mrepo link: https://github.com/sam13142023/Wireguard-shell \033[0m"
    echo "1) 检查并安装 WireGuard / Check and install WireGuard"
    echo "2) 展示所有隧道信息 / Show all tunnels information"
    echo "3) 创建新隧道 / Create a new tunnel"
    echo "4) 生成并打印公私钥 / Generate and print public and private keys"
    echo "5) 更新脚本 / Upgrade the shell"
    echo "6) 退出 / Exit"
    read -p "请选择操作（输入数字）： / Select an option (enter a number): " choice

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
        update
        ;;
      6)
        echo "感谢使用，再见！ / Thank you for using the script. Goodbye!"
        exit 0
        ;;
      *)
        echo "无效的选项，请重新选择。 / Invalid option, please choose again."
        ;;
    esac

    read -p "按 Enter 键继续... / Press Enter to continue..."
done
