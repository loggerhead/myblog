title: Shadowsocks 源码分析——超时处理
date: 2017-1-20 10:00
tags: 源码分析, Python

Shadowsocks 是一款性能很不错的代理工具，它的高性能体现在两个方面：速度快、资源占用少。相信你在读完「[协议与结构](/posts/shadowsocks-yuan-ma-fen-xi-xie-yi-yu-jie-gou.html)」和「[TCP 代理](/posts/shadowsocks-yuan-ma-fen-xi-tcp-dai-li.html)」这两篇文章后，就能理解为什么 shadowsocks 的速度快了[^not-understand]。资源占用少主要是因为 shadowsocks 使用了事件循环而不是多线程，另一方面，及时的进行超时和异常处理，能够将空闲的资源回收再利用也是原因之一。本文基于 [2.9.0 版本的源码](https://github.com/loggerhead/shadowsocks/tree/8e8ee5d490ce319b8db9b61001dac51a7da4be63)介绍 `tcprelay.py` 如何进行超时处理。

[^not-understand]: 如果读完还是不能理解，可能是我遗漏了某些细节，或者没写明白 :P ，欢迎把疑问或建议[发邮件](mailto:lloggerhead@gmail.com)告诉我，或者留言在相应文章下面

<!--- SUMMARY_END -->

[TOC]

# 超时处理

超时是网络编程中常见的一种需要处理的情况，如果不进行处理，会使得不活跃的 TCP 连接占用不必要的资源。Shadowsocks 经常被运行在内存很小的 VPS 上，所以这部分的处理是必要的。与之相关的函数有：

* TCPRelayHandler
    * `update_activity`: 只是简单的调用了 `TCPRelay.update_activity`；
    * `destroy`: 销毁对象；
* TCPRelay
    * `handle_periodic`: 调用 `_sweep_timeout` 定期清理一段时间内不活跃的 `TCPRelayHandler`；
    * `update_activity`: 更新超时队列；
    * `_sweep_timeout`: 清理超时队列；
    * `remove_handler`: 将相关的 `TCPRelayHandler` 从超时队列中删除。

其中的关键是 `EventLoop.run`、`TCPRelay._sweep_timeout` 和 `TCPRelay.update_activity`，其它的函数在弄懂它们仨的逻辑后就很容易懂了。

## EventLoop.run

我们把不相关的代码去掉，简化逻辑：

```python
def run(self):
    while not self._stopping:
        asap = False
        try:
            events = self.poll(TIMEOUT_PRECISION)
        except (OSError, IOError) as e:
            if errno_from_exception(e) in (errno.EPIPE, errno.EINTR):
                # EPIPE: Happens when the client closes the connection
                # EINTR: Happens when received a signal
                # handles them as soon as possible
                asap = True
            else:
                continue
        ...
        now = time.time()
        if asap or now - self._last_time >= TIMEOUT_PRECISION:
            for callback in self._periodic_callbacks:
                callback()
            self._last_time = now
```

这段代码的关键在于最后五行代码：

* 每隔 `TIMEOUT_PRECISION`（取值为 10）秒调用在 `self._periodic_callbacks` 中的所有回调函数；
* 如果 `self.poll` 抛出异常是因为收到了信号或者断开了连接，那么立即调用所有的回调函数；

`self._periodic_callbacks` 是通过 `add_periodic` 函数来添加回调函数的，我们在项目中搜索它，会发现它在 `TCPRelay`、`UDPRelay` 和 `DNSResolver` 的 `add_to_loop` 中出现：

```python
loop.add_periodic(self.handle_periodic)
```

所以，上述代码中的 `callback` 其实就是 `TCPRelay.handle_periodic`、`UDPRelay.handle_periodic` 或 `DNSResolver.handle_periodic`。

## TCPRelay.update_activity

我们删除注释，简单的改写代码：

```python
def update_activity(self, handler, data_len):
    now = int(time.time())
    # lower timeout modification frequency
    if now - handler.last_activity >= eventloop.TIMEOUT_PRECISION:
        handler.last_activity = now
        index = self._handler_to_timeouts.get(hash(handler), -1)
        if index >= 0:
            # delete is O(n), so we just set it to None
            self._timeouts[index] = None
        self._timeouts.append(handler)
        self._handler_to_timeouts[hash(handler)] = len(self._timeouts) - 1
```

它会每隔 10 秒以上更新一次超时队列（`self._timeouts`），将 `handler` 挪到队列尾。这里有几个小细节：

* 在真实场景中，活跃的 TCP 连接会使得 `update_activity` 被频繁调用，第一个 `if` 降低了超时队列被更新的频率[^lower-modify]；
* 因为 `self._handler_to_timeouts` 是一个字典，所以需要 `hash(handler)` 才能将 `handler` 映射为 key 来使用；
* `self._timeouts[index] = None` 通过使用 `None` 来占位，使得删除操作的复杂度为 O(1)；
* 最后一行将 `handler` 在超时队列中的下标保存到 `self._handler_to_timeouts` 中。

[^lower-modify]: `if` 里面的语句时间复杂度是 O(1)，似乎这个 `if` 是多余的，可能是作者考虑到能降低 CPU 占用率吧

## TCPRelay._sweep_timeout

重头戏来了，`_sweep_timeout` 是整个超时处理部分最难懂也是最核心的函数。我们去除日志和注释，将该函数的代码转换为等价的逻辑：

```python
def _sweep_timeout(self):
    if self._timeouts:
        now = time.time()
        pos = self._timeout_offset
        while pos < len(self._timeouts):
            handler = self._timeouts[pos]
            if handler:
                if now - handler.last_activity < self._timeout:
                    break
                # timeout
                else:
                    handler.destroy()
                    self._timeouts[pos] = None
                    pos += 1
            else:
                pos += 1

        clean_size = max(TIMEOUTS_CLEAN_SIZE, len(self._timeouts) / 2)
        if pos > clean_size:
            self._timeouts = self._timeouts[pos:]
            for key in self._handler_to_timeouts:
                self._handler_to_timeouts[key] -= pos
            pos = 0
        self._timeout_offset = pos
```

`self._timeout_offset` 记录了每次停止清理前，最后停留的位置，它的初始值是 0。第 4、5 行会从每次清理结束的位置重新开始遍历超时队列，继续这次的清理（类似于下载软件的「断点续传」功能）。循环的逻辑是：

1. 从上次中断的位置（`self._timeout_offset`）开始遍历超时队列（`self._timeouts`）；
2. 如果没有超时，说明后面的 `handler` 都没有超时，此时退出循环，避免对整个队列进行遍历，降低运算时间；否则销毁超时的 `TCPRelayHandler`。这里告诉我们 `self._timeouts` 实际上是个优先级队列，`TCPRelay.update_activity` 函数的最后两行保证了它的元素有序，所以才会有「如果没有超时，说明后面的 `handler` 都没有超时」；

接下来调整 `self._timeouts` 的大小，收回多余的空间。此处的 `if` 使得只有在超时的 `handler` 达到一定数量以后（`pos` 变量同时起到了游标和计数的功能），才调整 `self._timeouts` 的大小。因为 `self._timeouts` 是优先级队列，`pos` 之前的都超时了，这部分空间应该回收，所以列表里面的元素全部往前挪 `pos` 个位置就行了。

# 总结

在分析完 `EventLoop.run`、`TCPRelay._sweep_timeout` 和 `TCPRelay.update_activity` 三个函数以后，我们可以把超时处理的整个过程整理一下：

* 在事件循环中每隔 10 秒清理一次超时队列；
* `TCPRelayHandler` 对象通过调用 `update_activity` 将自己挪到超时队列的队尾。

其中 `TCPRelayHandler.update_activity` 在三个函数中被调用：

* `__init__`
* `_on_local_read`
* `_on_remote_read`

总的来说，shadowsocks 的超时算法还是挺有趣的，同时权衡了时间和空间，值得我们学习。
