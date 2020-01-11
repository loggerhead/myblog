title: 求 Fibonacci 数列的 N 种算法    
date: 2015-10-28 21:58:40  
tags: 算法, Python  

高中学过一个神奇的数列——Fibonacci 数列，它的特点是：除了最初的两个 Fibonacci 数以外，其余的所有 Fibonacci 数都等于前两个 Fibonacci 数之和。表达成数学公式就是：

$$
F_{n}=\begin{cases}
      0               & n=0\\
      1               & n=1\\
      F_{n-1}+F_{n-2} & n\geq 2
      \end{cases}
$$

下面是 Fibonacci 数列的头几项（0 是第零项）。

$$0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233...$$

同时，Fibonacci 数列也出现在很多计算机相关的书上面，那么我们怎么编程求第 n 个 Fibonacci 数呢？[^source code]

[^source code]: 文中几种算法的实现可参考我的 [Gist](https://gist.github.com/loggerhead/6bf260918d07e10f273b)

<!--- SUMMARY_END -->

# $O(2^n), O(n)$
首先，很自然的想法是直接将通项公式“翻译”成代码。

```python
def fib1(n):
    if n == 0:
        return 0
    elif n == 1:
        return 1
    return fib1(n-1) + fib1(n-2)
```

几乎没什么难度，但是如果你这样就满足了，那只能说实在是 “too young, too simple”。这种算法存在一个很严重的问题——当输入稍微大一点的时候，比如：42，需要运行很久，速度非常慢。

原因在于，`fib1(n-1) + fib1(n-2)` 中的递归导致算法的时间复杂度是指数型的，也就是 $O(2^n)$[^fib1 time complexity]。假设计算 $F_n$ 需要 $T(n)$ 的运算时间，那么 $T(n)$ 等于计算 $F_{n-1}$ 和 $F_{n-2}$ 的时间加上一个常量 $C$（`if`、`+` 和 `return` 的时间）。

$$T(n)=T(n-1)+T(n-2)+C < 2\times T(n-1) = O(2^n) \qquad n\rightarrow\infty$$

[^fib1 time complexity]: $O(2^n)$ 是时间上界，精确的时间界是个无理数的 n 次幂

再来看 `fib1(n)` 的空间复杂度，容易发现递归的最大深度是 n，所以递归形成的隐式栈占用了 $O(n)$ 的空间，即空间复杂度为 $O(n)$。如果把递归过程看成一颗树，那么空间复杂度正比于树的高度，时间复杂度正比于树的节点数。

![complexity of fib1](https://loggerhead.me/_images/fib1.svg)

# $O(n), O(n)$
`fib1` 进行了很多重复运算，就 `fib1(4)` 来说，`fib1(2)` 被计算了 2 次。

![fib1_4](https://loggerhead.me/_images/fib1_4.svg)

发现了这一点后，我们将 `fib1` 进行改造，记录下每一个算出来的 $F_n$，避免重复计算，减少运行时间。

```python
def fib2(n, f={ 0: 0, 1: 1 }):
    if n in f:
        return f[n]
    f[n] = fib2(n-1) + fib2(n-2)
    return f[n]
```

如图，`fib2(4)` 在第一次计算 `fib2(2)` 时保存了结果，第二次计算 `fib2(2)` 时就不用再递归计算了，而是直接返回 `fib2(2)` 的值。

![fib2_4](https://loggerhead.me/_images/fib2_4.svg)

因为递归的最大深度没变，所以 `fib2` 的空间复杂度还是 $O(n)$。但是因为每个子问题只需要计算一次，所以时间复杂度变成了 $O(n)$。

$$T(n)=T(n-1)+T(n-2)+C=T(n-1)+C'+C=O(n) \qquad T(n-2)=C'$$

# $O(n), O(1)$
仔细观察递推公式 $F_{n}=F_{n-1}+F_{n-2}$，发现每次计算 $F_{n}$ 都只需要 $F_{n-1}$ 和 $F_{n-2}$ 两个值。利用这一点，我们可以用两个变量 `f2` 和 `f1` 分别记录计算 $F_{n}$ 所需要的 $F_{n-1}$ 和 $F_{n-2}$，而不是 $F_0, F_1, ..., F_n$ 的值，将空间复杂度降为 $O(1)$。

```python
def fib3(n):
    f1, f2 = 0, 1
    for i in xrange(n):
        f2, f1 = f2 + f1, f2
    return f1
```

`fib3(4)` 的计算过程如下图所示：

![fib3_4](https://loggerhead.me/_images/fib3_4.svg)

# $O(\log n), O(\log n)$
在介绍 $O(\log n)$ 的算法前，我们先考虑一下怎么计算 $2^n$。

```python
def pow2(n):
    p = 1
    for i in xrange(n):
        p *= 2
    return p
```

上述算法在计算 $2^8$ 时，`pow2(8)` 迭代过程中的 `p` 为：

$$1, 2, 4, 8, 16, 32, 64, 128, 256$$

也就是做了 8 次运算。但是如果把 $2^8$ 看成是 $2^4\times 2^4$，而不是 $2\times 2^7$，那么计算过程就变成了：

$$256=16\times 16, 16=4\times 4, 4=2\times 2$$

只需要 3 次运算。把这个想法提炼一下就有了下面这个 $O(\log n)$ 的递归式。

$$
2^{n}=\begin{cases}
      2\times 2^{n-1}                       & n=1,3,\cdots\\
      2^{\frac{n}{2}}\times 2^{\frac{n}{2}} & n=2,4,\cdots
      \end{cases}
$$

对于给定的 n，递归过程中每次 n 为偶数时，问题规模减半，而 n 为奇数的次数顶多比 n 为偶数的次数多一次。比如，求 $2^{15}$ 的递归过程中 n 的变化是：$15, 14, 7, 6, 3, 2, 1$。递归深度和运行时间都正比于问题规模减半的次数，所以时间复杂度和空间复杂度都是 $O(\log n)$。把整个想法用 python 实现就是：

```python
def pow2(n):
    if n == 0:
        return 1
    if n % 2 == 1:
        return 2*pow2(n-1)
    else:
        p = pow2(n/2)
        return p*p
```

重复平方技术也可以用在求 Fibonacci 数上。

##矩阵方法
把 `fib3` 中的变换：

$$
\begin{aligned}
f2' &= f2 + f1 \\
f1' &= f2  
\end{aligned}
$$

用矩阵表示就是：

$$
\begin{bmatrix}
f1' & f2'
\end{bmatrix}
=
\begin{bmatrix}
f1 & f2
\end{bmatrix}
\times
\begin{bmatrix}
0 & 1\\
1 & 1
\end{bmatrix}
$$

所以 Fibonacci 数列的通项公式可以用矩阵表示为：

$$
\begin{bmatrix}
F_n & F_{n+1}
\end{bmatrix}
=
\begin{bmatrix}
F_0 & F_1
\end{bmatrix}
\times
\begin{bmatrix}
0 & 1\\
1 & 1
\end{bmatrix}^n
$$

注意到其中二维矩阵的乘法也可以用重复平方技术大大减少运算时间：

$$
\begin{bmatrix}
0 & 1\\
1 & 1
\end{bmatrix}^n
=
\begin{cases}
\begin{bmatrix}
0 & 1\\
1 & 1
\end{bmatrix}
\times
\begin{bmatrix}
0 & 1\\
1 & 1
\end{bmatrix}^{n-1}         & n=1,3,\cdots\\
\begin{bmatrix}
0 & 1\\
1 & 1
\end{bmatrix}^{\frac{n}{2}}
\times
\begin{bmatrix}
0 & 1\\
1 & 1
\end{bmatrix}^{\frac{n}{2}} & n=2,4,\cdots
\end{cases}
$$

其实现为：

```python
def fib4(n):
    def calc_coefs(n):
        e = [[1, 0], 
             [0, 1]]
        c = [[0, 1], 
             [1, 1]]
        if n == 0:
            return e
        elif n == 1:
            return c
        # `n & 1` == `n % 2 == 1`
        if n & 1:
            # `mmul` == `Matrix Multiplication`
            return mmul(calc_coefs(n-1), c)
        else:
            coef = calc_coefs(n/2)
            return mmul(coef, coef)

    return mmul([[0, 1]], calc_coefs(n))[0][0]
```

##代数方法
再看看 `fib3` 中的变换：

$$
\begin{aligned}
f2' &= f2 + f1 \\
f1' &= f2 
\end{aligned}
$$

如果我们能找到一种方法把两次变换后的 $f2'', f1''$ 表示成 $f2, f1$，那不是又能用上重复平方技术了吗？上式等价于下式 $p=0, q=1$ 的特殊情况。

$$
\begin{aligned}
f2' &= f1\times q + f2\times q +f2\times p \\
f1' &= f1\times q+f2\times q
\end{aligned}
$$

将 $f2''$ 和 $f1''$ 做代换后发现，当 $p'=p^2+q^2, q'=q^2+2qp$ 时，下式成立：

$$
\begin{aligned}
f2'' &= f1'\times q + f2'\times q +f2'\times p    \\
     &= f1\times p' + f2'\times q' + f2'\times p' \\
\\
f1'' &= f1'\times q+f2'\times q                   \\
     &= f1\times q' + f2'\times q                 
\end{aligned}
$$

这样就能用算 $2^n$ 的方法来实现下面这种算法了。

```python
def fib5(n):
    def fib_iter(n, f2, f1, p, q):
        if n == 0:
            return f1
        if n & 1:
            return fib_iter(n-1, f1*q+f2*(q+p), f1*p+f2*q, p, q)
        else:
            return fib_iter(n/2, f2, f1, p*p+q*q, q*(q+2*p))

    return fib_iter(n, 1, 0, 0, 1)
```

##性能问题
虽然上述算法理论上时间复杂度是 $O(\log n)$，但当 n 较大时，发现它们的运行时间增长不符合对数型的增长。原因在于，当 n 较大时，$F_{\frac{n}{2}}$ 是个非常大的整数，而 **大整数的乘法不是 $O(1)$ 的**，所以 $F_{\frac{n}{2}}\times F_{\frac{n}{2}}$ 的开销不是个常数。如果读者对这个问题感兴趣，可以自行用 C 语言实现两个大整数（`long long` 也无法表示的整数）的乘法。

#参考
* [Wiki: 斐波那契数列](https://zh.wikipedia.org/wiki/斐波那契数列)
* [计算机程序的构造和解释](https://mitpress.mit.edu/sicp/full-text/book/book-Z-H-11.html#%_thm_1.19)
