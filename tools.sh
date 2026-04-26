#!/usr/bin/env bash
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[33m"
Cyan_font_prefix="\033[36m"
Blue_font_prefix="\033[34m"
Purple_font_prefix="\033[35m"
White_font_prefix="\033[37m"
Bold_prefix="\033[1m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"
copyright(){
    clear
echo "\
############################################################

  Linux 网络优化脚本 v3.0
  针对代理/隧道服务器深度调优
  新增: 自动环境检测 + 智能自适应优化
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

# ============================================================
# v3.0 新增: 环境检测函数
# ============================================================

# 检测单个目标的 RTT (返回毫秒数, 失败返回 -1)
_ping_one() {
  local ip="$1"
  local result
  result=$(ping -c 3 -W 3 "$ip" 2>/dev/null | awk -F'/' '/avg/{print $5}')
  if [[ -n "$result" ]]; then
    printf "%.1f" "$result"
  else
    echo "-1"
  fi
}

# 检测 RTT — 设置全局变量 RTT_RESULTS (关联数组) 和 RTT_AVG (平均值)
detect_rtt() {
  declare -gA RTT_RESULTS
  local total=0 count=0

  local -A targets=(
    ["北京电信"]="219.141.136.10"
    ["北京联通"]="202.106.50.1"
    ["北京移动"]="221.179.155.161"
    ["东京CF"]="1.1.1.1"
    ["洛杉矶CF"]="198.41.200.12"
    ["法兰克福CF"]="1.0.0.1"
  )

  local order=("北京电信" "北京联通" "北京移动" "东京CF" "洛杉矶CF" "法兰克福CF")

  for name in "${order[@]}"; do
    local ip="${targets[$name]}"
    local rtt
    rtt=$(_ping_one "$ip")
    RTT_RESULTS["$name"]="$rtt"
    if [[ "$rtt" != "-1" ]]; then
      total=$(echo "$total + $rtt" | bc 2>/dev/null || awk "BEGIN{print $total + $rtt}")
      count=$((count + 1))
    fi
  done

  if [[ $count -gt 0 ]]; then
    RTT_AVG=$(awk "BEGIN{printf \"%.1f\", $total / $count}")
  else
    RTT_AVG="-1"
  fi
}

# 检测带宽 — 设置全局变量 NIC_NAME, NIC_SPEED_MBPS
detect_bandwidth() {
  # 找到默认路由网卡
  NIC_NAME=$(ip route show default 2>/dev/null | awk '/default/{print $5; exit}')
  [[ -z "$NIC_NAME" ]] && NIC_NAME=$(ls /sys/class/net/ | grep -v lo | head -1)

  NIC_SPEED_MBPS=1000  # 默认 1Gbps

  # 方法1: ethtool
  if command -v ethtool &>/dev/null && [[ -n "$NIC_NAME" ]]; then
    local speed
    speed=$(ethtool "$NIC_NAME" 2>/dev/null | awk '/Speed:/{gsub(/[^0-9]/,"",$2); print $2}')
    if [[ -n "$speed" && "$speed" -gt 0 ]] 2>/dev/null; then
      NIC_SPEED_MBPS="$speed"
      return
    fi
  fi

  # 方法2: /sys/class/net
  if [[ -f "/sys/class/net/${NIC_NAME}/speed" ]]; then
    local speed
    speed=$(cat "/sys/class/net/${NIC_NAME}/speed" 2>/dev/null)
    if [[ -n "$speed" && "$speed" -gt 0 ]] 2>/dev/null; then
      NIC_SPEED_MBPS="$speed"
      return
    fi
  fi

  # 方法3: 虚拟机常见速率估算
  if [[ -d "/sys/class/net/${NIC_NAME}" ]]; then
    # virtio 等虚拟网卡无 speed, 默认 1Gbps
    NIC_SPEED_MBPS=1000
  fi
}

# 检测内存 — 设置全局变量 MEM_TOTAL_BYTES, MEM_TOTAL_MB, MEM_TOTAL_GB
detect_memory() {
  MEM_TOTAL_BYTES=$(free -b 2>/dev/null | awk '/Mem:/{print $2}')
  [[ -z "$MEM_TOTAL_BYTES" ]] && MEM_TOTAL_BYTES=$(awk '/MemTotal/{print $2*1024}' /proc/meminfo 2>/dev/null)
  [[ -z "$MEM_TOTAL_BYTES" ]] && MEM_TOTAL_BYTES=0

  MEM_TOTAL_MB=$((MEM_TOTAL_BYTES / 1024 / 1024))
  MEM_TOTAL_GB=$(awk "BEGIN{printf \"%.1f\", $MEM_TOTAL_BYTES / 1024 / 1024 / 1024}")
}

# 检测 CPU — 设置全局变量 CPU_CORES
detect_cpu() {
  CPU_CORES=$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)
}

# 综合检测并彩色输出
detect_environment() {
  echo -e "${Info} 开始环境检测，请稍候..."
  echo ""

  detect_cpu
  detect_memory
  detect_bandwidth
  detect_rtt

  # --- 彩色表格输出 ---
  local line="${Cyan_font_prefix}╔══════════════════════════════════════════════════════╗${Font_color_suffix}"
  local line2="${Cyan_font_prefix}╠══════════════════════════════════════════════════════╣${Font_color_suffix}"
  local line3="${Cyan_font_prefix}╚══════════════════════════════════════════════════════╝${Font_color_suffix}"

  echo -e "$line"
  echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Bold_prefix}${Green_font_prefix}🖥  系统环境检测结果${Font_color_suffix}                              ${Cyan_font_prefix}║${Font_color_suffix}"
  echo -e "$line2"

  # CPU
  echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Yellow_font_prefix}CPU 核数${Font_color_suffix}      : ${Bold_prefix}${CPU_CORES}${Font_color_suffix} 核                                  ${Cyan_font_prefix}║${Font_color_suffix}"

  # 内存
  local mem_color="${Green_font_prefix}"
  if [[ $MEM_TOTAL_MB -lt 1024 ]]; then
    mem_color="${Red_font_prefix}"
  elif [[ $MEM_TOTAL_MB -lt 4096 ]]; then
    mem_color="${Yellow_font_prefix}"
  fi
  echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Yellow_font_prefix}内存${Font_color_suffix}          : ${mem_color}${Bold_prefix}${MEM_TOTAL_GB} GB${Font_color_suffix} (${MEM_TOTAL_MB} MB)                    ${Cyan_font_prefix}║${Font_color_suffix}"

  # 网卡
  echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Yellow_font_prefix}网卡${Font_color_suffix}          : ${Bold_prefix}${NIC_NAME}${Font_color_suffix} @ ${Green_font_prefix}${NIC_SPEED_MBPS} Mbps${Font_color_suffix}                   ${Cyan_font_prefix}║${Font_color_suffix}"

  echo -e "$line2"
  echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Bold_prefix}${Green_font_prefix}🌐 RTT 延迟测试${Font_color_suffix}                                    ${Cyan_font_prefix}║${Font_color_suffix}"
  echo -e "$line2"

  local order=("北京电信" "北京联通" "北京移动" "东京CF" "洛杉矶CF" "法兰克福CF")
  local -A ips=(
    ["北京电信"]="219.141.136.10"
    ["北京联通"]="202.106.50.1"
    ["北京移动"]="221.179.155.161"
    ["东京CF"]="1.1.1.1"
    ["洛杉矶CF"]="198.41.200.12"
    ["法兰克福CF"]="1.0.0.1"
  )

  for name in "${order[@]}"; do
    local rtt="${RTT_RESULTS[$name]}"
    local ip="${ips[$name]}"
    local rtt_color="${Green_font_prefix}"
    local rtt_display="${rtt} ms"
    if [[ "$rtt" == "-1" ]]; then
      rtt_color="${Red_font_prefix}"
      rtt_display="超时"
    elif (( $(echo "$rtt > 150" | bc 2>/dev/null || awk "BEGIN{print ($rtt>150)}") )); then
      rtt_color="${Red_font_prefix}"
    elif (( $(echo "$rtt > 30" | bc 2>/dev/null || awk "BEGIN{print ($rtt>30)}") )); then
      rtt_color="${Yellow_font_prefix}"
    fi
    printf "  ${Cyan_font_prefix}║${Font_color_suffix}  %-10s %-16s ${rtt_color}%8s${Font_color_suffix}            ${Cyan_font_prefix}║${Font_color_suffix}\n" "$name" "$ip" "$rtt_display"
  done

  echo -e "$line2"

  # RTT 分级
  local rtt_level rtt_level_color
  if [[ "$RTT_AVG" == "-1" ]]; then
    rtt_level="无法检测"
    rtt_level_color="${Red_font_prefix}"
  elif (( $(echo "$RTT_AVG < 30" | bc 2>/dev/null || awk "BEGIN{print ($RTT_AVG<30)}") )); then
    rtt_level="低延迟 (<30ms) — 本地/近距离"
    rtt_level_color="${Green_font_prefix}"
  elif (( $(echo "$RTT_AVG < 150" | bc 2>/dev/null || awk "BEGIN{print ($RTT_AVG<150)}") )); then
    rtt_level="中延迟 (30-150ms) — 亚太区域"
    rtt_level_color="${Yellow_font_prefix}"
  else
    rtt_level="高延迟 (>150ms) — 跨洲际"
    rtt_level_color="${Red_font_prefix}"
  fi

  echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Yellow_font_prefix}平均 RTT${Font_color_suffix}      : ${Bold_prefix}${RTT_AVG} ms${Font_color_suffix}                              ${Cyan_font_prefix}║${Font_color_suffix}"
  echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Yellow_font_prefix}延迟分级${Font_color_suffix}      : ${rtt_level_color}${rtt_level}${Font_color_suffix}  ${Cyan_font_prefix}║${Font_color_suffix}"

  # 内存分级
  local mem_level
  if [[ $MEM_TOTAL_MB -lt 1024 ]]; then
    mem_level="小内存 (<1GB) — 缓冲区封顶 16MB"
  elif [[ $MEM_TOTAL_MB -lt 4096 ]]; then
    mem_level="中内存 (1-4GB) — 缓冲区封顶 64MB"
  else
    mem_level="大内存 (>4GB) — 缓冲区最高 128MB"
  fi
  echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Yellow_font_prefix}内存分级${Font_color_suffix}      : ${mem_color}${mem_level}${Font_color_suffix}  ${Cyan_font_prefix}║${Font_color_suffix}"

  echo -e "$line3"
  echo ""
}

# ============================================================
# v3.0 新增: 智能一键优化
# ============================================================

smart_optimize() {
  echo -e "${Info} 🧠 智能一键优化: 先检测环境，再自适应配置"
  echo ""

  # Step 1: 检测环境
  detect_environment

  # Step 2: 计算最佳参数
  echo -e "${Info} 正在根据检测结果计算最佳参数..."

  # --- 内存分级: 确定缓冲区上限 ---
  local buf_max_bytes
  if [[ $MEM_TOTAL_MB -lt 1024 ]]; then
    buf_max_bytes=$((16 * 1024 * 1024))    # 16MB
    echo -e "  内存 < 1GB → 缓冲区封顶 ${Yellow_font_prefix}16 MB${Font_color_suffix}"
  elif [[ $MEM_TOTAL_MB -lt 4096 ]]; then
    buf_max_bytes=$((64 * 1024 * 1024))    # 64MB
    echo -e "  内存 1-4GB → 缓冲区封顶 ${Yellow_font_prefix}64 MB${Font_color_suffix}"
  else
    buf_max_bytes=$((128 * 1024 * 1024))   # 128MB
    echo -e "  内存 > 4GB → 缓冲区最高 ${Green_font_prefix}128 MB${Font_color_suffix}"
  fi

  # --- BDP 计算: buffer = bandwidth(bps) * RTT(s) * 2 ---
  local bw_bps=$((NIC_SPEED_MBPS * 1000000))  # Mbps -> bps
  local rtt_sec
  if [[ "$RTT_AVG" == "-1" ]]; then
    rtt_sec="0.100"  # 默认 100ms
  else
    rtt_sec=$(awk "BEGIN{printf \"%.6f\", $RTT_AVG / 1000}")
  fi
  local bdp_bytes
  bdp_bytes=$(awk "BEGIN{val=int($bw_bps * $rtt_sec * 2 / 8); printf \"%d\", val}")

  # 取 BDP 和内存上限的较小值
  if [[ $bdp_bytes -gt $buf_max_bytes ]]; then
    bdp_bytes=$buf_max_bytes
  fi
  # 最小不低于 4MB
  if [[ $bdp_bytes -lt 4194304 ]]; then
    bdp_bytes=4194304
  fi

  local buf_max_human
  buf_max_human=$(awk "BEGIN{printf \"%.1f MB\", $bdp_bytes / 1024 / 1024}")
  echo -e "  BDP 计算 (${NIC_SPEED_MBPS}Mbps x ${RTT_AVG}ms x 2) → 最优缓冲区: ${Green_font_prefix}${buf_max_human}${Font_color_suffix}"

  # --- RTT 分级: 确定 TCP 行为参数 ---
  local slow_start_idle=0
  local tcp_init_cwnd_comment=""
  local notsent_lowat=16384
  local rmem_default=1048576
  local wmem_default=1048576
  local tcp_rmem_init=87380
  local tcp_wmem_init=65536
  local fin_timeout=15
  local keepalive_time=300

  if [[ "$RTT_AVG" != "-1" ]] && (( $(awk "BEGIN{print ($RTT_AVG < 30)}") )); then
    # 低延迟 (<30ms): 小 buffer, 快速恢复
    echo -e "  RTT < 30ms → ${Green_font_prefix}低延迟模式${Font_color_suffix}: 小缓冲区 + 快速响应"
    slow_start_idle=1
    notsent_lowat=131072
    tcp_rmem_init=131072
    tcp_wmem_init=131072
    rmem_default=262144
    wmem_default=262144
    fin_timeout=10
    keepalive_time=600
    tcp_init_cwnd_comment="# 低延迟: 保持 slow_start_after_idle=1, 大初始窗口"
  elif [[ "$RTT_AVG" != "-1" ]] && (( $(awk "BEGIN{print ($RTT_AVG < 150)}") )); then
    # 中延迟 (30-150ms): 标准大 buffer
    echo -e "  RTT 30-150ms → ${Yellow_font_prefix}中延迟模式${Font_color_suffix}: 标准大缓冲区"
    slow_start_idle=0
    notsent_lowat=16384
    tcp_rmem_init=87380
    tcp_wmem_init=65536
    rmem_default=1048576
    wmem_default=1048576
    fin_timeout=15
    keepalive_time=300
    tcp_init_cwnd_comment="# 中延迟: 关闭 slow_start_after_idle, 标准缓冲"
  else
    # 高延迟 (>150ms): 最大 buffer + 激进设置
    echo -e "  RTT > 150ms → ${Red_font_prefix}高延迟模式${Font_color_suffix}: 最大缓冲区 + 激进恢复"
    slow_start_idle=0
    notsent_lowat=16384
    tcp_rmem_init=87380
    tcp_wmem_init=65536
    rmem_default=2097152
    wmem_default=2097152
    fin_timeout=20
    keepalive_time=120
    tcp_init_cwnd_comment="# 高延迟: 关闭 slow_start_after_idle, 最大缓冲区"
  fi

  echo ""
  read -p "确认应用智能优化参数? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo -e "${Tip} 已取消"
    return
  fi

  echo -e "${Info} 正在应用智能优化配置..."

  # Step 3: 清理旧配置 + 写入新配置
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

  cat >> /etc/sysctl.conf << SYSEOF

# ============ 智能自适应调优 (v3.0) ============
# 检测环境: RTT=${RTT_AVG}ms | 带宽=${NIC_SPEED_MBPS}Mbps | 内存=${MEM_TOTAL_GB}GB | CPU=${CPU_CORES}核
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
${tcp_init_cwnd_comment}

# --- BBR 拥塞控制 (Google TCP BBR) ---
net.core.default_qdisc=fq                          # fq 队列调度器, BBR 最佳搭档
net.ipv4.tcp_congestion_control=bbr                 # 启用 BBR 拥塞控制算法

# --- 缓冲区 (基于 BDP=${buf_max_human} 计算) ---
net.core.rmem_max=${bdp_bytes}                      # 接收缓冲区最大值 (所有协议)
net.core.wmem_max=${bdp_bytes}                      # 发送缓冲区最大值 (所有协议)
net.core.rmem_default=${rmem_default}               # 接收缓冲区默认值
net.core.wmem_default=${wmem_default}               # 发送缓冲区默认值
net.ipv4.tcp_rmem=4096 ${tcp_rmem_init} ${bdp_bytes}  # TCP 接收缓冲区 (min default max)
net.ipv4.tcp_wmem=4096 ${tcp_wmem_init} ${bdp_bytes}  # TCP 发送缓冲区 (min default max)
net.ipv4.udp_rmem_min=8192                          # UDP 接收缓冲区最小值
net.ipv4.udp_wmem_min=8192                          # UDP 发送缓冲区最小值

# --- TCP 行为优化 ---
net.ipv4.tcp_no_metrics_save=1                      # 不缓存连接指标, 每次连接独立探测
net.ipv4.tcp_ecn=2                                  # ECN: 服务端被动响应, 不主动发起
net.ipv4.tcp_frto=2                                 # F-RTO: 区分真丢包和乱序导致的超时
net.ipv4.tcp_mtu_probing=1                          # 路径 MTU 探测, 避免分片
net.ipv4.tcp_rfc1337=1                              # 防止 TIME_WAIT 被旧报文重置
net.ipv4.tcp_sack=1                                 # 选择性确认, 高效重传
net.ipv4.tcp_fack=1                                 # 前向确认, 配合 SACK 提升效率
net.ipv4.tcp_window_scaling=1                       # 窗口缩放, 支持大于 64KB 的窗口
net.ipv4.tcp_adv_win_scale=2                        # 窗口大小计算系数
net.ipv4.tcp_moderate_rcvbuf=1                      # 自动调整接收缓冲区
net.ipv4.tcp_timestamps=1                           # 时间戳, RTT 精确计算必备

# --- 延迟优化 ---
net.ipv4.tcp_fastopen=3                             # TFO: 客户端+服务端都启用, 减少握手 RTT
net.ipv4.tcp_slow_start_after_idle=${slow_start_idle}  # 空闲后是否慢启动 (高延迟关闭)
net.ipv4.tcp_notsent_lowat=${notsent_lowat}         # 未发送数据低水位, 降低延迟

# --- 连接回收 ---
net.ipv4.tcp_tw_reuse=1                             # TIME_WAIT 重用, 加速端口回收
net.ipv4.tcp_max_tw_buckets=2000000                 # TIME_WAIT 最大数量
net.ipv4.tcp_fin_timeout=${fin_timeout}             # FIN_WAIT2 超时秒数
net.ipv4.tcp_max_orphans=65536                      # 孤儿连接最大数量

# --- Keepalive (快速检测死连接) ---
net.ipv4.tcp_keepalive_time=${keepalive_time}       # 空闲多久开始探测 (秒)
net.ipv4.tcp_keepalive_intvl=30                     # 探测间隔 (秒)
net.ipv4.tcp_keepalive_probes=3                     # 探测次数, 超过则断开

# --- 握手队列 ---
net.ipv4.tcp_max_syn_backlog=65535                  # SYN 半连接队列大小
net.ipv4.tcp_synack_retries=2                       # SYN-ACK 重试次数
net.ipv4.tcp_syn_retries=3                          # SYN 重试次数
net.core.somaxconn=65535                            # listen() 全连接队列大小

# --- 网卡队列 ---
net.core.netdev_max_backlog=65535                   # 网卡接收队列积压上限
net.core.netdev_budget=600                          # 每次软中断处理包数
net.core.netdev_budget_usecs=20000                  # 每次软中断时间预算 (微秒)
SYSEOF

  sysctl -p && sysctl --system

  echo ""
  echo -e "${Info} =========================================="
  echo -e "${Info} 🧠 智能优化完成!"
  echo -e "${Info} RTT: ${RTT_AVG}ms | 缓冲区: ${buf_max_human}"
  echo -e "${Info} 建议继续执行 Conntrack + 转发 + 资源限制优化"
  echo -e "${Info} 或重启系统使所有配置生效"
  echo -e "${Info} =========================================="
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
${Blue_font_prefix}10.${Font_color_suffix} 🔍 自动检测环境 (RTT/带宽/内存/CPU)
${Purple_font_prefix}11.${Font_color_suffix} 🧠 智能一键优化 (自动检测+自适应配置)
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
  10) detect_environment ;;
  11) smart_optimize ;;
  *)
    clear
    echo -e "${Error}: 请输入正确数字 [0-11]"
    sleep 2s
    copyright
    menu
    ;;
  esac
}

copyright
menu
