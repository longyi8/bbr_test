#!/usr/bin/env bash
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[33m"
Cyan_font_prefix="\033[36m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"
copyright(){
    clear
echo "\
############################################################

  Linux 网络优化脚本 v2.0
  针对代理/隧道服务器深度调优
  By Longyi | https://github.com/longyi8

############################################################
"
}

# 清理 sysctl 中的旧条目
sysctl_clean() {
  for key in "$@"; do
    sed -i "/${key//./\\.}/d" /etc/sysctl.conf
  done
}

tcp_tune(){ # TCP 窗口 + 协议栈深度优化
echo -e "${Info} 开始 TCP 深度调优..."

sysctl_clean \
  net.ipv4.tcp_no_metrics_save \
  net.ipv4.tcp_ecn \
  net.ipv4.tcp_frto \
  net.ipv4.tcp_mtu_probing \
  net.ipv4.tcp_rfc1337 \
  net.ipv4.tcp_sack \
  net.ipv4.tcp_fack \
  net.ipv4.tcp_window_scaling \
  net.ipv4.tcp_adv_win_scale \
  net.ipv4.tcp_moderate_rcvbuf \
  net.ipv4.tcp_rmem \
  net.ipv4.tcp_wmem \
  net.core.rmem_max \
  net.core.wmem_max \
  net.core.rmem_default \
  net.core.wmem_default \
  net.ipv4.udp_rmem_min \
  net.ipv4.udp_wmem_min \
  net.core.default_qdisc \
  net.ipv4.tcp_congestion_control \
  net.ipv4.tcp_fastopen \
  net.ipv4.tcp_slow_start_after_idle \
  net.ipv4.tcp_notsent_lowat \
  net.ipv4.tcp_tw_reuse \
  net.ipv4.tcp_max_tw_buckets \
  net.ipv4.tcp_fin_timeout \
  net.ipv4.tcp_keepalive_time \
  net.ipv4.tcp_keepalive_intvl \
  net.ipv4.tcp_keepalive_probes \
  net.ipv4.tcp_max_syn_backlog \
  net.ipv4.tcp_synack_retries \
  net.ipv4.tcp_syn_retries \
  net.ipv4.tcp_timestamps \
  net.ipv4.tcp_max_orphans \
  net.core.somaxconn \
  net.core.netdev_max_backlog \
  net.core.netdev_budget \
  net.core.netdev_budget_usecs

cat >> /etc/sysctl.conf << EOF

# ============ TCP 深度调优 (v2.0) ============
# --- BBR 拥塞控制 ---
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# --- 缓冲区 (64MB max, 适合高延迟长肥管道) ---
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.rmem_default=1048576
net.core.wmem_default=1048576
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192

# --- TCP 行为优化 ---
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=2
net.ipv4.tcp_frto=2
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=2
net.ipv4.tcp_moderate_rcvbuf=1
net.ipv4.tcp_timestamps=1

# --- 降延迟 ---
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_notsent_lowat=16384

# --- 连接回收 ---
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_max_tw_buckets=2000000
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_max_orphans=65536

# --- Keepalive (快速检测死连接) ---
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=3

# --- 握手队列 ---
net.ipv4.tcp_max_syn_backlog=65535
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_syn_retries=3
net.core.somaxconn=65535

# --- 网卡队列 ---
net.core.netdev_max_backlog=65535
net.core.netdev_budget=600
net.core.netdev_budget_usecs=20000
EOF
sysctl -p && sysctl --system
echo -e "${Info} TCP 调优完成"
}

conntrack_tune(){ # conntrack 优化 (高并发必备)
echo -e "${Info} 开始 conntrack 调优..."

# 先加载模块
modprobe nf_conntrack 2>/dev/null

sysctl_clean \
  net.netfilter.nf_conntrack_max \
  net.netfilter.nf_conntrack_buckets \
  net.netfilter.nf_conntrack_tcp_timeout_fin_wait \
  net.netfilter.nf_conntrack_tcp_timeout_time_wait \
  net.netfilter.nf_conntrack_tcp_timeout_close_wait \
  net.netfilter.nf_conntrack_tcp_timeout_established \
  net.netfilter.nf_conntrack_udp_timeout \
  net.netfilter.nf_conntrack_udp_timeout_stream \
  net.netfilter.nf_conntrack_icmp_timeout

cat >> /etc/sysctl.conf << EOF

# ============ Conntrack 优化 ============
net.netfilter.nf_conntrack_max=2000000
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=30
net.netfilter.nf_conntrack_tcp_timeout_time_wait=30
net.netfilter.nf_conntrack_tcp_timeout_close_wait=15
net.netfilter.nf_conntrack_tcp_timeout_established=7200
net.netfilter.nf_conntrack_udp_timeout=30
net.netfilter.nf_conntrack_udp_timeout_stream=60
net.netfilter.nf_conntrack_icmp_timeout=10
EOF

# 设置 hashsize = conntrack_max / 4
if [ -f /sys/module/nf_conntrack/parameters/hashsize ]; then
  echo 500000 > /sys/module/nf_conntrack/parameters/hashsize
fi

sysctl -p && sysctl --system
echo -e "${Info} conntrack 调优完成"
}

enable_forwarding(){ #开启内核转发
echo -e "${Info} 开启内核转发..."

sysctl_clean \
  net.ipv4.conf.all.route_localnet \
  net.ipv4.ip_forward \
  net.ipv4.conf.all.forwarding \
  net.ipv4.conf.default.forwarding \
  net.ipv6.conf.all.forwarding \
  net.ipv6.conf.default.forwarding

cat >> '/etc/sysctl.conf' << EOF

# ============ 内核转发 ============
net.ipv4.conf.all.route_localnet=1
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding=1
EOF
sysctl -p && sysctl --system
echo -e "${Info} 内核转发已开启 (IPv4 + IPv6)"
}

banping(){
sysctl_clean net.ipv4.icmp_echo_ignore_all net.ipv4.icmp_echo_ignore_broadcasts
cat >> '/etc/sysctl.conf' << EOF
net.ipv4.icmp_echo_ignore_all=1
net.ipv4.icmp_echo_ignore_broadcasts=1
EOF
sysctl -p && sysctl --system
echo -e "${Info} ICMP 已屏蔽"
}

unbanping(){
sed -i "s/net.ipv4.icmp_echo_ignore_all=1/net.ipv4.icmp_echo_ignore_all=0/g" /etc/sysctl.conf
sed -i "s/net.ipv4.icmp_echo_ignore_broadcasts=1/net.ipv4.icmp_echo_ignore_broadcasts=0/g" /etc/sysctl.conf
sysctl -p && sysctl --system
echo -e "${Info} ICMP 已开放"
}

ulimit_tune(){
echo -e "${Info} 开始系统资源限制调优..."

echo "1000000" > /proc/sys/fs/file-max
sed -i '/fs.file-max/d' /etc/sysctl.conf
cat >> '/etc/sysctl.conf' << EOF
fs.file-max=1000000
EOF

ulimit -SHn 1000000 && ulimit -c unlimited
cat > /etc/security/limits.conf << EOF
root     soft   nofile    1000000
root     hard   nofile    1000000
root     soft   nproc     1000000
root     hard   nproc     1000000
root     soft   core      1000000
root     hard   core      1000000
root     hard   memlock   unlimited
root     soft   memlock   unlimited

*     soft   nofile    1000000
*     hard   nofile    1000000
*     soft   nproc     1000000
*     hard   nproc     1000000
*     soft   core      1000000
*     hard   core      1000000
*     hard   memlock   unlimited
*     soft   memlock   unlimited
EOF

if ! grep -q "ulimit" /etc/profile; then
  sed -i '/ulimit -SHn/d' /etc/profile
  echo "ulimit -SHn 1000000" >>/etc/profile
fi

if [ -f /etc/pam.d/common-session ]; then
  if ! grep -q "pam_limits.so" /etc/pam.d/common-session; then
    echo "session required pam_limits.so" >>/etc/pam.d/common-session
  fi
fi

sed -i '/DefaultTimeoutStartSec/d' /etc/systemd/system.conf
sed -i '/DefaultTimeoutStopSec/d' /etc/systemd/system.conf
sed -i '/DefaultRestartSec/d' /etc/systemd/system.conf
sed -i '/DefaultLimitCORE/d' /etc/systemd/system.conf
sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
sed -i '/DefaultLimitNPROC/d' /etc/systemd/system.conf

cat >>'/etc/systemd/system.conf' <<EOF
[Manager]
DefaultTimeoutStopSec=30s
DefaultLimitCORE=infinity
DefaultLimitNOFILE=1000000
DefaultLimitNPROC=1000000
EOF

systemctl daemon-reload
echo -e "${Info} 系统资源限制调优完成"
}

one_click(){ # 一键全部优化
echo -e "${Tip} 即将执行一键全部优化 (TCP + Conntrack + 转发 + 资源限制)"
read -p "确认执行? [y/N]: " confirm
if [[ "$confirm" =~ ^[yY]$ ]]; then
  tcp_tune
  echo ""
  conntrack_tune
  echo ""
  enable_forwarding
  echo ""
  ulimit_tune
  echo ""
  echo -e "${Info} =========================================="
  echo -e "${Info} 一键优化全部完成!"
  echo -e "${Info} 建议重启系统使所有配置生效"
  echo -e "${Info} =========================================="
else
  echo -e "${Tip} 已取消"
fi
}

show_status(){ # 显示当前优化状态
echo -e "${Cyan_font_prefix}========== 当前网络参数 ==========${Font_color_suffix}"
echo -e "拥塞控制: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)"
echo -e "队列调度: $(sysctl -n net.core.default_qdisc 2>/dev/null)"
echo -e "TCP FastOpen: $(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null)"
echo -e "rmem_max: $(sysctl -n net.core.rmem_max 2>/dev/null) bytes"
echo -e "wmem_max: $(sysctl -n net.core.wmem_max 2>/dev/null) bytes"
echo -e "tcp_rmem: $(sysctl -n net.ipv4.tcp_rmem 2>/dev/null)"
echo -e "tcp_wmem: $(sysctl -n net.ipv4.tcp_wmem 2>/dev/null)"
echo -e "IP转发: $(sysctl -n net.ipv4.ip_forward 2>/dev/null)"
echo -e "conntrack_max: $(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null || echo 'N/A')"
echo -e "conntrack当前: $(cat /proc/net/nf_conntrack 2>/dev/null | wc -l || echo 'N/A')"
echo -e "文件描述符: $(ulimit -n)"
echo -e "ICMP: $([ $(sysctl -n net.ipv4.icmp_echo_ignore_all 2>/dev/null) -eq 1 ] && echo '已屏蔽' || echo '开放')"
echo -e "内核: $(uname -r)"
echo -e "${Cyan_font_prefix}==================================${Font_color_suffix}"
}

bbr(){
if uname -r | grep -qE "^[5-9]\.|^[1-9][0-9]"; then
    echo -e "${Info} 内核 $(uname -r)，BBR 已原生支持"
    sysctl -n net.ipv4.tcp_congestion_control
else
    echo -e "${Tip} 内核低于 5.x，需要升级..."
    wget -N "http://sh.nekoneko.cloud/bbr/bbr.sh" -O bbr.sh && bash bbr.sh
fi
}

Update_Shell(){
  wget -N "https://raw.githubusercontent.com/longyi8/bbr_test/main/tools.sh" -O tools.sh && chmod +x tools.sh && bash tools.sh
}

get_opsy() {
  [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
  [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
  [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

virt_check() {
  virtualx=$(dmesg 2>/dev/null)

  if command -v dmidecode &>/dev/null; then
    sys_manu=$(dmidecode -s system-manufacturer 2>/dev/null)
    sys_product=$(dmidecode -s system-product-name 2>/dev/null)
    sys_ver=$(dmidecode -s system-version 2>/dev/null)
  else
    sys_manu="" ; sys_product="" ; sys_ver=""
  fi

  if grep -qa docker /proc/1/cgroup 2>/dev/null; then
    virtual="Docker"
  elif grep -qa lxc /proc/1/cgroup 2>/dev/null; then
    virtual="Lxc"
  elif grep -qa container=lxc /proc/1/environ 2>/dev/null; then
    virtual="Lxc"
  elif [[ -f /proc/user_beancounters ]]; then
    virtual="OpenVZ"
  elif [[ "$virtualx" == *kvm-clock* ]] || [[ "$cname" == *KVM* ]] || [[ "$cname" == *QEMU* ]]; then
    virtual="KVM"
  elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
    virtual="VMware"
  elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
    virtual="Parallels"
  elif [[ "$virtualx" == *VirtualBox* ]]; then
    virtual="VirtualBox"
  elif [[ -e /proc/xen ]]; then
    virtual="Xen"
  elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
    virtual="Hyper-V"
  else
    virtual="Dedicated母鸡"
  fi
}

get_system_info() {
  cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
  opsy=$(get_opsy)
  arch=$(uname -m)
  kern=$(uname -r)
  virt_check
}

menu() {
  echo -e "\
${Green_font_prefix}0.${Font_color_suffix} 升级脚本
${Green_font_prefix}1.${Font_color_suffix} 安装 BBR 原版内核 (5.x+ 不需要)
${Green_font_prefix}2.${Font_color_suffix} TCP 窗口 + 协议栈深度调优
${Green_font_prefix}3.${Font_color_suffix} Conntrack 连接跟踪优化
${Green_font_prefix}4.${Font_color_suffix} 开启内核转发 (IPv4 + IPv6)
${Green_font_prefix}5.${Font_color_suffix} 系统资源限制调优
${Green_font_prefix}6.${Font_color_suffix} 屏蔽 ICMP  ${Green_font_prefix}7.${Font_color_suffix} 开放 ICMP
${Yellow_font_prefix}8.${Font_color_suffix} ⚡ 一键全部优化 (2+3+4+5)
${Cyan_font_prefix}9.${Font_color_suffix} 📊 查看当前优化状态
"
get_system_info
echo -e "当前系统: ${Font_color_suffix}$opsy ${Green_font_prefix}$virtual${Font_color_suffix} $arch ${Green_font_prefix}$kern${Font_color_suffix}
"

  read -p "请输入数字: " num
  case "$num" in
  0) Update_Shell ;;
  1) bbr ;;
  2) tcp_tune ;;
  3) conntrack_tune ;;
  4) enable_forwarding ;;
  5) ulimit_tune ;;
  6) banping ;;
  7) unbanping ;;
  8) one_click ;;
  9) show_status ;;
  *)
    clear
    echo -e "${Error}: 请输入正确数字 [0-9]"
    sleep 2s
    copyright
    menu
    ;;
  esac
}

copyright
menu
