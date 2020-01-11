title: Gist SSH Timeout 原因    
date: 2015-09-17 22:28:06  
tags: Github, non-tech

最近 clone gist 的时候总是 timeout，Google 了一番，在 ssh 上找了半天原因后发现是因为 **GFW 把 Gist 给墙了**。

<!--- SUMMARY_END -->

```shell
$ git clone git@gist.github.com:48facfaab6db640c2b3f.git
Cloning into '48facfaab6db640c2b3f'...
ssh: connect to host gist.github.com port 22: Operation timed out
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

`ping gist.github.com` 会发现 GFW 返回了一个伪造的 IP，所以 ssh 连不上。解决办法有两种：

1. 因为 github.com 没被墙，所以将 `gist.github.com` 改成 `github.com` 就好了

    ```
    git@github.com:48facfaab6db640c2b3f.git
    ```

2. 用 [proxychains4](https://github.com/rofl0r/proxychains-ng)

    ```
    proxychains4 git clone git@gist.github.com:48facfaab6db640c2b3f.git
    ```

3. 用 VPN
