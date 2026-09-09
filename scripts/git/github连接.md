# github连接

有时候开了梯子后还是有可能连不上github，这个时候就需要按如下操作处理一下了

## 使用代理的方案

 **Git 无法通过 HTTPS（443 端口）连接到 GitHub**。以下是按优先级排列的排查和解决方法：

------

### **第一步：确认代理软件是否在运行**

端口 `7897` 看起来是 Clash 类代理工具的端口，但 **Clash 默认的 HTTP 代理端口通常是 `7890`**，而非 `7897`。

先确认你的代理工具实际使用的端口：

- 打开代理软件的设置界面，查看 **HTTP/HTTPS 代理端口**
- 常见默认端口：Clash = `7890`，V2Ray = `10809`，SS = `1080`

如果端口不对，重新设置：

```cmd
git config --global --unset https.proxy
git config --global http.proxy http://127.0.0.1:实际端口
git config --global https.proxy http://127.0.0.1:实际端口
```

> ⚠️ **注意：HTTP 和 HTTPS 两个都要设置**。

### **第二步：验证代理是否生效**

设置完后，先用 `curl` 测试连通性：

```cmd
curl -I https://github.com
```

如果返回 HTTP 响应（如 `HTTP/2 200`），说明代理通了，再执行 `git pull`。

如果仍然不通，说明代理软件本身未正常工作，需要：

- 确认代理软件处于 **全局/规则模式** 且正在运行
- 检查系统代理是否开启（设置 → 网络和 Internet → 代理）

## 不用代理的方案

**彻底清除代理配置**：

```sh
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 刷新DNS缓存

```cmd
ipconfig /flushdns
```

