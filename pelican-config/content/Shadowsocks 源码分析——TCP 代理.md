title: Shadowsocks 源码分析——TCP 代理
date: 2017-1-4 10:40
tags: 源码分析, Python

[Shadowsocks 源码分析——协议与结构](/posts/shadowsocks-yuan-ma-fen-xi-xie-yi-yu-jie-gou.html) 已经对 shadowsocks 进行了大体上的分析，我们进一步的深入，来了解 shadowsocks 真正的核心——TCP 代理。

<!--- SUMMARY_END -->

[TOC]

# TCPRelay

[前文](/posts/shadowsocks-yuan-ma-fen-xi-xie-yi-yu-jie-gou.html#eventlooppy)已经说过了，shadowsocks 是一个反应器模式，它会在 eventloop 中将事件一层一层的传递给真正的处理者。

![reactor](https://loggerhead.me/_images/ss-reactor-pattern.png)

和 TCP 相关的任何事件，首先会经过 `TCPRelay` 之手，根据事件对应的套接字执行不同的逻辑，具体的代码是（删除了部分日志相关的代码）：

```python
def handle_event(self, sock, fd, event):
    # 如果是 TCPRelay 的 socket
    if sock == self._server_socket:
        if event & eventloop.POLL_ERR:
            raise Exception('server_socket error')
        try:
            conn = self._server_socket.accept()
            TCPRelayHandler(self, self._fd_to_handlers,
                            self._eventloop, conn[0], self._config,
                            self._dns_resolver, self._is_local)
        except (OSError, IOError) as e:
            error_no = eventloop.errno_from_exception(e)
            if error_no in (errno.EAGAIN, errno.EINPROGRESS,
                            errno.EWOULDBLOCK):
                return
            else:
                shell.print_exception(e)
                if self._config['verbose']:
                    traceback.print_exc()
    # 如果是 TCPRelayHandler 的 socket
    else:
        if sock:
            handler = self._fd_to_handlers.get(fd, None)
            if handler:
                handler.handle_event(sock, event)
        else:
            logging.warn('poll removed fd')
```

如果发生事件的套接字是 `TCPRelay` 它自己的，那么 `accept()` 建立一个新的 TCP 连接，并且创建一个 `TCPRelayHandler` 对象来负责处理它；否则，说明发生事件的套接字是 `TCPRelayHandler` 的，此时根据 `fd` 找到对应的 `handler`，并调用它的 `handle_event` 来处理事件。

注意到调用 `accept()` 之前没有对事件类型进行判断，说明这个 `event` 一定是 `eventloop.POLL_IN`。我们看到 `add_to_loop` 这个函数：

```python
def add_to_loop(self, loop):
    if self._eventloop:
        raise Exception('already add to loop')
    if self._closed:
        raise Exception('already closed')
    self._eventloop = loop
    self._eventloop.add(self._server_socket,
                        eventloop.POLL_IN | eventloop.POLL_ERR, self)
    self._eventloop.add_periodic(self.handle_periodic)
```

确实只注册了读事件，证实了我们的猜想。再回头看看 `TCPRelay` 的初始化：

```python
addrs = socket.getaddrinfo(listen_addr, listen_port, 0,
                           socket.SOCK_STREAM, socket.SOL_TCP)
if len(addrs) == 0:
  raise Exception("can't get addrinfo for %s:%d" % (listen_addr, listen_port))
af, socktype, proto, canonname, sa = addrs[0]

server_socket = socket.socket(af, socktype, proto)
server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server_socket.bind(sa)
server_socket.setblocking(False)
server_socket.listen(1024)
self._server_socket = server_socket
```

上面是 `__init__` 函数的部分代码。可以看到第 1 行调用了会阻塞的函数 `getaddrinfo` 进行地址解析[^getaddrinfo]。比如：它能将 `localhost.loggerhead.me` 或 `localhost` 解析成 `127.0.0.1`，这也是为什么 shadowsocks 的服务器地址可以填域名的原因。可以看出 `self._server_socket` 是一个典型的 TCP 服务器套接字，说明 `TCPRelay` 只是个普通的 TCP 服务器，只不过兼任了转发事件的功能。

其它的函数，诸如：`update_activity`、`handle_periodic` 等，都是用来处理超时的，本文暂且不提。

[^getaddrinfo]: `getaddrinfo` 在 C 语言中有同名函数，用于进行名字与地址的转换，支持 IPv4 和 IPv6。

# TCPRelayHandler

在事件经由 `TCPRelay` 转发给 `TCPRelayHandler` 以后，`handle_event` 会负责处理这个事件。它会进一步根据事件的种类，调用相应的函数进一步处理，某种意义上来说也是转发。

```python
def handle_event(self, sock, event):
    if self._stage == STAGE_DESTROYED:
        logging.debug('ignore handle_event: destroyed')
        return

    if sock == self._remote_sock:
        ...
    elif sock == self._local_sock:
        if event & eventloop.POLL_ERR:
            self._on_local_error()
            if self._stage == STAGE_DESTROYED:
                return
        if event & (eventloop.POLL_IN | eventloop.POLL_HUP):
            self._on_local_read()
            if self._stage == STAGE_DESTROYED:
                return
        if event & eventloop.POLL_OUT:
            self._on_local_write()
    else:
        logging.warn('unknown socket')
```

`handle_event` 会根据事件发生的套接字决定调用的函数，这里涉及到 `self._remote_sock` 和 `self._local_sock` 两个套接字，它俩在很多方面都是对称、相似的，比如：`if` 代码块与 `elif` 代码块中的代码是一模一样的，只是 `remote` 换成了 `local`，所以这里省略了。那么这两个套接字有什么用呢？此处出现的 `self._stage` 又是干什么的？为了解答这两个问题，我们得先介绍几个概念。

## 命名约定

每一个 TCP 连接，都由一个 `TCPRelayHandler` 处理，而每一个 `TCPRelayHandler` 又都有两个套接字。

![ss-socks](https://loggerhead.me/_images/ss-socks.png)

如图所示，黄色圆点表示 `local_sock`，绿色圆点表示 `remote_sock`。

* 对于 `sslocal` 而言，`local` 指 SOCKS5 客户端，`remote` 指 `ssserver`；
* 对于 `ssserver` 而言，`local` 指 `sslocal`，`remote` 指目标服务器；

所以 `local_sock` 就是专门负责与左边通信的套接字，`remote_sock` 是专门负责与右边通信的套接字。另外，需要注意的是因为 shadowsocks 客户端和服务器重用了绝大部分的代码，所以在判断当前程序是当做 `sslocal` 还是 `ssserver` 用时会用一个变量 `is_local` 来判断，这里的 `local` 指的是 `sslocal`。

为了区分，「客户端」指 `sslocal` 左边的 SOCKS5 客户端，「ss 客户端」指 `sslocal`。

## _on_local_read 函数

上面提到 `handle_event` 函数，我们注意到当发生事件的套接字是 `local_sock` 时，只涉及到三个函数，分别对应于几种事件：

* `OLL_ERR`: `self._on_local_error()`
* `OLL_IN` 或 `POLL_HUP`: `self._on_local_read()`
* `OLL_OUT`: `self._on_local_write()`

其中 `eventloop.POLL_HUP` 事件发生说明套接字关闭了。我们进一步的分析 `_on_local_read` 函数：

```python
def _on_local_read(self):
   # 防御性编程，完全是多余的
   if not self._local_sock:
       return
   is_local = self._is_local
   # 接受至多 BUF_SIZE 大小的数据，如果此时发生异常，那么分两种情况处理：
   # 1. 如果异常产生的原因是 `ETIMEDOUT`, `EAGAIN` 或 `EWOULDBLOCK` 则返回
   # 2. 否则直接销毁当前的 TCPRelayHandler
   data = None
   try:
       data = self._local_sock.recv(BUF_SIZE)
   except (OSError, IOError) as e:
       if eventloop.errno_from_exception(e) in \
               (errno.ETIMEDOUT, errno.EAGAIN, errno.EWOULDBLOCK):
           return
   if not data:
       self.destroy()
       return

   # 重置计时器
   self._update_activity(len(data))

   # 如果 data 是 sslocal 发送过来的，则解密数据
   if not is_local:
       data = self._encryptor.decrypt(data)
       if not data:
           return

   # 典型的状态机，根据当前的状态执行相应的函数
   if self._stage == STAGE_STREAM:
       self._handle_stage_stream(data)
       return
   elif is_local and self._stage == STAGE_INIT:
       self._handle_stage_init(data)
   elif self._stage == STAGE_CONNECTING:
       self._handle_stage_connecting(data)
   elif (is_local and self._stage == STAGE_ADDR) or \
           (not is_local and self._stage == STAGE_INIT):
       self._handle_stage_addr(data)
```

`_on_local_read` 会从 `local_sock` 读数据，并根据状态，将数据交由不同的函数处理。`self._stage` 记录了对应的状态，它的取值如下：

* `TAGE_INIT`: SOCKS5 的握手阶段，协商采用的认证方式；
* `TAGE_ADDR`：SOCKS5 建立连接阶段，对 `remote` 进行 DNS 查询；
* `TAGE_UDP_ASSOC`：与 UDP 代理相关；
* `TAGE_DNS`：正在进行 DNS 查询；
* `TAGE_CONNECTING`：正在建立 TCP 连接；
* `TAGE_STREAM`：SOCKS5 传输阶段；
* `TAGE_DESTROYED`：`TCPRelayHandler` 已经被销毁。

我从 `_on_local_read` 的代码可以看出，只有四种状态对应了相关的执行函数：

* `TAGE_INIT`: `self._handle_stage_init`；
* `TAGE_ADDR`：`self._handle_stage_addr`；
* `TAGE_CONNECTING`：`self._handle_stage_connecting`；
* `TAGE_STREAM`：`self._handle_stage_stream`。

其的状态 `STAGE_UDP_ASSOC`、`STAGE_DNS`、`STAGE_DESTROYED` 都只是作为一个标记，并不导致状态改变。既然整个 `TCPRelayHandler` 是一个状态机，那么它的起始状态至关重要，我们到 `__init__` 函数中发现无论是 `sslocal` 还是 `ssserver`，起始状态都是 `STAGE_INIT`，但是注意到 `_on_local_read` 中的几行：

```python
   elif (is_local and self._stage == STAGE_ADDR) or \
           (not is_local and self._stage == STAGE_INIT):
       self._handle_stage_addr(data)
```

还记得[前文](/posts/shadowsocks-yuan-ma-fen-xi-xie-yi-yu-jie-gou.html)里有提过：

> 可以看出来，SOCKS5 服务器的实现被拆分成了两部分：
>
> * sslocal 负责与 SOCKS5 客户端进行 SOCKS5 协议相关的通讯（握手并建立连接），在建立连接后将 SOCKS5 客户端发来的数据加密并发送给 ssserver；
> * ssserver 起到一个中继的作用，负责解密以后将数据转发给目标服务器，并不涉及 SOCKS5 协议的任何一部分。

所以 `ssserver` 真正的起始状态是 `STAGE_ADDR` 而不是 `STAGE_INIT`，因为 `ssserver` 不负责 SOCKS5 的握手协商。整个状态的转移过程如下（省略了前缀 `STAGE_`，下文同）：

* `slocal`: `INIT` -> `ADDR` -> `DNS` -> `CONNECTING` -> `STREAM` -> `DESTROYED`；
* `sserver`: `ADDR` -> `...`；

总结一下，`_on_local_read` 函数会在 `self._local_sock` 可读时被 `_handle_event` 调用。它会根据当前的 `self._stage` 调用对应的函数处理读到的数据 `data`。

## _on_local_XXX / _on_remote_XXX 函数

除了 `_on_local_read` 与 `_on_remote_read` 以外，以 `_on` 开头的另外四个函数有着类似的结构和功能，它们都是在对应的套接字发生对应的事件时被 `_handle_event` 函数调用。其中函数与套接字的对应关系如下：

* `on_local_XXX` 对应于 `self._local_sock`；
* `on_remote_XXX` 对应于 `self._remote_sock`；

`_on_local_XXX` / `_on_remote_XXX` 对应的事件，以及对应的功能如下表所示：

| 数名  |    事件    |                                              功能                                             |
|--------|------------|-----------------------------------------------------------------------------------------------|
| `rror` | `POLL_ERR` | 写日志并调用 `self.destroy` 进行销毁                                                          |
| `rite` | `POLL_OUT` | 如果 `self._data_to_write_to_XXX` 有数据，则写入 `self._XXX_sock`；否则，更新套接字监听的事件 |

这里大体的提一下，具体的细节我们稍后再看。

## _handle_XXX 函数

`_handle_XXX` 函数负责了 SOCKS5 协议的相关通讯，控制了 shadowsocks 内部状态机的转移，是整个系统最为重要的部分。

### _handle_stage_init

`_handle_stage_init` 函数完成了 SOCKS5 的认证方式协商，如果协商成功，则通过 `self._stage = STAGE_ADDR` 将状态转移为 `STAGE_ADDR`。如果协商失败，则直接销毁。这里再次强调一下，因为整个 SOCKS5 协议都是在 `sslocal` 完成的，所以这个函数只可能被 `sslocal` 调用。

### _handle_stage_addr

这个函数乍看下去挺复杂的，不过当我们把 one time auth 和 UDP 部分给剔除，并删掉了一些日志以后，代码就简化了不少：

```python
def _handle_stage_addr(self, data):
    if self._is_local:
        cmd = common.ord(data[1])
        if cmd == CMD_UDP_ASSOCIATE:
            ...
            self._stage = STAGE_UDP_ASSOC
            return
        elif cmd == CMD_CONNECT:
            # just trim VER CMD RSV
            data = data[3:]
        else:
            logging.error('unknown command %d', cmd)
            self.destroy()
            return

    header_result = parse_header(data)
    if header_result is None:
        raise Exception('can not parse header')

    addrtype, remote_addr, remote_port, header_length = header_result
    self._remote_address = (common.to_str(remote_addr), remote_port)
    # pause reading
    self._update_stream(STREAM_UP, WAIT_STATUS_WRITING)
    self._stage = STAGE_DNS

    if self._is_local:
        # forward address to remote
        self._write_to_sock((b'\x05\x00\x00\x01'
                             b'\x00\x00\x00\x00\x10\x10'),
                            self._local_sock)
        data_to_send = self._encryptor.encrypt(data)
        self._data_to_write_to_remote.append(data_to_send)
        # notice here may go into _handle_dns_resolved directly
        self._dns_resolver.resolve(self._chosen_server[0],
                                   self._handle_dns_resolved)
    else:
        if len(data) > header_length:
            self._data_to_write_to_remote.append(data[header_length:])
        # notice here may go into _handle_dns_resolved directly
        self._dns_resolver.resolve(remote_addr,
                                   self._handle_dns_resolved)
```

对于 `sslocal` 而言，这段代码实际上就是[前文](/posts/shadowsocks-yuan-ma-fen-xi-xie-yi-yu-jie-gou.html#_2)中建立连接部分的实现，我们回忆一下 SOCKS5 请求的格式：

```
+----+-----+-------+------+----------+----------+
|VER | CMD |  RSV  | ATYP | DST.ADDR | DST.PORT |
+----+-----+-------+------+----------+----------+
| 1  |  1  |   1   |  1   | Variable |    2     |
+----+-----+-------+------+----------+----------+
```

Shadowsocks 只在握手阶段检查了 `VER` 字段，之后就不管这个字段了。所以 `_handle_stage_addr` 中只对 `CMD` 字段进行了检查，也就是第 2 到第 14 行。当执行到第 16 行时，`data` 的取值符合如下格式：

```
+------+----------+----------+------+
| ATYP | DST.ADDR | DST.PORT | DATA |
+------+----------+----------+------+
|  1   |    n     |    2     |  m   |
+------+----------+----------+------+
```

其中，`ATYP`、`DST.ADDR` 和 `DST.PORT` 在 shadowsocks 的源码中被称作 `header`，所以变量 `addrtype`、`remote_addr`、`remote_port` 分别对应了 header 中的字段 `ATYP`、`DST.ADDR`、`DST.PORT`，而 `header_length` 等于 `1 + n + 2`。

第 26 行的 `if` 逻辑块大体上做了两件事：

1. 将 `data` 保存到发送缓冲区 `self._data_to_write_to_remote`；
2. 调用 `self._dns_resolver` 进行 DNS 查询，在查询有结果后回调 `self._handle_dns_resolved`。

  但是对于 `sslocal` 和 `ssserver`，它们在细节上又有所不同：

* 对于 `sslocal`：

    + 它需要发送 SOCKS5 响应，完成建立连接的过程；
    + 在将数据保存到缓冲区之前，需要先加密（所有发送到 `ssserver` 的数据都要先加密）；
    + 因为数据要发送给 `ssserver`，所以 DNS 解析的是 `self._chosen_server`；

* 对于 `ssserver`：

    + 需要从收到的 `data` 中去除 header 再保存到缓冲区，因为对于 remote（目标服务器）而言，代理对它是透明的；
    + DNS 解析的是 remote，即 header 中的 `DST.ADDR`。

`_handle_stage_addr` 函数的整个执行过程可以用下图表示：

![handle_stage_addr](https://loggerhead.me/_images/handle_stage_addr.png)

其中，有向箭头表示数据流，虚线表示保存到缓冲区，蓝线表示进行 DNS 查询，橘黄色的框表示数据已经进行了加密，绿色的框表示数据已经进行了解密。在执行完 `_handle_stage_addr` 以后，状态转移到了 `STAGE_DNS`，同时对 `self._update_stream(STREAM_UP, WAIT_STATUS_WRITING)` 的调用，使得当前的 `TCPRelayHandler` 停止监听任何事件。也就是说，从现在开始，`TCPRelayHandler` 啥也不管了，直到 DNS 解析完成，调用 `self._handle_dns_resolved` 再继续干活。

### _handle_dns_resolved

我们去掉 [TCP fast open](https://en.wikipedia.org/wiki/TCP_Fast_Open) 和日志，只看 `_handle_dns_resolved` 最基础的形式：

```python
# result -> (hostname, ip)
def _handle_dns_resolved(self, result, error):
    if error:
        self.destroy()
        return
    if not (result and result[1]):
        self.destroy()
        return

    ip = result[1]
    self._stage = STAGE_CONNECTING
    remote_addr = ip
    if self._is_local:
        remote_port = self._chosen_server[1]
    else:
        remote_port = self._remote_address[1]

    remote_sock = self._create_remote_socket(remote_addr,
                                             remote_port)
    try:
        remote_sock.connect((remote_addr, remote_port))
    except (OSError, IOError) as e:
        pass
    self._loop.add(remote_sock,
                   eventloop.POLL_ERR | eventloop.POLL_OUT,
                   self._server)
    self._update_stream(STREAM_UP, WAIT_STATUS_READWRITING)
    self._update_stream(STREAM_DOWN, WAIT_STATUS_READING)
```

如果有错误发生或者没有 DNS 解析结果，则销毁 `TCPRelayHandler`；否则，创建一个负责与 remote 通信的套接字，连接到 `remote_addr:remote_port`，并添加到事件循环中监听 `POLL_OUT`（可写）。此时，状态转移到 `STAGE_CONNECTING`。

### _handle_stage_connecting

我们去掉 TCP fast open 和 [one time auth](shadowsocks.org/en/spec/one-time-auth.html) 相关的代码，将 `_handle_stage_connecting` 简化为如下逻辑：

```python
def _handle_stage_connecting(self, data):
    if self._is_local:
        data = self._encryptor.encrypt(data)
    self._data_to_write_to_remote.append(data)
```

将当前的 `data` 添加到缓冲区，如果是 `sslocal`，则加密以后再添加到缓冲区。

### _handle_stage_stream

去掉 one time auth 相关的代码，将逻辑简化：

```python
def _handle_stage_stream(self, data):
    if self._is_local:
        data = self._encryptor.encrypt(data)
    self._write_to_sock(data, self._remote_sock)
```

通过 `self._remote_sock` 套接字无脑将 `data` 中的数据转发到 remote，只不过 `sslocal` 在发送前要先加密。

## 事件与状态

之前我们略过了几个函数没讲：

* `_on_remote_read`；
* `_on_remote_write` / `_on_local_write`；
* `_update_steam`。

它们与 `_handle_XXX` 的耦合挺高的，单独拿出来会让人莫名其妙，上一张图大家就知道我为什么这么说了……

![ss-event-stage-relationship](https://loggerhead.me/_images/ss-event-stage-relationship.svg)

* 绿色二元组：表示 `self._downstream_status` 和 `self._upstream_status` 分别对应的值；
* 蓝色二元组：表示 `self._local_sock` 和 `self._remote_sock` 分别监听的事件，如果为空表示没有监听任何事件；
* 实线箭头：表示在下一次事件循环中，如果给定的套接字发生给定的事件，那么会调用哪个函数，比如：

    ```
    handle_stage_init -> Local:IN -> handle_stage_addr
    ```

    表示在调用完 `_handle_stage_init` 之后的下一次事件循环中，如果 `self._local_sock` 发生了可读事件，那么 `_handle_stage_addr` 会被调用；

* 虚线：与实线箭头一样，只不过目标是自身；
* 方框内的空心箭头：表示 `self._write_to_sock` 如果没有全部写成功时，可能发生的变化。

上图只是 `sslocal` 的事件-状态变化图，`ssserver` 的又略有不同，不过这些都不重要，只要弄明白了每个阶段（stage）分别是干嘛的，对应的监听事件应该怎么变化，就自然而然的明白，能够看懂上图了。

### _update_stream

`_update_stream` 会在 `self._XXX_status` 发生变化时，更新套接字监听的事件。具体的取值如表所示：

|  status |  events |
|---------|---------|
| (R, R)  | (I, I)  |
| (R, W)  | ( , IO) |
| (R, RW) | (I, IO) |
| (W, R)  | (IO, )  |

* status 对应的是二元组 `(self._downstream_status, self.upstream_status)`；
* events 对应的是二元组 `(self._local_sock, self._remote_sock)` 所监听的事件。

因为 status 在 shadowsocks 中只可能是以上四种取值，所以这里没有穷举 status 所有的可能。events 中出现的空缺表示只监听 `POLL_ERR` 事件，比如：`( , IO)` 表示 `self._local_sock` 监听 `POLL_ERR` 事件，`self._remote_sock` 监听 `POLL_IN | POLL_OUT | POLL_ERR` 事件。注意，在回调 `_handle_dns_resolved` 之前，`self._remote_sock` 的值为 `None`，`_update_stream` 不会影响 `self._remote_sock`。

除去 TCP fast open 相关的逻辑，我们看看所有的 `self._update_stream` 调用：

```python
def _handle_stage_addr(self, data):
    # ( , IO)
    self._update_stream(STREAM_UP, WAIT_STATUS_WRITING)

def _handle_dns_resolved(self, result, error):
    # (I, IO)
    self._update_stream(STREAM_UP, WAIT_STATUS_READWRITING)
    self._update_stream(STREAM_DOWN, WAIT_STATUS_READING)

def _on_local_write(self):
    if self._data_to_write_to_local:
        ...
    else:
        # self._remote_sock: POLL_IN
        self._update_stream(STREAM_DOWN, WAIT_STATUS_READING)

def _on_remote_write(self):
    if self._data_to_write_to_remote:
        ...
    else:
        # self._local_sock: POLL_IN
        self._update_stream(STREAM_UP, WAIT_STATUS_READING)

def _write_to_sock(self, data, sock):
    if uncomplete:
        if sock == self._local_sock:
            # self._local_sock: POLL_OUT
            self._update_stream(STREAM_DOWN, WAIT_STATUS_WRITING)
        elif sock == self._remote_sock:
            # self._remote_sock: POLL_OUT
            self._update_stream(STREAM_UP, WAIT_STATUS_WRITING)
    else:
        if sock == self._local_sock:
            # self._remote_sock: POLL_IN
            self._update_stream(STREAM_DOWN, WAIT_STATUS_READING)
        elif sock == self._remote_sock:
            # self._local_sock: POLL_IN
            self._update_stream(STREAM_UP, WAIT_STATUS_READING)
```

* `_handle_stage_addr`：因为 `self._remote_sock` 为 `None`，此时只有 `self._local_sock` 监听 `POLL_ERR` 事件。前面说过了，这个函数会通过 `self._dns_resolver` 解析 remote 对应的 IP，并在回调函数 `_handle_dns_resolved` 中创建 `self._remote_sock` 连接至 remote。如果 DNS 解析失败，那么将数据从 `self._local_sock` 读到缓冲区就毫无意义，白白消耗 CPU；
* `_handle_dns_resolved`：此时我们已经得到了 remote 的 IP，并尝试与 remote 建立 TCP 连接。因为此处的 `connect` 是非阻塞的[^non-blocking socket]，我们不知道什么时候成功建立了 TCP 连接，所以需要在 `self._remote_sock` 上注册 `POLL_OUT` 事件，当事件循环通知我们 `self._remote_sock` 可写时，说明连接成功。在建立连接的同时，我们将 `self._local_sock` 注册为可读，将客户端发来的数据缓冲起来（`_handle_stage_connecting`），降低延迟；
* `_on_local_write` / `_on_remote_write`：这两个函数是十分相似的。它们会将缓冲区的数据发送出去，如果缓冲区空了，则将另一个套接字注册为可读，因为只有它可读才可能重新塞入数据到缓冲区。有一点要注意，`_on_remote_write` 被调用说明 `self._remote_sock` 成功建立了连接，此时它会将 `self._stage` 设置为 `STAGE_STREAM`；
* `_write_sock`：负责将数据通过给定套接字发送出去，并改变对应的监听事件。如果全部发送成功，此时的动作和 `_on_XXX_write` 一样，将另一个套接字注册为可读；如果没有全部发送成功，则将剩余的数据添加到缓冲区，并将套接字注册为可写。

[^non-blocking socket]: `_create_remote_socket` 中的 `remote_sock.setblocking(False)` 将套接字设置为了非阻塞的，此时对 `connect` 的调用要么立刻成功建立 TCP 连接，要么抛出含有 `errno.EINPROGRESS` 的异常。

### _on_remote_read

`_on_remote_read` 函数比较简单，我们看看简化后的代码：

```python
def _on_remote_read(self):
    try:
        data = self._remote_sock.recv(BUF_SIZE)
    except (OSError, IOError) as e:
        data = None
    if not data:
        self.destroy()
        return

    self._update_activity(len(data))

    if self._is_local:
        data = self._encryptor.decrypt(data)
    else:
        data = self._encryptor.encrypt(data)

    try:
        self._write_to_sock(data, self._local_sock)
    except Exception as e:
        self.destroy()
```

从 `self._remote_sock` 读取数据，并将读到的数据通过 `self._local_sock` 发送出去。对于 `sslocal` 而言，收到的数据来自 `ssserver`，需要解密以后再发送给客户端；对于 `ssserver` 而言，收到的数据来自目标服务器，需要加密以后再发送给 `sslocal`。

# 总结

理解 shadowsocks 的关键是理解 `TCPRelayHandler`，其中有些变量，如：`self._local_sock` 和 `self._remote_sock`，`self._downstream_status` 和 `self._upstream_status` 很让人迷惑，弄清楚它们的区别对于理解 `TCPRelayHandler` 至关重要。本文对大多数函数进行了分析，但是由于涉及的内容较多，限于篇幅，并未全部覆盖，比如：one time auth、TCP fast open、异步 DNS 以及超时处理都没有提及，可能之后会单独用几篇文章介绍这些内容。
