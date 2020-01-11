title: Shadowsocks 源码分析——UDP 代理
date: 2017-3-22 11:20
tags: 源码分析, Python

我们在 [Shadowsocks 源码分析——TCP 代理](/posts/shadowsocks-yuan-ma-fen-xi-tcp-dai-li.html)中分析了 TCP 部分的源码，UDP 的实现比 TCP 简单不少，同时代码结构上与 TCP 又有所不同。本文将在假设读者已经看过了前面几篇文章的基础上，对 UDP 部分的实现作分析。

<!--- SUMMARY_END -->

[TOC]

# SOCKS5 协议

在 [Shadowsocks 源码分析——协议与结构](/posts/shadowsocks-yuan-ma-fen-xi-xie-yi-yu-jie-gou.html)中，我们简单介绍了 SOCKS5 协议的 TCP 代理，知道是 shadowsocks 的客户端 `sslocal` 与 shadowsocks 服务器 `ssserver` 共同完成了 SOCKS5 服务器的功能，整个 SOCKS5 代理的结构如下图所示：

![proxy-structure](https://loggerhead.me/_images/normal-proxy.svg)

并且了解到了 SOCKS5 协议可以分为三个阶段：

1. 握手阶段
2. 建立连接
3. 传输阶段

我们用 `client`、`ss`、`server` 分别指代 SOCKS5 客户端、SOCKS5 服务器（`sslocal` + `ssserver`）、目标服务器，假设它们都位于本机上，且对应的端口如下：

|  机器  |         端口          |
|--------|----------------------|
| client | 63155/TCP、53911/UDP |
| ss     | 8000/TCP、8000/UDP   |
| server | 9000/UDP             |

我们来看看各个阶段 UDP 代理与 TCP 代理有什么不一样。

## 握手阶段

这个阶段和 TCP 代理时没有区别，`client` 会向 `ss` 建立 TCP 连接，并且协商认证方式，对于 shadowsocks 而言具体传输的数据如下：

```python
client -> ss: 0x05 0x01 0x00
ss -> client: 0x05 0x00
```

## 建立连接

与 TCP 代理一样，`client` 会向 `ss` 发起请求：

```
+----+-----+-------+------+----------+----------+
|VER | CMD |  RSV  | ATYP | DST.ADDR | DST.PORT |
+----+-----+-------+------+----------+----------+
| 1  |  1  |   1   |  1   | Variable |    2     |
+----+-----+-------+------+----------+----------+
```

除了以下几个不同点外，请求中各个字段的含义与 TCP 代理时相同：

* `CMD` 字段：取值为 `0x03`，表示关联 UDP 请求；
* `DST.ADDR` 字段：关联的 UDP 客户端的地址；
* `DST.PORT` 字段：关联的 UDP 客户端的端口。

这到底是什么意思呢？我们先不急着了解，等下举个例子就明白了。让我们先看看 `ss` 返回给 `client` 的响应：

```
+----+-----+-------+------+----------+----------+
|VER | REP |  RSV  | ATYP | BND.ADDR | BND.PORT |
+----+-----+-------+------+----------+----------+
| 1  |  1  |   1   |  1   | Variable |    2     |
+----+-----+-------+------+----------+----------+
```

`BND.ADDR`、`BND.PORT` 用来告诉 `client` 转发服务器的地址和端口（一般就是 SOCKS5 服务器），除此之外其它部分和 TCP 代理一样。下面看一个具体的例子：

```python
#    request: VER  CMD  RSV  ATYP DST.ADDR            DST.PORT
client -> ss: 0x05 0x03 0x00 0x01 0x7f 0x00 0x00 0x01 0xd2 0x97
                                  127.0.0.1:53911

#   response: VER  REP  RSV  ATYP BND.ADDR            BND.PORT
ss -> client: 0x05 0x00 0x00 0x01 0x7f 0x00 0x00 0x01 0x1f 0x40
                                  127.0.0.1:8000
```

`client` 向 `ss` 发送请求，告诉 `ss`：“我想要进行 UDP 代理，并且通过 `127.0.0.1:53911` 这个 UDP 套接字发送数据包”。`ss` 收到请求后，告诉 `client`：“我明白了，你把 UDP 数据包发到 `127.0.0.1:8000` 这个服务器，它会替你转发的”。之后 `client` 会在 `127.0.0.1:53911` 打开一个 UDP 套接字[^real-process]，并在传输阶段通过它往转发服务器（`127.0.0.1:8000`）发送 UDP 数据包。这里有几点需要提一下：

* 对于 shadowsocks 而言，`sslocal` 就是转发服务器；
* 「握手阶段」和「建立连接」都是通过 TCP 进行的；
* TCP 和 UDP 可以共用同一个端口；

[^real-process]: 可能会先打开 UDP 套接字，获取到它的端口后再发送请求。

我们把 UDP 套接字 `127.0.0.1:53911/UDP` 与转发服务器 `127.0.0.1:8000/UDP` 之间的数据传输称为「UDP 会话」[^udp-association]。上述过程就是为了建立一个 UDP 会话，将它与建立连接时的 TCP 连接关联起来。当 TCP 连接断开时，UDP 会话也随之终止。

[^udp-association]: UDP 不像 TCP，没有连接的概念，[RFC 1928](https://www.ietf.org/rfc/rfc1928.txt) 中的原文是“UDP association”，这里为了说明方便，暂且翻译成「UDP 会话」。

## 传输阶段

在建立完 UDP 会话之后，就进入了传输阶段。但是与 TCP 代理不同，UDP 代理不能无脑转发数据包，它还需要为数据加上头部：

```
+----+------+------+----------+----------+----------+
|RSV | FRAG | ATYP | DST.ADDR | DST.PORT |   DATA   |
+----+------+------+----------+----------+----------+
| 2  |  1   |  1   | Variable |    2     | Variable |
+----+------+------+----------+----------+----------+
```

除了 `FRAG` 字段，头部中的每个字段都与[前文](/posts/shadowsocks-yuan-ma-fen-xi-xie-yi-yu-jie-gou.html)中介绍过的一样，对于 shadowsocks 而言 `FRAG` 字段的值始终为 0。我们来看一个例子：

```python
#    request: RSV       FRAG ATYP DST.ADDR            DST.PORT  DATA
client -> ss: 0x00 0x00 0x00 0x01 0x7f 0x00 0x00 0x01 0x23 0x28 b'1'
                                  127.0.0.1:9000
ss -> server: b'1'
server -> ss: b'1'
#   response: RSV       FRAG ATYP DST.ADDR            DST.PORT  DATA
ss -> client: 0x00 0x00 0x00 0x01 0x7f 0x00 0x00 0x01 0x23 0x28 b'1'
                                  127.0.0.1:9000
```

`client` 向 `ss` 发送了一个数据包，告诉 `ss` 将数据 `b'1'` 转发给 `127.0.0.1:9000`，随后 `ss` 便将数据转发给了 `server`，`server` 回复了相同的数据，`ss` 收到后将数据发回给了 `client`。这里有两个问题：

1. 当 `server` 回复 `ss` 时，`ss` 怎么知道应该把收到的数据发给哪个 `client`；
2. 为什么 `ss` 发给 `client` 的数据中，`DST.PORT` 是 `9000`，而不是 `53911`；

第一个问题在下文分析源码以后就明白了，第二个问题给个提示：如果同一个 `client` 通过同一个 `ss` 向多个 `server` 发送数据，`client` 怎么确定 `ss` 发给它的数据来自哪个 `server` 呢？

# UDPRelay

在深入细节之前，我们先从总体上了解一下各个函数的功能：

1. `TCPRelayHandler._handle_stage_addr` 完成「握手阶段」和「建立连接」；
2. `handle_event` 根据发生事件的套接字调用相应的函数（详见[前文](/posts/shadowsocks-yuan-ma-fen-xi-xie-yi-yu-jie-gou.html#udprelaypy)）；
3. `_handle_server` 将来自客户端的数据转发给服务器；
4. `_handle_client` 将来自服务器的数据转发给客户端；

`_handle_server` 与 `_handle_client` 的关系与[前文](/posts/shadowsocks-yuan-ma-fen-xi-tcp-dai-li.html#_1)提过的 `remote_sock` 与 `local_sock` 的关系类似。要注意的是：

* 对于 `sslocal` 而言，客户端是指「SOCKS5 客户端」，服务器是指「ssserver」；
* 对于 `ssserver` 而言，客户端是指「sslocal」，服务器是指「目标服务器」；

![ss-socks](https://loggerhead.me/_images/ss-socks.png)

`sslocal` 和 `ssserver` 复用了大部分代码，两者的功能很容易让人产生迷惑，这里我们再次强调一下：

> * sslocal 负责与 SOCKS5 客户端进行 SOCKS5 协议相关的通讯（握手并建立连接），在建立连接后将 SOCKS5 客户端发来的数据加密并发送给 ssserver；
> * ssserver 起到一个中继的作用，负责解密以后将数据转发给目标服务器，并不涉及 SOCKS5 协议的任何一部分。

![ss-proxy](https://loggerhead.me/_images/ss-proxy.svg)

## TCPRelayHandler._handle_stage_addr

「握手阶段」与「建立连接」都是通过 TCP 完成的，shadowsocks 为了复用代码，把 UDP 这部分的逻辑也写在了 `TCPRelayHandler` 中。「握手阶段」的实现与 TCP 一模一样，读一下[前文对 `_handle_stage_init` 的分析](/posts/shadowsocks-yuan-ma-fen-xi-tcp-dai-li.html#_handle_stage_init)就能明白。「建立连接」是在 `_handle_stage_addr` 这个函数中完成的，我们把不相关的代码去掉：

```python
def _handle_stage_addr(self, data):
    if self._is_local:
        cmd = common.ord(data[1])
        if cmd == CMD_UDP_ASSOCIATE:
            logging.debug('UDP associate')
            if self._local_sock.family == socket.AF_INET6:
                header = b'\x05\x00\x00\x04'
            else:
                header = b'\x05\x00\x00\x01'
            addr, port = self._local_sock.getsockname()[:2]
            addr_to_send = socket.inet_pton(self._local_sock.family,
                                            addr)
            port_to_send = struct.pack('>H', port)
            self._write_to_sock(header + addr_to_send + port_to_send,
                                self._local_sock)
            self._stage = STAGE_UDP_ASSOC
            # just wait for the client to disconnect
            return
```

首先 `self._is_local` 判断当前进程是 `sslocal` 还是 `ssserver`，然后查看一下 SOCKS5 请求中的 `CMD` 字段的值是不是 `0x03`，如果是的话，说明这是个 UDP 代理建立连接的请求，那么构造一个 SOCKS5 响应发送给 SOCKS5 客户端。代码相当简单，我们了解一下各个函数的功能就行了：

* `getsockname`：用于获取套接字的地址和端口；
* `inet_pton`：将地址转换成字节数组（比如：`'127.0.0.1'` -> `0x7f 0x00 0x00 0x01`）；
* `struct.pack('>H', port)`：将 `port` 转换成网络序的字节数组（比如：`8000` -> `0x1f 0x40`）。

有两点值得提一下：

* shadowsocks 简化了逻辑，没有将 TCP 连接与 UDP 会话相关联，因此 TCP 连接断开时，UDP 会话不会受到影响；
* `self._stage = STAGE_UDP_ASSOC` 使得当前的 `TCPRelayHandler` 进入 `STAGE_UDP_ASSOC` 阶段，忽略来自 TCP 的数据；

## _handle_server

`_handle_server` 函数处理传输阶段的数据，负责将来自客户端的数据转发给服务器。我们简化逻辑，去掉一些非核心的代码：

```python
def _handle_server(self):
    # r_addr: 发送 UDP 数据包的地址与端口
    data, r_addr = self._server_socket.recvfrom(BUF_SIZE)

    if self._is_local:
        # +----+------+------+----------+----------+----------+
        # |RSV | FRAG | ATYP | DST.ADDR | DST.PORT |   DATA   |
        # +----+------+------+----------+----------+----------+
        #      ~~~~~~~~
        frag = common.ord(data[2])
        if frag != 0:
            logging.warn('UDP drop a message since frag is not 0')
            return
        else:
            # +------+----------+----------+----------+
            # | ATYP | DST.ADDR | DST.PORT |   DATA   |
            # +------+----------+----------+----------+
            data = data[3:]
    else:
        # ssserver 解密来自 sslocal 的数据
        data, _key, _iv = encrypt.dencrypt_all(self._password, self._method, data)
        if not data:
            logging.debug('UDP handle_server: data is empty after decrypt')
            return

    header_result = parse_header(data)
    if header_result is None:
        return
    # +------+----------+----------+----------+
    # | ATYP | DST.ADDR | DST.PORT |   DATA   |
    # +------+----------+----------+----------+
    # .                            .
    # |<----- header_length ------>|
    addrtype, dest_addr, dest_port, header_length = header_result

    if self._is_local:
        # ssserver 地址和端口
        server_addr, server_port = self._get_a_server()
    else:
        # 「目标服务器」地址和端口
        server_addr, server_port = dest_addr, dest_port

    # 从缓存中取 server_addr 解析后的地址
    addrs = self._dns_cache.get(server_addr, None)
    # 如果找不到，则解析 server_addr 的地址并存入缓存
    if addrs is None:
        # 注意，getaddrinfo 函数是阻塞的
        addrs = socket.getaddrinfo(server_addr, server_port, 0,
                                   socket.SOCK_DGRAM, socket.SOL_UDP)
        if not addrs:
            return
        else:
            self._dns_cache[server_addr] = addrs

    af, socktype, proto, canonname, sa = addrs[0]
    # 根据地址、端口、af 生成一个 key，这个 key 与 UDP 套接字一一对应
    key = client_key(r_addr, af)
    # client 与 server_socket 的关系类似于 TCPRelay 与 TCPRelayHandler 的关系，
    # 同时一个 client 对应于一个 UDP 会话
    client = self._cache.get(key, None)
    # 如果缓存中找不到 key 对应的 UDP 套接字
    if not client:
        # 创建 UDP 套接字
        client = socket.socket(af, socktype, proto)
        client.setblocking(False)
        self._cache[key] = client
        # 将套接字与其地址关联起来，`_handle_client` 会用到
        self._client_fd_to_server_addr[client.fileno()] = r_addr
        # 将套接字关联的文件描述符加入 `self._sockets` 中，`handle_event` 会用到
        self._sockets.add(client.fileno())
        # 将套接字加入事件循环，
        self._eventloop.add(client, eventloop.POLL_IN, self)

    # 如果是 sslocal，那么需要将数据加密
    if self._is_local:
        key, iv, m = encrypt.gen_key_iv(self._password, self._method)
        data = encrypt.encrypt_all_m(key, iv, m, self._method, data)
        if not data:
            return
    # 如果是 ssserver，在将接收到的数据发送给目标服务器之前，
    # 需要解密并且去掉头部，解密在上面已经完成了
    else:
        # +------+----------+----------+----------+
        # | ATYP | DST.ADDR | DST.PORT |   DATA   |
        # +------+----------+----------+----------+
        #                              ~~~~~~~~~~~~
        data = data[header_length:]
    if not data:
        return

    # - 对于 sslocal 而言，将加密后的数据发送给 ssserver，数据格式如下：
    #
    #    +------+----------+----------+----------+
    #    | ATYP | DST.ADDR | DST.PORT |   DATA   |
    #    +------+----------+----------+----------+
    #
    # - 对于 ssserver 而言，将解密后的数据发送给目标服务器（只剩 `DATA` 部分了）
    client.sendto(data, (server_addr, server_port))
```

相信加上注释以后，上面的代码理解起来不会有很大的问题。接下来我们看看这段代码对 `sslocal` 和 `ssserver` 而言分别实现了什么功能。

* 对于 `sslocal` 而言：

    1. 接收来自 SOCKS5 客户端的数据，将它的地址和端口存放到 `r_addr`；
    2. 效验传输阶段 UDP 数据包的头部，如果 `FRAG` 字段不为 0 则丢弃该数据包（详见 [RFC 1928](https://www.ietf.org/rfc/rfc1928.txt) 第 7 页）；
    3. 获取 ssserver 地址；
    4. 找到与 `r_addr` 相关联的 UDP 套接字，该套接字用于接收来自 `ssserver` 的数据；
    5. 将数据加密；
    6. 发送给 `ssserver`；

* 对于 `ssserver` 而言：

    1. 解密来自 `sslocal` 的数据；
    2. 解析 shadowsocks 头部（注意与 SOCKS5 协议的头部不是同一个东西），得到「目标服务器」的地址和端口；
    3. 找到与 `r_addr` 相关联的 UDP 套接字，该套接字用于接收来自目标服务器的数据；
    4. 去掉 shadowsocks 头部，此时 `data` 只是单纯的数据了（即[传输阶段](#_3)中的 `b'1'`）；
    5. 将数据发送给目标服务器。


只不过第 55 行到第 72 行的意图可能不是那么直观，此处暂且不提，下文会做分析，我们思考这么一个问题：服务器收到客户端的数据包后，想要回复数据给这个客户端，该怎么实现？

## _handle_client

`_handle_client` 函数负责接收服务器回复给客户端的数据，并将其转发给客户端。我们去掉一些非核心的代码：

```python
def _handle_client(self, sock):
    # 接收来自服务器的数据
    # r_addr: 服务器的地址与端口
    data, r_addr = sock.recvfrom(BUF_SIZE)
    if not data:
        logging.debug('UDP handle_client: data is empty')
        return
    # ssserver
    if not self._is_local:
        addrlen = len(r_addr[0])
        if addrlen > 255:
            # drop
            return
        # |    pack_addr    |   pack   |
        # .                 .          .
        # +------+----------+----------+----------+
        # | ATYP | DST.ADDR | DST.PORT |   DATA   |
        # +------+----------+----------+----------+
        data = pack_addr(r_addr[0]) + struct.pack('>H', r_addr[1]) + data
        # `1` 表示加密
        response = encrypt.encrypt_all(self._password, self._method, 1, data)
        if not response:
            return
    # sslocal
    else:
        # `0` 表示解密
        data = encrypt.encrypt_all(self._password, self._method, 0, data)
        if not data:
            return
        header_result = parse_header(data)
        if header_result is None:
            return
        # \x00\x00\x00
        # +----+------+------+----------+----------+----------+
        # |RSV | FRAG | ATYP | DST.ADDR | DST.PORT |   DATA   |
        # +----+------+------+----------+----------+----------+
        #             .                                       .
        #             |<--------------- data ---------------->|
        response = b'\x00\x00\x00' + data
    # 这里的 sock 就是 _handle_server 中的 client
    client_addr = self._client_fd_to_server_addr.get(sock.fileno())
    # 通过 _server_socket 将数据发送到 client 对应的地址
    if client_addr:
        self._server_socket.sendto(response, client_addr)
    else:
        # this packet is from somewhere else we know
        # simply drop that packet
        pass
```

* 对于 `sslocal` 而言：

    1. 接收来自 `ssserver` 的数据；
    2. 解密数据，分析头部，组成符合 SOCKS5 协议的 UDP 数据包；
    3. 通过 `self._server_socket` 将数据包发给 `sock` 对应的地址与端口（SOCKS5 客户端）；

* 对于 `ssserver` 而言：

    1. 接收来自目标服务器的数据，并将其地址和端口存到 `r_addr`；
    2. 组成 shadowsocks 头部（再次注意与 SOCKS5 协议头部的区别），加密数据；
    3. 通过 `self._server_socket` 将数据包发给 `sock` 对应的地址与端口（`sslocal`）；

# 总结

shadowsocks 对于 UDP 代理的实现相比 TCP 要简单不少，代码理解起来也没那么困难，反倒是在读完 TCP 部分的实现后，会对 UDP 的实现产生一些干扰。因为：

* `_handle_server` 和 `_handle_client` 的命名也不是很贴切；
* `TCPRelayHandler` 唯一对应了某个客户端的会话，而 `UDPRelay` 是通过 `client` 来实现的；

还需要注意 `sslocal` 与 `ssserver` 之间的通讯不是 SOCKS5 协议，而是 shadowsocks 自己的协议。

![socks5-ss-difference](https://loggerhead.me/_images/socks5-ss-difference.png)

理解 shadowsocks 源码最重要的是弄清楚每个角色负责什么功能，从业务的角度去考虑，理解起来也就不是问题了。
