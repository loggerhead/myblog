title: AES 加密算法的实现    
date: 2014-03-24 17:27:37  
tags: AES, Rijndael, 加密算法

[AES (Advanced Encryption
Standard)][AES] 是由 NIST (美国国家标准与技术研究院) 发布于 [FIPS
PUB 197][fips_pub] 用来替代 [DES (Data Encryption
Standard)][DES] 的高级加密标准。而 Rijndael 算法是被 NIST 认为符合 AES 且被采用的一种对称加密算法，所以一般对 AES 和 Rijndael 算法这两个概念不予细究。

由于本文主要介绍 AES 算法的实现，对其原理不作详细介绍，所以和算法实现有关的数学知识我就只粗略提一下。文中出现的伪代码和实际实现有些出入，仅供读者理解算法各部分的实现思路。至于算法的各种实现细节，可以参考我用 [python 写的源代码][rijndael_cipher.py]。

[AES]: https://en.wikipedia.org/wiki/Advanced_Encryption_Standard
[fips_pub]: http://csrc.nist.gov/publications/fips/fips197/fips-197.pdf
[DES]: https://en.wikipedia.org/wiki/Data_Encryption_Standard
[rijndael_cipher.py]: https://github.com/loggerhead/lab/blob/master/rijndael_cipher.py

<!--- SUMMARY_END -->

[TOC]

#数学基础
[有限域][]是指含有有限个元素的域，其中元素的个数被称为*阶*。那么，什么是[域][]呢？我也不知道，不过不打紧，我们只要能看懂下表的运算 (注意：运算结果模除了阶数 3) ，并且知道域具有下面这几条性质就行了：

[有限域]: http://zh.wikipedia.org/wiki/有限域
[域]: http://zh.wikipedia.org/wiki/域_(數學)

| + | 0 | 1 | 2 |
|---|---|---|---|
| 0 | 0 | 1 | 2 |
| 1 | 1 | 2 | 0 |
| 2 | 2 | 0 | 1 |

| * | 0 | 1 | 2 |
|---|---|---|---|
| 0 | 0 | 0 | 0 |
| 1 | 0 | 1 | 2 |
| 2 | 0 | 2 | 1 |

* 在加法和乘法上封闭，即对任意属于该域的 $a$, $b$，都有 $a+b$ 和 $a*b$ 也属于该域
* 加法和乘法符合结合律和交换律
* 符合乘法对加法的分配律，即对任意属于该域的 $a$, $b$, $c$，恒有 $a*(b+c)=(a*b)+(a*c)$

##有限域加法
有限域中两个元素的加法定义为其多项式表示的相应系数的“加法”。此处加法是异或运算(记为 $\oplus$)，即模 2 加：$1\oplus1=0,\ 1\oplus0=1,\ 0\oplus0=0$。我们也可以把多项式表示成二进制形式，例如：$x^8+x^4+x^3+x+1\Leftrightarrow100011011$。有限域加法到底是什么意思呢？我们看一个例子就懂了：

$$
\begin{matrix}
 & (x^6+x^4+x^2+x+1)+(x^7+x+1)=x^7+x^6+x^4+x^2 & \\
\Longleftrightarrow & 01010111\oplus10000011=11010100 & 
\end{matrix}
$$

##有限域乘法
有限域 $GF(2^8)$ 上的乘法 (记为 $\cdot$ ) 定义为多项式的乘积模除 (记为 `%` ) 不可约多项式 (不能进行因式分解) ：$x^8+x^4+x^3+x+1$。例如：

$$
\begin{aligned}
&\ \ \ \ (x^6+x^4+x^2+x+1)\cdot(x^7+x+1)\ \ \ \Longleftrightarrow \ \ \ (01010111\cdot 10000011)\%100011011\\
&=(x^{13}+x^{11}+x^9+x^8+x^7+x^7+x^5+x^3+x^2+x+x^6+x^4+x^2+x+1)\%(x^8+x^4+x^3+x+1) \\
&=(x^{13}+x^{11}+x^9+x^8+x^6+x^5+x^4+x^3+1)\%(x^8+x^4+x^3+x+1) \\
&=x^7+x^6+1 \ \ \ \Longleftrightarrow \ \ \ 11000001 \\
\end{aligned}
$$

![模除多项式](https://loggerhead.me/_images/模除多项式.png)

#算法说明
Rijndael 是带有可变块长和可变密钥长度的迭代块密码，它的输入和输出均为 128 bits 的数据分组 (blocks)，使用的密钥可以为 128，192 或 256 bits。由于块密码自身只能加密特定长度的单块数据，若要加密变长数据，则数据必须先被划分为一些单独的密码块。通常而言，最后一块数据需要使用合适填充方式将数据扩展到符合密码块大小的长度。一种工作模式描述了加密每一数据块的过程，常见的有 CBC、ECB、CTR、OCF、CFB 五种工作模式，我们下面的介绍都是指 CBC 模式。

对于加密和解密变换，Rijndael 算法使用 4 个不同的以字节为基本单位的变换复合而成：

* 利用一个替代表 (S-Box) 对状态 state 进行字节替代；
* 将状态矩阵 state 的每一行循环移位不同的位移量；
* 将状态矩阵 state 中每一列的数据进行混合；
* 将轮密钥加到状态 state 上。

##预处理
假设我们要加密的字符串是 unicode 编码的 `hello,world=你好,世界`，那么将它进行处理并填充后的数据块为：

![Rijndael算法预处理](https://loggerhead.me/_images/Rijndael算法预处理.png)

原始输入有两个问题需要进行处理。首先，unicode 编码的字母 `a` 和汉字 `啊` 分别占用了 1 byte 和 2 bytes，也就是字符可能占用 1 到 2 个字节。问题在于，如果不能保证字符占用的字节个数，那么解密的时候就无法知道应当把某个字节当做一个字母处理，还是一个汉字的某个字节处理。所以，我们将所有只占用 1 byte 的字符高位填充 `0`，使所有的字符均占用 2 bytes。其次，最后一个块只有 2 bytes (`{75 4C}`)，但是算法的处理单位是数据块，也就是 $4*4$ bytes (即128 bits) 。于是我们采用 [PKCS7 的填充算法][PKCS7 padding]填充 14 (`14 = 0x0E`) 个 `{0E}`，使最后一个块也占用 16 bytes。注意，如果最后一个块正好占用 16 bytes，那么新增一个块并填充 16 个 `{10}`。

[PKCS7 padding]: https://en.wikipedia.org/wiki/Padding_(cryptography)#PKCS7

##伪代码
AES 算法的加密解密伪代码如下所示：

```python
def cipher(state, w):
    AddRoundKey(state, w, 0)

    for round in [1 to Nr-1]:
        SubBytes(state)
        ShiftRows(state)
        MixColumns(state)
        AddRoundKey(state, w, round)

    SubBytes(state)
    ShiftRows(state)
    AddRoundKey(state, w, Nr)
    return state

def invCipher(state, w):
    AddRoundKey(state, w, Nr)

    for round in [Nr-1 to 1]:
        invShiftRows(state)
        invSubBytes(state)
        AddRoundKey(state, w, round)
        invMixColumns(state)

    invShiftRows(state)
    invSubBytes(state)
    AddRoundKey(state, w, 0)
    return state
```

其中，分组大小 `Nb`、密钥长度 `Nk`、轮数 `Nr`、扩展密钥 `w`、状态矩阵 `state` 的含义如下：

* `Nb=4`，该值反应了状态 `state` 中 32-bit 字的个数(列数)；
* `Nk=4、6、8`，反应了密钥 `key` 中 32-bit 字的个数(列数) ；
* 算法的轮数 `Nr` 依赖于密钥长度；
* w 是经过密钥扩展后得到的 4-byte 字的一维数组，由 `KeyExpansion(key)` 得到；
* 加密算法的中间结果，表示为 $4*Nb$ byte 的矩阵数组。

目前符合 AES 的一切 Nk-Nb-Nr 的组合如下表所示。虽然未来版本可能包括对这些参数允许取值的改变或增加，不过我们的代码实现以此表为准。

|         | Nk | Nb | Nr |
|---------|:--:|:--:|:--:|
| AES-128 |  4 |  4 | 10 |
| AES-192 |  6 |  4 | 12 |
| AES-256 |  8 |  4 | 14 |

#算法实现
##字节替代 SubBytes
字节替代变换是一个非线性的字节替代，它独立地将状态 `state` 中的每个字节利用替代表 (S-Box) 进行运算。运算规则是：将字节的高 4 位作为 x，低 4 位作为 y 进行查表得到变换后的字节。比如：`{49}` 由行标为 4，列标为 9 的单元决定，变换结果为 `{3B}`。

![state_and_S-Box](https://loggerhead.me/_images/state_and_S-Box.png)

###S-Box 的生成
任意字节 $A=\{xy\}$ 在 S-Box 中对应单元 $B^{'}$ 都由两个变换得到:

(1) 在有限域 $GF(2^8)$ 上找到使 $A\cdot B=1$ 的 $B$，其中 $A=\{00\}$ 时 $B=\{00\}$。实现的伪代码如下：

```python
def invMult(A):
    if A == 0: return 0
    for B in [0x01 to 0xFF]:
        # * 表示 有限域$GF(2^8)$上的乘法
        if A * B == 0x01:
            return B
```

(2) 应用定义在 $GF(2)$ 上的仿射变换:

$$B^{'}_i=B_i \oplus B_{(i+4)\%8} \oplus B_{(i+5)\%8} \oplus B_{(i+6)\%8} \oplus B_{(i+7)\%8} \oplus C_i$$

其中 $0 \leq i<8$，$B_i$ 是字节 B 的第 i 比特，$C_i$ 是值为 $01100011$ 的字节 C 的第 i 比特，$\%$ 是普通的模除运算。S-Box 在 $GF(2)$ 上的仿射变换还可以表示为矩阵形式：

$$
\begin{bmatrix}
B^{'}_7\\
B^{'}_6\\
B^{'}_5\\
B^{'}_4\\
B^{'}_3\\
B^{'}_2\\
B^{'}_1\\
B^{'}_0
\end{bmatrix}
=
\begin{bmatrix}
1 & 1 & 1 & 1 & 1 & 0 & 0 & 0\\
0 & 1 & 1 & 1 & 1 & 1 & 0 & 0\\
0 & 0 & 1 & 1 & 1 & 1 & 1 & 0\\
0 & 0 & 0 & 1 & 1 & 1 & 1 & 1\\
1 & 0 & 0 & 0 & 1 & 1 & 1 & 1\\
1 & 1 & 0 & 0 & 0 & 1 & 1 & 1\\
1 & 1 & 1 & 0 & 0 & 0 & 1 & 1\\
1 & 1 & 1 & 1 & 0 & 0 & 0 & 1
\end{bmatrix}
\cdot
\begin{bmatrix}
B_7\\
B_6\\
B_5\\
B_4\\
B_3\\
B_2\\
B_1\\
B_0
\end{bmatrix}
\oplus
\begin{bmatrix}
0\\
1\\
1\\
0\\
0\\
0\\
1\\
1
\end{bmatrix}
$$

例如：$A=\{49\}$，则 $B=invMult(A)=\{64\}=01100100_{(2)}$，$B^{'}=00111011_{(2)}=\{3B\}$。

###逆字节替代 invSubBytes
`invSubBytes` 与 `SubBytes` 类似，伪代码如下：

```python
def invSubBytes(state):
    for byte in state:
        # 取高4位
        x = (byte & 0xF0) >> 4
        # 取低4位
        y = byte & 0xF
        replace_byte(state, inv_S_Box[x][y])
```

其中，`inv_S_Box` 的每个单元都是通过逆向查询 S-Box 得到的，例如：对于字节 `{3B}`，`inv_S_Box[3][B]=49`。

##行移位 ShiftRows
将 `state` 的每一行左循环移位 r 次 (r 为行号，且 $0 \leq r<3$) ，如下图所示：

![行移位ShiftRows](https://loggerhead.me/_images/行移位ShiftRows.png)

###逆行移位 invShiftRows
`invShiftRows` 与 `ShiftRows` 的唯一区别在于，左循环移位变成了右循环移位。

##列混合 MixColumns
列混合 `MixColumns` 在 `state` 上按照每一列进行运算，并将每一列看作 $GF(2^8)$ 上的多项式且被一个固定的多项式 $\{03\}x^3+\{01\}x^2+\{01\}x+\{02\}$ 模 $x^4+1$ 乘，这可以表示成矩阵形式：

$$\begin{bmatrix}
S^{'}_{0,c}\\
S^{'}_{1,c}\\
S^{'}_{2,c}\\
S^{'}_{3,c}
\end{bmatrix}
=
\begin{bmatrix}
02 & 03 & 01 & 01\\
01 & 02 & 03 & 01\\
01 & 01 & 02 & 03\\
03 & 01 & 01 & 02
\end{bmatrix}
\cdot 
\begin{bmatrix}
S_{0,c}\\
S_{1,c}\\
S_{2,c}\\
S_{3,c}
\end{bmatrix}$$

注意，$S_{r,c}$ 表 state 第 r 行第 c 列处的字节。也等价于下面的运算：

$$
\begin{aligned}
S^{'}_{0,c}=(\{02\}\cdot S_{0,c}) \oplus (\{03\}\cdot S_{1,c}) \oplus S_{2,c} \oplus S_{3,c}\\
S^{'}_{1,c}=S_{0,c} \oplus (\{02\}\cdot S_{1,c}) \oplus (\{03\}\cdot S_{2,c}) \oplus S_{3,c}\\
S^{'}_{2,c}=S_{0,c} \oplus S_{1,c} \oplus (\{02\}\cdot S_{2,c}) \oplus (\{03\}\cdot S_{3,c})\\
S^{'}_{3,c}=(\{03\}\cdot S_{0,c}) \oplus S_{1,c} \oplus S_{2,c} \oplus (\{02\}\cdot S_{3,c})\\
\end{aligned}
$$

![列混合MixColumns](https://loggerhead.me/_images/列混合MixColumns.png)

###逆列混合 invMixColumns
`invMixColumns` 与 `MixColumns` 区别不大，只不过将相乘的多项式换成了 $\{0B\}x^3+\{0D\}x^2+\{09\}x+\{0E\}$，也可表示为矩阵形式：

$$
\begin{bmatrix}
S^{'}_{0,c}\\
S^{'}_{1,c}\\
S^{'}_{2,c}\\
S^{'}_{3,c}
\end{bmatrix}
=
\begin{bmatrix}
0E & 0B & 0D & 09\\
09 & 0E & 0B & 0D\\
0D & 09 & 0E & 0B\\
0B & 0D & 09 & 0E
\end{bmatrix}
\cdot 
\begin{bmatrix}
S_{0,c}\\
S_{1,c}\\
S_{2,c}\\
S_{3,c}
\end{bmatrix}
$$

##轮密钥加 AddRoundKey
`AddRoundKey` 只是简单的将 `state` 的每一列与一个轮密钥进行*异或加*，即：

$$
\begin{bmatrix}
S^{'}_{0,c}\\
S^{'}_{1,c}\\
S^{'}_{2,c}\\
S^{'}_{3,c}
\end{bmatrix}
=
\begin{bmatrix}
w_{l+c,0} &\\
w_{l+c,1} &\\
w_{l+c,2} &\\
w_{l+c,3} &
\end{bmatrix}
\oplus
\begin{bmatrix}
S_{0,c}\\
S_{1,c}\\
S_{2,c}\\
S_{3,c}
\end{bmatrix}
$$

其中 $w=KeyExpansion(key)$，$l=round*Nb$，round 是当前轮数，且 $0 \leq round \leq Nr$，$w_{l+c,n}$ 表示 `w` 数组中下标为 `l+c` 的字的第 n+1 个字节 (最高位位于第 1 个字节) 。

![轮密钥加变换](https://loggerhead.me/_images/轮密钥加变换.png)

##密钥扩展 KeyExpansion
`KeyExpansion` 调用后生成 $Nb*(Nr+1)$ 个字，即 $4*Nb*(Nr+1)$ bytes。我们先看一段伪代码加深一下理解：

```python
def KeyExpansion(key):
    w = word_array(Nb*(Nr+1))
    # 注意：数组下标从0开始
    for i in [0 to Nk-1]:
        # key 为字节数组
        w[i] = bytesToWord(key[4*i], key[4*i+1], key[4*i+2], key[4*i+3])
    for i in [Nk to Nb*(Nr+1)-1]:
        tmp = w[i-1]
        if i%Nk == 0:
            # i/Nk 会向下取整
            tmp = xor(subword(rotword(tmp)), rcon[i/Nk])
        else if Nk>6 and i%Nk == 4:
            tmp = subword(tmp)
        w[i] = xor(w[i-Nk], tmp)
    return w
```

###key 的预处理
为了接收任意的 key 输入，我们可以将 key 像下面这样进行处理，使得 key 的长度为 128，192 或 256：

```python
if 0 <= toBit(key).length <= 128:
    key = md5(key)
else if 128 < toBit(key).length <= 192:
    key = md5(key) + md5(key)/2
else:
    key = sha256(key)
```

当然，这种做法并不高效，只不过抛砖引玉而已。

###轮常数 rcon
`rcon` 是一个字数组，生成的算法是 [Rijndael key schedule]，AES 实现中可能用到的值如下：

[Rijndael key schedule]: http://en.wikipedia.org/wiki/Rijndael_key_schedule

| 下标 |     值     |
|:-----|:----------:|
| 0    | 0x00000000 |
| 1    | 0x01000000 |
| 2    | 0x02000000 |
| 3    | 0x04000000 |
| 4    | 0x08000000 |
| 5    | 0x10000000 |
| 6    | 0x20000000 |
| 7    | 0x40000000 |
| 8    | 0x80000000 |
| 9    | 0x1B000000 |
| 10   | 0x36000000 |
| ...  | ......     |

`rcon[0]` 仅用于占位，实际中并未使用它。`rcon` 由 $rcon[i][0]=rcon[i-1][0]\cdot 2$ 生成，`rcon[i][0]` 表示 `rcon[i]` 的最高字节，剩余三个字节均用 `0` 填充。$\cdot$ 是前面介绍过的有限域 $GF(2^8)$ 内的模 $x^8+x^4+x^3+x+1$ 乘法。

###其余函数
* 循环左移 `rotword`，和行移位 `ShiftRows` 中的循环左移一样，这里将字中的每个字节循环左移 1 次；
* 字替换 `subword`，使用 S-Box 替换字中的每个字节；
* 异或 `xor`，将两个字进行异或。
