下面是一个可直接运行的 Shell 脚本，用于监控分布在多个服务器上的 Java 应用端口连通性。脚本包含配置分离、超时控制、彩色输出、日志记录等实用功能。

---

## 一、配置文件

新建一个文件 `apps.conf`，格式为：`IP 端口 备注`（以空格或 Tab 分隔，`#` 开头为注释）：

```bash
# apps.conf
# 格式： IP地址        端口    备注
192.168.1.10    8080    订单服务(order-service)
192.168.1.11    8081    用户服务(user-service)
192.168.1.12    8082    支付服务(payment-service)
192.168.1.13    9090    网关服务(gateway)
```

> 建议把这个文件和脚本放在同一目录，或者通过参数传入绝对路径。

---

## 二、监控脚本 `check_apps.sh`

```bash
#!/bin/bash
###############################################################################
# Java 应用端口监控脚本
# 功能：读取配置文件，逐个检测目标 IP:PORT 是否可达（TCP 连通性）
# 用法：./check_apps.sh [-f 配置文件] [-t 超时秒数] [-l 日志文件]
###############################################################################

set -u

# -------------------------- 默认参数 --------------------------
CONF_FILE="$(dirname "$0")/apps.conf"   # 默认配置文件路径
TIMEOUT=3                               # 单个端口检测超时时间（秒）
LOG_FILE="/var/log/check_apps.log"       # 日志文件
CONNECT_TIMEOUT=2                       # TCP 连接超时（秒）

# -------------------------- 参数解析 --------------------------
while getopts ":f:t:l:h" opt; do
    case $opt in
        f) CONF_FILE="$OPTARG" ;;
        t) TIMEOUT="$OPTARG" ;;
        l) LOG_FILE="$OPTARG" ;;
        h)
            echo "用法: $0 [-f 配置文件] [-t 超时秒数] [-l 日志文件]"
            exit 0
            ;;
        \?)
            echo "无效选项: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# -------------------------- 颜色定义 --------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# -------------------------- 检查依赖 --------------------------
if ! command -v nc >/dev/null 2>&1; then
    echo -e "${YELLOW}[警告] 未检测到 nc 命令，将使用 /dev/tcp 方式检测${NC}"
    USE_NC=0
else
    USE_NC=1
fi

# -------------------------- 检查配置文件 --------------------------
if [[ ! -f "$CONF_FILE" ]]; then
    echo -e "${RED}[错误] 配置文件不存在: $CONF_FILE${NC}" >&2
    exit 2
fi

# -------------------------- 端口检测函数 --------------------------
# 返回 0 表示端口可达，非 0 表示不可达
check_port() {
    local ip="$1"
    local port="$2"

    if [[ "$USE_NC" -eq 1 ]]; then
        # -z: 只扫描不发送数据；-w: 超时；-G: 连接超时
        nc -z -w "$TIMEOUT" "$ip" "$port" >/dev/null 2>&1
        return $?
    else
        # 使用 bash 内建 /dev/tcp
        timeout "$TIMEOUT" bash -c "echo > /dev/tcp/$ip/$port" >/dev/null 2>&1
        return $?
    fi
}

# -------------------------- 主流程 --------------------------
TOTAL=0
OK=0
FAIL=0
FAIL_LIST=()

START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE} Java 应用端口监控  开始时间: ${START_TIME}${NC}"
echo -e "${BLUE} 配置文件: ${CONF_FILE}${NC}"
echo -e "${BLUE}============================================================${NC}"
printf "%-18s %-7s %-30s %-10s\n" "IP" "端口" "备注" "状态"
echo "------------------------------------------------------------"

# 逐行读取配置（跳过空行和注释）
while IFS= read -r line || [[ -n "$line" ]]; do
    # 去除前后空白
    line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # 跳过空行与注释行
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue

    # 解析字段：IP、端口、备注（备注可能包含空格，所以用 read 把剩余内容都放进 desc）
    read -r ip port desc <<< "$(echo "$line" | awk '{ $1=$1; print }')"
    # 上面的写法无法保留备注里的空格，改用更稳的方式：
    ip=$(echo "$line" | awk '{print $1}')
    port=$(echo "$line" | awk '{print $2}')
    desc=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":"")}')

    # 校验 IP 与端口
    if [[ -z "$ip" || -z "$port" ]]; then
        echo -e "${YELLOW}[跳过] 配置行格式不正确: $line${NC}"
        continue
    fi

    TOTAL=$((TOTAL + 1))

    if check_port "$ip" "$port"; then
        STATUS="${GREEN}✔ UP${NC}"
        OK=$((OK + 1))
        printf "%-18s %-7s %-30s %b\n" "$ip" "$port" "$desc" "$STATUS"
    else
        STATUS="${RED}✘ DOWN${NC}"
        FAIL=$((FAIL + 1))
        FAIL_LIST+=("$ip:$port  ($desc)")
        printf "%-18s %-7s %-30s %b\n" "$ip" "$port" "$desc" "$STATUS"
    fi
done < "$CONF_FILE"

END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# -------------------------- 汇总输出 --------------------------
echo "------------------------------------------------------------"
echo -e "总数: ${TOTAL}   ${GREEN}正常: ${OK}${NC}   ${RED}异常: ${FAIL}${NC}"
echo -e "${BLUE}结束时间: ${END_TIME}${NC}"

if [[ "$FAIL" -gt 0 ]]; then
    echo -e "${RED}异常列表:${NC}"
    for item in "${FAIL_LIST[@]}"; do
        echo -e "  ${RED}✘${NC} $item"
    done
fi

# -------------------------- 写入日志 --------------------------
# 确保日志目录存在
LOG_DIR=$(dirname "$LOG_FILE")
if [[ ! -d "$LOG_DIR" ]]; then
    mkdir -p "$LOG_DIR"
fi

# 写入日志（保留系统错误输出）
{
    echo "[$END_TIME] total=$TOTAL ok=$OK fail=$FAIL"
    for item in "${FAIL_LIST[@]:-}"; do
        [[ -n "$item" ]] && echo "    DOWN: $item"
    done
} >> "$LOG_FILE"

# 判断上一步的重定向是否成功
if [[ $? -ne 0 ]]; then
    echo -e "${YELLOW}[警告] 无法写入日志文件: $LOG_FILE （请检查路径是否为目录、权限是否足够）${NC}"
fi

# 返回码：有异常返回 1，全部正常返回 0
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
```

```sh
报错信息里的 ^M 是罪魁祸首。这说明你的 check_apps.sh 脚本文件是在 Windows 环境下编辑并上传的，文件使用了 Windows 的换行符（\r\n，即 CRLF），而 Linux 系统只认 Unix 换行符（\n，即 LF）。

当系统读取脚本第一行的 #!/bin/bash 时，实际上读到的是 #!/bin/bash\r。Linux 会去找一个名为 /bin/bash\r 的解释器，找不到自然报错。
sed -i 's/\r$//' check_apps.sh
```



---

## 三、使用方式

```bash
# 赋予执行权限
chmod +x check_apps.sh

# 使用默认配置文件（同目录下的 apps.conf）
./check_apps.sh

# 指定配置文件与超时
./check_apps.sh -f /opt/monitor/apps.conf -t 5

# 指定日志文件
./check_apps.sh -f /opt/monitor/apps.conf -l /tmp/apps_monitor.log
```

### 输出示例
```
============================================================
 Java 应用端口监控  开始时间: 2025-01-20 10:00:00
 配置文件: /opt/monitor/apps.conf
============================================================
IP                 端口    备注                           状态
------------------------------------------------------------
192.168.1.10       8080    订单服务(order-service)        ✔ UP
192.168.1.11       8081    用户服务(user-service)         ✔ UP
192.168.1.12       8082    支付服务(payment-service)      ✘ DOWN
192.168.1.13       9090    网关服务(gateway)              ✔ UP
------------------------------------------------------------
总数: 4   正常: 3   异常: 1
结束时间: 2025-01-20 10:00:05
异常列表:
  ✘ 192.168.1.12:8082  (支付服务(payment-service))
```

---

## 四、配合定时任务与告警

### 1. 加入 crontab（每 5 分钟检测一次）
```bash
*/5 * * * * /opt/monitor/check_apps.sh -f /opt/monitor/apps.conf -l /var/log/check_apps.log
```

### 2. 触发告警（示例：钉钉/企业微信 Webhook）
在脚本末尾的 `[[ "$FAIL" -gt 0 ]] && exit 1` 之前，可以加一段：

```bash
if [[ "$FAIL" -gt 0 ]]; then
    MSG="【Java应用监控告警】\n异常应用数: $FAIL\n$(printf '  - %s\n' "${FAIL_LIST[@]}")"
    curl -s -H "Content-Type: application/json" \
        -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"$MSG\"}}" \
        "https://oapi.dingtalk.com/robot/send?access_token=YOUR_TOKEN" >/dev/null
fi
```

---

## 五、几点说明与建议

1. **只检测端口连通性 ≠ 应用健康**
   端口监听不等于应用能正常处理请求。如果要做更严格的应用级健康检查，可以扩展脚本，对特定路径（如 `/actuator/health`）发起 HTTP 请求并校验返回码/内容。这个可以按需再加。

2. **`nc` 与 `/dev/tcp` 二选一**
   脚本优先使用 `nc`，如果机器上没装则自动回退到 bash 内建的 `/dev/tcp`，兼容性较好。

3. **配置文件里备注含空格**
   脚本通过 `awk` 取第 3 个字段之后的所有内容作为备注，所以备注里带空格也没问题，无需加引号。

4. **异常返回码**
   脚本在存在 DOWN 的应用时返回 `1`，方便被上层调度系统（如 Jenkins、Zabbix、自研告警平台）捕捉。

如果需要我帮你再加 **HTTP 健康检查** 或 **并发检测（提升大量应用时的速度）**，告诉我即可。