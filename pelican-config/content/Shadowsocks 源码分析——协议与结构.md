title: Shadowsocks 源码分析——协议与结构
date: 2016-12-06 21:00:00
tags: 源码分析, Python

[Shadowsocks](https://github.com/shadowsocks/shadowsocks/tree/master) 是一款著名的 SOCKS5 代理工具，深受人民群众喜爱。它的源码工程质量很高，十分便于研究。不过当你真正开始读源码的时候，会有一种似懂非懂的感觉，因为虽然它的大体框架容易理解，但是其中的诸多细节却不是那么简单明了。

本文将基于 [2.9.0 版本的源码](https://github.com/loggerhead/shadowsocks/tree/8e8ee5d490ce319b8db9b61001dac51a7da4be63)对 shadowsocks 进行分析，希望读者看完以后能对 shadowsocks 的原理有个大体上的认识。为了行文简洁，在示例中我们用 ss 指代 shadowsocks。

<!--- SUMMARY_END -->

[TOC]

# SOCKS5 协议

无论是实现什么网络应用，首当其冲的就是确定通讯协议。SOCKS5 协议作为一个同时支持 TCP 和 UDP 的应用层协议（[RFC](https://www.ietf.org/rfc/rfc1928.txt) 只有短短的 7 页），因为其简单易用的特性而被 shadowsocks 青睐。我们先从 SOCKS5 协议入手，一点一点剖析 shadowsocks。

## 握手阶段

客户端和服务器在握手阶段协商认证方式，比如：是否采用用户名/密码的方式进行认证，或者不采用任何认证方式。

客户端发送给服务器的消息格式如下（数字表示对应字段占用的字节数）：

```
+----+----------+----------+
|VER | NMETHODS | METHODS  |
+----+----------+----------+
| 1  |    1     |  1~255   |
+----+----------+----------+
```

* `VER` 字段是当前协议的版本号，也就是 `5`；
* `NMETHODS` 字段是 `METHODS` 字段占用的字节数；
* `METHODS` 字段的每一个字节表示一种认证方式，表示客户端支持的全部认证方式。

服务器在收到客户端的协商请求后，会检查是否有服务器支持的认证方式，并返回客户端如下格式的消息：

```
+----+--------+
|VER | METHOD |
+----+--------+
| 1  |   1    |
+----+--------+
```

对于 shadowsocks 而言，返回给客户端的值只有两种可能：

* `0x05 0x00`：告诉客户端采用无认证的方式建立连接；
* `0x05 0xff`：客户端的任意一种认证方式服务器都不支持。

举个例子，就 shadowsocks 而言，最简单的握手可能是这样的：

```python
client -> ss: 0x05 0x01 0x00
ss -> client: 0x05 0x00
```

如果客户端**还**支持用户名/密码的认证方式，那么握手会是这样子：

```python
client -> ss: 0x05 0x02 0x00 0x02
ss -> client: 0x05 0x00
```

如果客户端**只**支持用户名/密码的认证方式，那么握手会是这样子：

```python
client -> ss: 0x05 0x01 0x02
ss -> client: 0x05 0xff
```

## 建立连接

完成握手后，客户端会向服务器发起请求，请求的格式如下：

```
+----+-----+-------+------+----------+----------+
|VER | CMD |  RSV  | ATYP | DST.ADDR | DST.PORT |
+----+-----+-------+------+----------+----------+
| 1  |  1  |   1   |  1   | Variable |    2     |
+----+-----+-------+------+----------+----------+
```

* `CMD` 字段：`command` 的缩写，shadowsocks 只用到了：
    * `0x01`：建立 TCP 连接
    * `0x03`：关联 UDP 请求
* `RSV` 字段：保留字段，值为 `0x00`；
* `ATYP` 字段：`address type` 的缩写，取值为：
    * `0x01`：IPv4
    * `0x03`：域名
    * `0x04`：IPv6
* `DST.ADDR` 字段：`destination address` 的缩写，取值随 `ATYP` 变化：
    * `ATYP == 0x01`：4 个字节的 IPv4 地址
    * `ATYP == 0x03`：1 个字节表示域名长度，紧随其后的是对应的域名
    * `ATYP == 0x04`：16 个字节的 IPv6 地址
* `DST.PORT` 字段：目的服务器的端口。

在收到客户端的请求后，服务器会返回如下格式的消息：

```
+----+-----+-------+------+----------+----------+
|VER | REP |  RSV  | ATYP | BND.ADDR | BND.PORT |
+----+-----+-------+------+----------+----------+
| 1  |  1  |   1   |  1   | Variable |    2     |
+----+-----+-------+------+----------+----------+
```

* `REP` 字段：用以告知客户端请求处理情况。在请求处理成功的情况下，shadowsocks 将这个字段的值设为 `0x00`，否则，shadowsocks 会直接断开连接；
* 其它字段和请求中字段的取值类型一样。

举例来说，如果客户端通过 shadowsocks 代理 `127.0.0.1:8000` 的请求，那么客户端和 shadowsocks 之间的请求和响应是这样的：

```python
#    request: VER  CMD  RSV  ATYP DST.ADDR            DST.PORT
client -> ss: 0x05 0x01 0x00 0x01 0x7f 0x00 0x00 0x01 0x1f 0x40
#   response: VER  REP  RSV  ATYP BND.ADDR            BND.PORT
ss -> client: 0x05 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x10 0x10
```

这里 `0x7f 0x00 0x00 0x01 0x1f 0x40` 对应的是 `127.0.0.1:8000`。需要注意的是，当请求中的 `CMD == 0x01` 时，绝大部分 SOCKS5 客户端的实现都会忽略 SOCKS5 服务器返回的 `BND.ADDR` 和 `BND.PORT` 字段，所以这里的 `0x00 0x00 0x00 0x00 0x10 0x10` 只是 shadowsocks 返回的一个无意义的地址和端口[^bnd.addr]。

[^bnd.addr]: 也有部分 SOCKS5 服务器的实现返回全零。

## 传输阶段
SOCKS5 协议只负责建立连接，在完成握手阶段和建立连接之后，SOCKS5 服务器就只做简单的转发了。假如客户端通过 shadowsocks 代理 `google.com:80`（用 `remote` 表示），那么整个过程如图所示：

![socks example](https://loggerhead.me/_images/socks5-example.svg)

整个过程中发生的传输可能是这样的：

```python
# 握手阶段
client -> ss: 0x05 0x01 0x00
ss -> client: 0x05 0x00
# 建立连接
client -> ss: 0x05 0x01 0x00 0x03 0x0a b'google.com'  0x00 0x50
ss -> client: 0x05 0x00 0x00 0x01 0x00 0x00 0x00 0x00 0x10 0x10
# 传输阶段
client -> ss -> remote
remote -> ss -> client
...
```

`b'google.com'` 表示 `google.com` 对应的 ASCII 码。

# 整体结构

在进一步了解 shadowsocks 的内部构造之前，我们粗略的看一下各个模块分别做了些什么：

* `tcprelay.py`：核心部分，整个 SOCKS5 协议的实现都在这里。负责 TCP 代理的实现；
* `udprelay.py`：负责 UDP 代理的实现；
* `asyncdns.py`：实现了简单的异步 DNS 查询；
* `eventloop.py`：封装了三种常见的 IO 复用函数——`epoll`、`kqueue` 和 `select`，提供统一的接口；
* `encrypt.py`：提供统一的加密解密接口；
* `crypto`：封装了多种加密库的调用，包括 OpenSSL 和 libsodium；
* `daemon.py`：用于实现守护进程；
* `shell.py`：读取命令行参数，检查配置；
* `common.py`：提供一些工具函数，比如：将 `bytes` 转换成 `str`、解析 SOCKS5 请求；
* `lru_cache.py`：实现了 [LRU 缓存](https://en.wikipedia.org/wiki/Cache_replacement_policies#Least_Recently_Used_.28LRU.29)；
* `local.py`：shadowsocks 客户端（即 `sslocal` 命令）的入口；
* `server.py`：shadowsocks 服务器（即 `ssserver` 命令）的入口。

sslocal 和 ssserver 复用了绝大部分的代码，所以两者的运行流程都可以用伪代码表示为：

```python
# local.py or server.py
def main():
    # 解析命令行和配置文件中的参数
    conf = shell.parse_config()
    # 根据配置决定要不要以守护进程的方式运行
    daemon.daemonize(conf)

    loop = eventloop.init()
    tcp_server = tcprelay.init(conf)
    udp_server = udprelay.init(conf)
    dns_resolver = asyncdns.init(conf)

    # 将 TCPRelay、UDPRelay 和 DNSResolver 注册到事件循环中
    tcp_server.add_to_loop(loop)
    udp_server.add_to_loop(loop)
    dns_resolver.add_to_loop(loop)

    loop.run()

# eventloop.py 中 loop.run 的实现
def loop_run():
    while True:
        events = wait_for_events()
        for handler, event in events:
            # handler 是 TCPRelay、UDPRelay 或 DNSResolver
            handler.handle_event(event)
```

有一点需要提一下：**代理和能翻墙的代理是不一样的**。比如，下图是普通的 SOCKS5 代理：

![normal-proxy](https://loggerhead.me/_images/normal-proxy.svg)

而能翻墙的 SOCKS5 代理是下图这种结构：

![ss-proxy](https://loggerhead.me/_images/ss-proxy.svg)

可以看出来，SOCKS5 服务器的实现被拆分成了两部分：

* sslocal 负责与 SOCKS5 客户端进行 SOCKS5 协议相关的通讯（握手并建立连接），在建立连接后将 SOCKS5 客户端发来的数据加密并发送给 ssserver；
* ssserver 起到一个中继的作用，负责解密以后将数据转发给目标服务器，并不涉及 SOCKS5 协议的任何一部分。

其中一个重要的环节就是加密解密——数据经过 sslocal（本机）加密以后转发给 ssserver（VPS），这也是普通代理和能翻墙的代理的区别。在了解到这一点以后，shadowsocks 的很多细节就容易理解了。下面我们分模块，对 shadowsocks 内部结构一探究竟。

# 事件处理

Shadowsocks 封装了三种常见的 IO 复用函数——`epoll`、`kqueue` 和 `select`，并通过 `eventloop.py` 提供统一的接口。之所以使用 IO 复用，而不是多线程的方式，是因为前者能提供更好的性能和更少的内存开销，这在路由器上至关重要[^router-problem]。

[^router-problem]: 因为路由器的 CPU 性能远不如 PC，内存也很少，可能只有几十 MB 可以用。

## eventloop.py

`eventloop.py` 的主要逻辑在于 `run` 函数的实现：

```python
def run(self):
    events = []
    while not self._stopping:
        # as soon as possible
        asap = False
        # 获取事件
        try:
            events = self.poll(TIMEOUT_PRECISION)
        except (OSError, IOError) as e:
            if errno_from_exception(e) in (errno.EPIPE, errno.EINTR):
                # EPIPE: Happens when the client closes the connection
                # EINTR: Happens when received a signal
                # handles them as soon as possible
                asap = True
                logging.debug('poll:%s', e)
            else:
                logging.error('poll:%s', e)
                import traceback
                traceback.print_exc()
                continue
        # 找到事件对应的 handler，将事件交由它处理
        for sock, fd, event in events:
            # 通过 fd 找到对应的 handler
            # 一个 handler 可能对应多个 fd（reactor 模式）
            handler = self._fdmap.get(fd, None)
            if handler is not None:
                handler = handler[1]
                try:
                    # handler 可能是 TCPRelay、UDPRelay 或 DNSResolver
                    handler.handle_event(sock, fd, event)
                except (OSError, IOError) as e:
                    shell.print_exception(e)
        # 计时器。每隔 10s 调用注册的 handle_periodic 函数
        now = time.time()
        if asap or now - self._last_time >= TIMEOUT_PRECISION:
            for callback in self._periodic_callbacks:
                callback()
            self._last_time = now
```

`run` 是一个典型的事件循环，它会阻塞在第 8 行等待注册事件的发生，然后通过事件对应的文件描述符 `fd` 找到 `handler`，调用 `handler.handle_event(sock, fd, event)` 来将事件交由 `handler` 处理，同时每隔 `TIMEOUT_PRECISION` 秒调用 `TCPRelay`、`UDPRelay` 或 `DNSResolver` 的 `handle_periodic` 函数处理超时或清除缓存。

比如：如果客户端连接到 sslocal，第 8 行会返回可读事件，第 30 行会调用 `TCPRelay` 的 `handle_event` 来处理，`handle_event` 发现这是一个可读事件，会调用 `accept` 建立新连接。

## tcprelay.py

Shadowsocks 采用了反应器模式（[reactor pattern](https://en.wikipedia.org/wiki/Reactor_pattern)），如下图所示。

![ss-reactor-pattern](https://loggerhead.me/_images/ss-reactor-pattern.png)

`TCPRelayHandler` 的事件会由 `EventLoop` 分发给 `TCPRelay`，再经由 `TCPRelay` 将事件分发给相应的 `TCPRelayHandler` 处理。这个过程发生在 `EventLoop` 和 `TCPRelay` 的 `handle_event` 函数。

我们去掉其中的日志处理和错误处理逻辑，看看 `handle_event` 函数：

```python
def handle_event(self, sock, fd, event):
    # 如果是 TCPRelay 的 socket
    if sock == self._server_socket:
        conn = self._server_socket.accept()
        TCPRelayHandler(self, self._fd_to_handlers,
                        self._eventloop, conn[0], self._config,
                        self._dns_resolver, self._is_local)
    else:
        # 找到 fd 对应的 TCPRelayHandler
        handler = self._fd_to_handlers.get(fd, None)
        if handler:
            handler.handle_event(sock, event)
```

逻辑很简单，如果发生事件（可读事件）的 socket 是 `TCPRelay` 的 socket，说明有新的 TCP 连接，创建一个 `TCPRelayHandler` 对象将新连接封装起来。否则，找到发生事件的 `TCPRelayHandler`，将事件交给它处理。

## udprelay.py

`UDPRelay` 的 `handle_event` 类似，不过它没有什么 `UDPRelayHandler`，所有的逻辑都是 `UDPRelay` 处理的，只不过不同的 socket 对应不同的函数——`_handle_server` 和 `_handle_client`。

```python
# 只有可读事件，所以不需要传入 event 给 `_handle_server` 或 `_handle_client`
def handle_event(self, sock, fd, event):
    if sock == self._server_socket:
        # 如果有错误发生，记录日志
        if event & eventloop.POLL_ERR:
            logging.error('UDP server_socket err')
        self._handle_server()
    elif sock and (fd in self._sockets):
        if event & eventloop.POLL_ERR:
            logging.error('UDP client_socket err')
        # 需要告诉是哪个 sock 发生了事件
        self._handle_client(sock)
```

## asyncdns.py

`DNSResolver` 的 `handle_event` 与 `TCPRelay` 和 `UDPRelay` 都不一样，因为它不需要分发处理，所以逻辑更简单：

```python
# 只有可读事件
def handle_event(self, sock, fd, event):
    # 防御性编程，实际上是个无用的判断
    if sock != self._sock:
        return
    # 如果有错误事件发生
    if event & eventloop.POLL_ERR:
        logging.error('dns socket err')
        # 从事件循环移除 self._sock
        self._loop.remove(self._sock)
        self._sock.close()
        # 重新初始化 self._sock
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM,
                                   socket.SOL_UDP)
        # 将套接字设置为非阻塞模式
        self._sock.setblocking(False)
        # 重新注册到事件循环
        self._loop.add(self._sock, eventloop.POLL_IN, self)
    else:
        # 读取一个 UDP 包，并取出前 1024 个字节
        # 注意：如果一个 UDP 包超过 1024 字节，比如：2048 字节。
        # 一次 recvfrom(1024) 也会消耗整个 UDP 包。这里是认为
        # DNS 查询返回的 UDP 包都不会超过 1024 字节。
        data, addr = sock.recvfrom(1024)
        if addr[0] not in self._servers:
            logging.warn('received a packet other than our dns')
            return
        self._handle_data(data)
```

# 总结

本来想一篇写完的……没想到才简单的介绍一下就这么长了，之后再分两篇写 `tcprelay.py` 和 `udprelay.py` 的细节好了。
