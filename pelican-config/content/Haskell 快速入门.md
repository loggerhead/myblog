title: Haskell 快速入门    
date: 2015-10-01 21:35:00  
tags: Haskell, 编程语言

当你开始接触函数式的时候，经常能看到 Haskell 的身影。那么 Haskell 究竟具有什么特点，让众多程序员为之倾倒？百闻不如一见，看几个例子你就懂了：

```haskell
-- 从 1 到负无穷的列表
[1, 0..]                                        
-- 斐波那契数列
fibs = 0 : 1 : zipWith (+) fibs (tail fibs)
-- 快速排序
quicksort [] = []  
quicksort (x:xs) = (quicksort $ filter (< x) xs) ++ [x] ++ (quicksort $ filter (> x) xs)
-- 将 `*2` 和 `+3` 分别作用于列表
[(*2), (+3)] <*> [1, 2, 3]  -- [2,4,6,4,5,6]
```

通过这几个例子，可以看出 Haskell 表达能力极强。这是因为 Haskell 是一门支持*惰性求值*、*模式匹配*、*列表解析*、*类型类*和*类型推断*的*强静态类型* && [纯函数式][functional programming]语言。

本文主要介绍 Haskell 的语法，并不会对函数式或 Haskell 的特性进行说明。如果曾经了解过函数式语言，本文可以作为语法简介来读。如果从未接触过函数式，那么你需要**熟悉至少一门语言**，并辅以适量的[习题][FP exercises]才可能入门。

[functional programming]: https://en.wikipedia.org/wiki/Functional_programming
[FP exercises]: https://www.hackerrank.com/domains/fp/intro

<!--- SUMMARY_END -->

[TOC]

#环境
##安装
```shell
# Linux
sudo apt-get install haskell-platform
# OSX
brew install ghc cabal-install
```

##编译与运行
```shell
# 交互式解释器
ghci
# 编译生成二进制可执行文件
ghc --make test.hs
# 运行 `test.hs`（不需要编译）
runghc test.hs
# `runghc` 的别名
runhaskell test.hs
```

#语法
##注释
```haskell
-- 单行注释
{- 
被 `{-` 和 `-}` 括起来的是多行注释
-}
```

##表达式
###数学运算
```haskell
2 + 10      -- 12
2 - 10      -- -8
2 * 10      -- 20
2 / 10      -- 0.2
2 `div` 10  -- 0
2 `mod` 10  -- 2
2 ^ 10      -- 1024
```

###布尔运算
```haskell
not True         -- 非
False && True    -- 与
False || True    -- 或

12345 /= 54321   -- 不等于
"foo" == "foo"   -- True       
"abc" <= "bbb"   -- True
(2,0) >= (1,9)   -- True
```

注意：只有布尔值能进行布尔运算，所以类似 `0 || 1` 的表达式会报错。

##列表
```haskell
-- 列表中元素的类型相同
[1, 2, 3]
-- 将 1 添加到列表 [2, 3] 的头部，时间复杂度为 O(1)
1:[2, 3]
-- 从 1 到 3 的列表，实际上是 `1:2:3:[]` 的语法糖
[1..3]
-- 小写字母。字符串实际上是字符列表，即 `[Char]`
['a'..'z']          -- "abcdefghijklmnopqrstuvwxyz"
-- 根据头两个数生成列表
[1, 4..10]          -- [1,4,7,10]
[1, 4..11]          -- [1,4,7,10]
-- 无穷列表
[1..]               -- 1 到正无穷
[1, 0..]            -- 1 到负无穷

-- 比较两个列表。挨个元素比较大小，直到确定大小关系，时间复杂度为 O(n)
[3, 2..] > [1, 2..]
-- 合并两个列表。挨个将第一个列表的元素添加到第二个列表中，时间复杂度为 O(n)
[1, 3..9] ++ [2, 4..10]
"hello" ++ "world"
-- `list !! i` 表示取出列表 `list` 中下标为 `i` 的元素，下标从 0 开始
[0..] !! 999

-- `[2*x | x <- l]` 产生了一个新列表，它的元素由列表 `l` 中的元素进行运算 `2*x` 得到
[2*x | x <- [1..2]]                                         -- [2,4]
-- 对偶数计算 `2*x`
[2*x | x <- [1..9], x `mod` 2 == 0]                         -- [4,8,12,16]
-- 计算与原点的距离
[sqrt (x*x + y*y) | (x, y) <- [(1, 1), (5, 12), (3, 4)]]    -- [1.4142135623730951,13.0,5.0]
-- 计算笛卡尔积
[(x, y) | x <- [1, 2], y <- [3, 4]]                         -- [(1,3),(1,4),(2,3),(2,4)]
-- 筛选
[y | (3, y) <- [(1, 1), (5, 12), (3, 4)]]                   -- [4]
```

##if 表达式
与其他语言的 if 不同，Haskell 的 if 是表达式，*有返回值*，所以 **必须有 else**。下面是几个例子：

```haskell
if 1 > 0 then "good" else "WTF?!"
[if 0 <= x && x <= 9 then x else -1 | x <- [-3..12]]
```

##let 语句
`let` 将表达式或值绑定到变量，例如：

```haskell
let c = 3
c == let a = 1; b = 2 in a + b
```

`let` 有 `let ...` 和 `let ... in ...` 两种形式。前者只能出现在 `do` 或列表解析中 `|` 的后面，后者在任何表达式能够存在的地方都可以出现。例如：

```haskell
-- 出现在 `do` 中
do statements
   let var1 = expr1
       var2 = expr2
   statements

-- 出现在列表解析中
[(x, y) | x <- [1..2], let y = 2*x]                 -- [(1,2),(2,4)]

-- 作为表达式
(let a = 1; b = 2 in a + b) + 3                     -- 6
[(x, y) | x <- [1..2], let y = let a = x^2 in a+x]  -- [(1,2),(2,6)]
```

##函数
函数的语法形式如下：

```haskell
name arg1 arg2 = do_something_with_args
```

Haskell 的函数有几个特点：

* 函数参数之间用空格隔开
* 任何函数都有返回值
* 函数名不一定要是字母，例如：

```haskell
let (+) = (++)
let (%) = mod
let pp' = succ

pp' 2                   -- 3
1 % 2                   -- 1
"hello" + "world"       -- "helloworld"
```

###匿名函数
匿名函数是没有名字的函数，它符合[λ演算][lambda]，其语法如下。

[lambda]: https://zh.wikipedia.org/wiki/Λ演算

```haskell
\arg1 arg2 -> do_something_with_args
```

也许因为 `\` 看起来像 λ，所以被用来定义匿名函数吧。

```haskell
(\x y -> x + y) 3 5                                           -- 8
[is_odd x | x <- [1..5], let is_odd = \x -> x `mod` 2 == 1]   -- [True,False,True,False,True]
foldl (\acc x -> 2*x + acc) 0 [1..3]                          -- 12
```

###常用函数
```haskell
-- 类似于 `i++`
succ 2                          -- 3

-- 取出元组第一个元素
fst ("hello", "world")          -- "hello"
snd ("hello", "world")          -- "world"

head [1..5]                     -- 1
tail [1..5]                     -- [2,3,4,5]
last [1..5]                     -- 5
-- 丢弃最后一个元素形成的列表
init [1..5]                     -- [1,2,3,4]

length [1..5]                   -- 5
-- 检查列表是否为空
null []                         -- True
-- 检查列表中是否存在元素 9
elem 9 [1..5]                   -- False

-- 反转列表
reverse [1..5]                  -- [5,4,3,2,1]
-- 取出列表的前 5 个元素组成新列表
take 5 [1..]                    -- [1,2,3,4,5]
-- 丢弃列表的前 5 个元素组成新列表
drop 5 [1..9]                   -- [6,7,8,9]
-- 生成具有 5 个重复元素 'a' 的新列表
replicate 5 'a'                 -- "aaaaa"

sum [1..5]                      -- 15
-- 1*2*3*4*5
product [1..5]                  -- 120
maximum [1..5]                  -- 5
minimum [1..5]                  -- 1

-- `foldl f acc list` 相当于 `foreach x in list do acc = f(acc, x)`
foldl (+) 0 [1..5]              -- sum [1..5]
foldl max 0 [1..5]              -- maximum [1..5]
-- `foldr` 与 `foldl` 类似，只不过是从右到左遍历列表
foldr (-) 0 [1..5]              -- 3
foldl (-) 0 [1..5]              -- -15
-- `map f list` 相当于 `[f(x) | x <- list]`
map succ [1..5]                 -- [succ x | x <- [1..5]]
-- 过滤掉不满足 `x > 0` 的元素
filter (> 0) [-5..5]            -- [1,2,3,4,5]
-- `zip a b` 将列表 `a`、`b` 合并成新列表 `c`，其中 `c !! i == (a !! i, b !! i)`
zip [1, 3..9] [2, 4]            -- [(1,2),(3,4)]
-- `zipWith f a b` 将列表 `a`、`b` 合并成新列表 `c`，其中 `c !! i == f (a !! i) (b !! i)`
zipWith (+) [1, 3..9] [2, 4]    -- [3,7]
```

###模式匹配
当定义函数时，可以为不同的模式定义不同的函数体。那到底什么是模式呢？我们先看一个例子感受一下。

新建文件 `test.hs`，输入下面的代码，保存后在命令行输入 `runhaskell test.hs` 运行。

```haskell
fibo 0 = 0
fibo 1 = 1
fibo n = fibo (n-1) + fibo (n-2)

main = print (fibo 2)
```

当调用 `fibo 2` 时，Haskell 会从上到下依次尝试进行模式匹配。先尝试 `0` 和 `1`，发现与参数 `2` 不匹配，直到尝试最后一个模式时，发现匹配变量 `n`，所以执行 `fibo n` 对应的函数体。

模式匹配不仅是可以对数字进行匹配，还可以对列表和元组等进行匹配，例如：

```haskell
-- 匹配空列表
first [] = []
-- `(x:[])` 匹配列表 `[x]`。在模式中出现的变量可以直接使用，表示匹配到的值
first (x:[]) = "LAST\t=> " ++ [x] 
-- `@` 前面的 `all` 表示整个列表。好处是当需要使用列表时，不需要通过 `x:xs` 再生成一次
first all@(x:xs) = all ++ "\t=> " ++ [x] ++ "\n" ++ first xs

main = putStrLn (first "hello")
```

注意，不能在模式匹配中使用 `++`，因为匹配 `(xs ++ ys)` 可能导致二义性。比如：`[1,2,3]` 可以是 `([1] ++ [2,3])`，也可以是 `([1,2] ++ [3])`，鬼知道匹配哪一个！

###Guards（断言）
断言类似于 C 语言中的 `switch`，它会对每一个断言求值，直到遇到 `True`，再执行所对应的逻辑。例如：

```haskell
phase age 
    | age <= 18 = "Fire"
    | age <= 30 = "Sublime"
    | otherwise = "Wisdom"

main = putStrLn (phase 22)
```

`phase 22` 调用会先检查 `22 <= 18`，发现为 `False`，接着检查下一个断言 `22 <= 30`，为 `True`，于是执行 `age <= 30` 后面的代码。

断言中出现的 `otherwise` 类似于 `switch` 中的 `default`，如果 `otherwise` 前面的所有断言都为 `False`，那么执行 `otherwise` 后面的逻辑。

###`.` 操作符
`.` 是一个函数组合操作符。功能类似于 Unix 中的管道符 `|`，它会将前一个函数的输出作为后一个函数的输入。先看一个例子：

```haskell
(succ . sum) [1..5]         -- 16
```

`.` 将 `succ` 和 `sum` 组合到一起，形成一个新函数 `succ . sum`，然后将 `[1..5]` 作为参数调用这个函数。等价于 `succ (sum [1..5])`。和[数学][dot in math]上的 `f∘g (x) <=> f(g(x))` 概念一样。这里不多作介绍，如果感兴趣，可以看看 [StackOverflow 上的回答][dot in haskell]。

[dot in math]: https://www.mathsisfun.com/sets/functions-composition.html
[dot in haskell]: https://stackoverflow.com/questions/20279306/what-does-f-g-mean-in-haskell#answer-20279307

下面给出一个比较复杂的例子，帮助理解 `.` 操作符。

```haskell
import Data.Char

upper_name (fst:snd:others) = capitalized fst:capitalized snd:others
    where capitalized (fst:remains) = toUpper fst : remains

cap_names = unlines . map unwords . map upper_name . map words . lines

main = putStr (cap_names "neo loggerhead\nfoo bar")
```

输出是：

```
Neo Loggerhead
Foo Bar
```

###`$` 函数
`$` 函数，又被称为 *function application*。不管有啥用，我们先看一个例子：

```haskell
-- 等价于 succ (cos (sin 1))
succ $ cos $ sin 1
```

其实 `$` 只是一个语法糖，它具有最低优先级。可以认为 `$` 给随后的语句加了一对括号，即把 `$` 替换成 `(`，并在最右边加上了 `)`。其优点是：当函数调用很长时，避免了产生一堆影响可读性的括号。

###where 语句
同样，话不多说，先看一个计算 BMI[^bmi] 的函数：

[^bmi]: [身高体重指数（Body Mass Index）](https://zh.wikipedia.org/wiki/身高體重指數)

```haskell
bmi weight height  
    | weight / height ^ 2 <= 18.5 = "You're underweight, you emo, you!"  
    | weight / height ^ 2 <= 25.0 = "You're supposedly normal. Pffft, I bet you're ugly!"  
    | weight / height ^ 2 <= 30.0 = "You're fat! Lose some weight, fatty!"  
    | otherwise                   = "You're a whale, congratulations!"  
```

不难看出 `weight / height ^ 2` 被重复计算了多次，违背了 DRY 原则[^DRY]。为了减少重复运算，增加可读性，可以将 `bmi` 改写成：

[^DRY]: 意为：[Don't repeat yourself][]，即尽可能的减少重复的逻辑和计算

[Don't repeat yourself]: https://en.wikipedia.org/wiki/Don't_repeat_yourself

```haskell
bmi weight height  
    | b <= skinny = "You're underweight, you emo, you!"  
    | b <= normal = "You're supposedly normal. Pffft, I bet you're ugly!"  
    | b <= fat    = "You're fat! Lose some weight, fatty!"  
    | otherwise   = "You're a whale, congratulations!" 
    where b = weight / height ^ 2
          (skinny, normal, fat) = (18.5, 25.0, 30.0) 

main = print (bmi 70 1.75)
```

`where` 语句与 `let` 语句作用类似，都能将值与变量绑定，方便随后的使用，其不同之处包括：

* `where` 中可以使用模式匹配
* `where` 中绑定的变量的作用域是整个函数
* `where` 是语句，不是表达式

###case 表达式
case 表达式和 if 表达式类似，都有返回值。但是 case 还能进行模式匹配。实际上，函数参数中的模式匹配就是 case 表达式的语法糖。

```haskell
{-
case expression of pattern -> result  
                   pattern -> result  
                   pattern -> result  
                   ...  
-}

classify age = case age of 0 -> "newborn"
                           1 -> "infant"
                           2 -> "toddler"
                           _ -> "senior citizen"

main = print $ classify 18
```

注意，模式匹配中的 `_` 能匹配任何值。

###Partial application（偏函数）
Haskell 中的所有函数都是**单参函数**。多参函数本质上是对单参函数的多次求值，例如：

```haskell
max 2 3
{- 等价于
let maxWith2 = max 2
maxWith2 3
-}
```

`max 2 3` 等价于 `(max 2) 3`，`max` 接收 `2` 作为参数，并返回一个新函数 `maxWith2`，接着执行 `maxWith2 3` 得到较大值。这样的好处是，我们能创造偏函数[^Partial_application]，而偏函数很多时候用起来超级方便。例如：

[^Partial_application]: 详见 [wiki](https://en.wikipedia.org/wiki/Partial_application)

```haskell
-- 计算两点距离
let distance (x1, y1) (x2, y2) = sqrt $ (x1-x2)^2 + (y1-y2)^2
-- 计算到原点距离的偏函数
let distanceToOrigin = distance (0, 0)
distanceToOrigin (3, 4)

-- `(> 0)` 等价于 `\x -> x > 0`
filter (> 0) [-5..5]            -- [1,2,3,4,5]
-- `(max 0)` 等价于 `\x -> max 0 x`
map (max 0) [-5..5]             -- [0,0,0,0,0,0,1,2,3,4,5]

let add1 = succ . max 0
-- `-1` 必须括起来，否则会被解释为做减法
add1 (-1)
-- 等价于 `add1 $ -1`，为什么？ 
```

##类型与 Typeclass
###类型
文章一开始就提到了 Haskell 是强静态类型语言，这是因为 Haskell 中的所有东西都有类型。我们可以在 GHCI 中使用 `:t anything` 命令查看 `anything` 的类型，比如：

```
Prelude> :t (.)
(.) :: (b -> c) -> (a -> b) -> a -> c
Prelude> :t 123
123 :: Num a => a
Prelude> :t 'a'  
'a' :: Char  
Prelude> :t 4 == 5  
4 == 5 :: Bool  
Prelude> :t mod
mod :: Integral a => a -> a -> a
```

不难发现，`::` 前面是表达式，后面是表达式的类型说明，并且*类型都以大写字母开头*。其中，`=>` 叫*类约束*（class constraint），用来指明类型属于哪些 typeclass，`a`、`b`、`c`等出现在类型说明中的小写字母叫*类型变量*（type variable）。我们看个例子：

```haskell
mod :: Integral a => a -> a -> a
```

上面的类型说明可以理解为：`mod` 函数接收两个同一类型 `a` 的参数，返回值也是类型 `a`，并且类型 `a` 属于 `Integral` typeclass。

常见的类型包括：

* `Int`: 有界限的整数。比如：32 位机器的最小 `Int` 是 `-2147483648`
* `Integer`: 无界限的整数。可以表达很大很大的整数
* `Float`: 单精度浮点数
* `Double`: 双精度浮点数
* `Bool`: 布尔类型
* `Char`: 字符类型
* `()`: 空元组
* `Ordering`: 取值为 `GT`、`LT` 或 `EQ`，分别是 `greater than`、`lesser than` 和 `equal` 的缩写

与 C 和 Java 等语言不一样，Haskell 是具有*类型推断*的**强**静态类型语言。这意味着：

* Haskell 会自动推断表达式或函数的类型，所以在定义函数的时候不需要声明类型
* **不会自动进行类型转换**。因此 `Int` 和 `Double` 不能直接进行运算，比如：

```
Prelude> (1::Int) == (1::Double)

<interactive>:66:14:
    Couldn't match expected type ‘Int’ with actual type ‘Double’
    In the second argument of ‘(==)’, namely ‘(1 :: Double)’
    In the expression: (1 :: Int) == (1 :: Double)
    In an equation for ‘it’: it = (1 :: Int) == (1 :: Double)
```

###Typeclass (类型类)
Typeclass 与常常出现在面向对象中的*接口*类似。常见 typeclass 如下：

* `Num`: 数字
* `Integral`: 整型数
* `Floating`: 浮点数
* `Eq`: 能测试相等。属于 `Eq` 的类型必须实现 `(/=)` 或 `(==)` 函数
* `Ord`: 能比较顺序。属于 `Ord` 的类型必须实现 `compare` 或 `(<=)` 函数
* `Show`: 能转换成字符串。属于 `Show` 的类型必须实现 `show` 函数。除了函数以外的所有的类型都属于 `Show` 类
* `Read`: 与 `Show` 相反。属于 `Read` 的类型必须实现 `read` 函数
    
比如，`1 :: Int` 就属于 `Num`、`Integral`、`Eq`、`Ord`、`Show`。下面给出一些常见的用法：

```haskell
show 123                -- "123"
-- 类型推断会自动将 `read "2"` 转换成 `read "2" :: Int`
1 + read "2"            -- 3
-- Haskell 不知道该将 `"2"` 转换成 `Int`、`Integer` 还是 `Float`，所以会报错
-- read "2"

let a = 1 :: Double
let b = 1 :: Int
-- fromIntegral 将 `Integral` 转换成 `Num`
a + fromIntegral b      -- 2
-- `+` 的类型是 `(+) :: Num a => a -> a -> a`
-- 类比面向对象中的多态和泛型的概念，想想为什么 `a`、`b` 不能直接相加
```

注意：如果从上下文不能推断出 `read` 的返回值是什么类型，一定要 **明确指明类型**

##其他
下面给出的内容不太容易掌握，不适宜放在快速入门中，如果感兴趣，可以自己看一下 [Learn You a Haskell for Great Good!](http://learnyouahaskell.com/chapters) [^HASKELL 趣学指南] 的相关章节：

* [模块](http://learnyouahaskell.com/modules)
* [输入输出](http://learnyouahaskell.com/input-and-output)
* [类型与类型类](http://learnyouahaskell.com/making-our-own-types-and-typeclasses)
* [Functors, Applicative, and Monoids](http://learnyouahaskell.com/functors-applicative-functors-and-monoids)

[^HASKELL 趣学指南]: 英文不好的同学可以看 [中文版](http://learnyoua.haskell.sg/content/zh-cn/index.html)

#参考
* [Wiki: Haskell](https://zh.wikipedia.org/wiki/Haskell)
* [Learn X in Y minutes: Haskell](http://learnxinyminutes.com/docs/haskell/)
* [Learn You Some Haskell](http://learnyouahaskell.com/chapters)
