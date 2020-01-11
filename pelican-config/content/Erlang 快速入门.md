title: Erlang 快速入门
date: 2015-08-21 21:08:25
tags: Erlang, 编程语言

在很多语言中，我们都能看到**函数式范型**、**动态类型**、**类型系统**的身影，而 Erlang 在此基础上发展出了一些自成一派的特点：

* **轻量级进程**。Erlang 的进程既不是操作系统层面的进程，也不是线程，而是由 Erlang 虚拟机进行管理调度的无状态的进程。建立一个进程的成本非常低，在博主机器上（2.4 GHz Intel Core i5，8 GB 1600 MHz DDR3）平均只需要 2~4 us，而建立 80 万个进程也只花费了几秒的时间，并且据官方说法，建立一个进程的内存占用不到 400 字。
* **消息原语**。Erlang 直接在语言层面支持进程间通讯，并且在内部对并发进行了同步处理，用户不需要再关心多进程并发会不会发生同步问题，大大降低了在进程间传递消息的难度。例如，一句话就能搞定发消息：`Pid ! Message.`，收消息也就多个匹配和处理的过程：`receive Message -> handle(Message) end.`。
* **快速失败**。如果发生了运行时错误，发生错误的进程会立刻停止执行，并借由消息机制传递错误，使其他进程能够帮助处理错误，或者干脆重启发生错误的进程。
* **代码热更新**。如果是其它语言，当代码发生变动需要重新部署时，比如紧急修复了一个 bug，你需要停止正在运行的服务器，编译后再重新运行新程序。但是使用 Erlang，你不需要停机，不需要停机，只需要利用消息机制通知服务器，更换模块即可，Erlang 虚拟机会自动加载新模块，达到“热更新”。
* **分布式**。Erlang 为分布式集群的实现提供了相当易用的函数，在集群的不同节点间通信与进程间通信的实现大同小异。如果熟悉了 Erlang 的消息机制，那么使用 Erlang 实现简单的分布式集群的学习成本近乎于零。

Erlang 的以上特性让它特别适合于实现高可靠、高性能的服务器。然而 Erlang 并不是一门新手友好的语言，且不说它属于函数式范型，光是它那受 Prolog 影响颇深的语法，也让人望而生畏。所以本文虽是快速入门，但也需要读者有一定的功力，**熟悉至少一门静态类型语言和动态类型语言**。否则，强行修炼，必将走火入魔。本文中涉及到的源代码可以在 [Gist][] 获取。

[Gist]: https://gist.github.com/loggerhead/48facfaab6db640c2b3f

<!--- SUMMARY_END -->

[TOC]

#环境
##安装
```shell
# Linux
sudo apt-get install erlang
# OSX
brew install erlang
```

官方的 Erlang Shell 是不带语法高亮的，如果需要高亮，可以安装 [kjell][]。

[kjell]: https://github.com/karlll/kjell

##运行
```shell
erl
#查看 erl 手册
erl -man erl
#查看 `lists` 模块手册
erl -man lists
```

在 `erl` 中按下 `CTRL+G` 中断正在运行的程序，如果没有运行的程序，那么再输入 `q` 退出 `erl`（连按两次 `CTRL+C` 也能退出），或者输入 `h` 查看可使用的命令。

```erl
1>
User switch command
--> h
c [nn]            - connect to job
i [nn]            - interrupt job
k [nn]            - kill job
j                 - list all jobs
s [shell]         - start local shell
r [node [shell]]  - start remote shell
q        - quit erlang
? | h             - this message
```

为了与命令行的 shell 相区分，下文使用 `erl` 代指 Erlang Shell。

## 运行环境差异
* `erl` 只能计算表达式，所以不能定义函数，不能使用 `-` 开头的编译命令
* [常用函数的缩写][function shorthand]只能在 `erl` 中使用
* [escript][]、`erl` 和模块三者不尽相同

[function shorthand]: http://linux.die.net/man/3/c
[escript]: http://www.erlang.org/doc/man/escript.html

#语法
##注释
```Erlang
% `%` 在 Erlang 中表单行注释
% Erlang 没有多行注释
%% 用几个 `%` 来注释只是风格问题
```

##变量
```Erlang
% 变量必须以大写字母或下划线开头
% 英文句号表示语句的结束
Num = 42.

% 变量只有绑定和未绑定两种状态
% 变量在第一次匹配时被绑定
% 已被绑定的变量不能再改变它的值
% Num = 1.
```

##模式匹配
```Erlang
% `=` 并不是赋值，而是模式匹配
1 = 1.
% 模式匹配的意思是：先计算右边的值，再将结果与左边进行匹配
Answer = 42.
42 = Answer.
```

##数据类型
```Erlang
% 浮点数
Pi = 3.14.

% Atom 以小写字母开始（所以变量必须以大写字母开始），可以由字母、数字、`_` 或 `@` 组成
Bar = for_example@bar.
% 被单引号括起来的也是 atom
Foo = '?! 2333...'.
% `true` 和 `false` 只是约定用来做布尔运算的 atom
true and false.

% 被花括号括起来的是元组
Point = {point, 1, 2}.

% 被中括号括起来的是列表
Nums = [1, 2, 3].
% 被双引号括起来的是字符串
Word = "Hi".
% 字符串实际上是由整数组成的列表
[72, 105] = "Hi".

% 字符以 `$` 开头，表示该字符对应的数字
$\n.  % 10
$a.   % 97
```

详见[官方文档](http://erlang.org/doc/reference_manual/typespec.html)。

##布尔运算
```Erlang
% `and` 类似于函数调用 `and(ExprA, ExprB)`
false and (ok == io:format("hi ")).     % hi false
% `andalso` 和其他语言一样，具有短路性质。当 `ExprA == false` 时，不计算 `ExprB`
false andalso (ok == io:format("hi ")). % false
% 不具有短路性质的逻辑或
true or (ok == io:format("hi ")).       % hi true
% 具有短路性质的逻辑或
true orelse (ok == io:format("hi ")).   % true
% 逻辑非
not true.

% 值相等吗？
1 == 1.0.
% 值相等且类型一致吗？
1 =:= 1.0.
% 值不相等吗？
1 /= 1.
% 值不相等或类型不相等吗？
1 =/= 1.0.

% 大于
1 >= 0.
% 不是 '<=' 哦！
1 =< 2.
```

##数学运算
```Erlang
5 / 2.   % 2.5
5 div 2. % 2
5 rem 2. % 1
% 语法 `Base#Value` 用于表示其他进制的数（2<=Base<=36）
2#101010 = 8#052 = 16#2A.
```

##元组匹配
```Erlang
% `_` 是匿名变量，用来匹配任何值
{_, _, Y} = Point.
```

##列表操作
```Erlang
List = [1, 2, 3].
% `[Head|Tail] = List` 匹配列表的头和尾
[Head|Tail] = List.  % Head = 1, Tail = [2, 3].
hd(List) =:= Head.
tl(List) =:= Tail.

% `[Head|Tail]` 还可以用来组成新列表
ListPlus = [0|List]. % [0, 1, 2, 3]
% 合并成新列表
[1, 2] ++ [3, 4].    % [1, 2, 3, 4]

% 剔除列表元素
[2, 4, 2] -- [2].    % [4, 2]

% 表达式 `[F(X) || X <- L]` 产生了一个新列表
% 新列表的每个元素由列表 L 中的每个元素进行运算 F(X) 得到
Double = [2*X || X <- List].                   % [2, 4, 6]
% 满足 `X rem 2 == 0` 的元素才计算 `2*X`
DoubleEven = [2*X || X <- List, X rem 2 == 0]. % [4]

% 计算与原点的距离
Points = [{1, 1}, {5, 12}, {3, 4}].
[math:sqrt(X*X + Y*Y) || {X, Y} <- Points]. % [1.4142135623730951,13.0,5.0]
% 计算笛卡尔积
[{X, Y} || X <- [1, 2], Y <- [3, 4]].       % [{1,3},{1,4},{2,3},{2,4}]
% 筛选
[Y || {3, Y} <- Points].                    % [4]
```

##比特语法
```Erlang
% 被 `<<` 和 `>>` 括起来的值会被转换为二进制数据
Color = <<16#010203:24>>.
<<Red:8, Green:8, Blue:8>> = Color.
<<"hello, world">>.

% binaries 的遍历操作和列表类似
% 只不过是使用 `<=` 而不是 `<-`（所以小于等于采用 `=<`）
[X || <<X>> <= <<1,2,3,4>>].            % [1,2,3,4]
<< <<X>> || <<X>> <= <<1,2,3,4>> >>.    % <<1,2,3,4>>
```

详见 [bit syntax](http://www.erlang.org/documentation/doc-5.6/doc/programming_examples/bit_syntax.html)。

##模块
[模块][module]必须存储在后缀为 `.erl` 的文件中，且**只能由模块属性和函数定义组成**，下面以 `test.erl` 为例说明如何使用模块。

[module]: http://erlang.org/doc/reference_manual/modules.html

```Erlang
% 模块属性以 `-` 开头
% module 属性是必须的，且参数必须与除去后缀的文件名一致
-module(test).

% import 属性用来导入其他模块的函数，然后才能在模块中使用
% -import(Module, [Function1/Arity, ..., FunctionN/Arity]).
% 其中 Arity 是函数的参数数目
```

模块必须编译才能使用 [^code_loading]，编译成功会生成 `test.beam` 文件。编译有多种方式，如：

* 使用 [erlc][] 进行编译：`erlc test.erl`
* 在 `erl` 中执行 `c(test).`

[erlc]: http://erlang.org/doc/man/erlc.html

[模块在第一次引用时被自动加载][module_first_use]，所以在调用模块中的函数时，不需要运行 `import` 之类的语句（python 就需要）。[^module_load]

[module_first_use]: http://erlang.org/doc/man/code.html

[^code_loading]: [Compilation and Code Loading](http://erlang.org/doc/reference_manual/code_loading.html)
[^module_load]: 实际上还得分**嵌入式**和**交互式**两种运行模式来讨论。前者在启动时一次加载完所有的代码，后者在启动时加载一部分基本的模块，其他模块则在第一次引用时动态加载。

##函数
###匿名函数
表达式 `fun(X) -> Expression end.` 返回*函数*作为表达式的值。

```Erlang
% Erlang 对缩进不敏感，所以也可以写成多行
Foo = fun() ->
    do_nothing_but_return_a_atom
end.
% 任何函数都有返回值，最后一个表达式的值会被当作返回值
Foo().
% 匿名函数可以在 erl 中执行
4 =:= fun(X) -> X*X end (2).
```

###函数定义
[函数][functions]不能在 `erl` 中定义，所以我们将函数定义写在 `mymethod.erl` 模块中。

[functions]: http://erlang.org/doc/reference_manual/functions.html

```Erlang
% mymethod.erl
-module(mymethod).

% 要想在外部调用模块中的函数，首先得将函数导出
% -export([Function1/Arity, ..., FunctionN/Arity]).
-export([hi/0]).

% 调试的时候可以使用下面的语句导出所有函数
% -compile(export_all).

% 不需要 `end`
hi() ->
    "hello, world".
```

函数名是一个 atom，函数定义的形式如下：

```Erlang
% 函数头部
function(Arg1, Arg2, ..., Arg3) ->
    % 函数体
    Expression1,
    Expression2,
    ...
    % 表达式的结果作为返回值
    ExpressionN.
```

其他语言中的 `if ... else ...` 可以通过函数分句和模式匹配来实现：

```python
def all_the_same(a, b, c):
    if a == b == c:
        return True
    else:
        return False
```

```Erlang
% 按函数分句的先后顺序进行模式匹配
% 找到第一个参数匹配的分句时，执行该分句下的表达式
% 分号表分句的结束，句号表整个函数的结束
all_the_same(X, X, X) -> true;
% `_` 是匿名变量
all_the_same(_, _, _) -> false.
```

有时候需要匹配一定范围内的值，这时候模式匹配就略显不足了。

```Erlang
is_adult(1) -> false;
...
is_adult(17) -> false;
is_adult(_) -> true.
```

所以 Erlang 有 guard（断言）。Guard 以 `when` 关键字开头，可出现在**函数头部**或**表达式**中。

```Erlang
is_adult(Age) when Age < 18 -> false;
is_adult(_) -> true.
```

Guard 可以由一系列 guard 表达式组成。

```Erlang
% 逗号在 guard 中的作用类似于 `and`
is_triangle(A, B, C) when A+B > C, B+C > A, A+C > B -> true;
is_triangle(_, _, _) -> false.

% 分号在 guard 中的作用类似于 `or`
is_num(X) when is_integer(X); is_float(X) -> true;
is_num(_) -> false.
```

下面给出几个例子帮助你熟悉函数定义：

```Erlang
bro(Girlfriend) when Girlfriend == girl -> 
    io:format("fall in love with ~p~n", [Girlfriend]);
% 若参数未被使用，编译时会发出警告：`Warning: variable 'Girl' is unused`
% 如果参数名以下划线开头，则不会警告
bro(_Girl) ->
    io:format("cheat!~n").

% 参数数目不同但同名的函数没有任何关系
bro() ->
    io:format("I'm a single dog~n").

% 根据参数的模式匹配执行不同的分句
yo(brother) ->
    io:format("Hi, man!~n");
yo(friend) ->
    io:format("How are you?~n");
yo(People) ->
    io:format("Are you \"~p\"?~n", [People]).

% 计算列表的和
sum(L) -> sum(L, 0).                    % 句号
sum([], Result)    -> Result;           % 分号
sum([H|T], Result) -> sum(T, H+Result). % 又是句号，为什么？
```

在 `erl` 中编译并运行。

```Erlang
% 编译当前目录下的 `mymethod.erl` 模块
c(mymethod).
% 可以使用 `cd` 切换目录
% cd("/path/to/where/you/saved/the-module/").

% 函数调用的形式是：`Module:Function(Arguments).`
% erl 会寻找 `Module.beam` 文件中 `Function` 的定义
mymethod:hi().
% 内建函数（BIFs: built-in functions）会被自动导入，不需要指出模块名
date().
% `seq` 并没有被自动导入，但你可以直接使用
lists:seq(1,4). % [1,2,3,4]
```

查看更多内建函数点[这里](http://linux.die.net/man/3/Erlang)。

## if 与 case 表达式
```Erlang
% `if` 类似于 guard，并且语法和 guard 一致
hi_if(X) -> 
    % `if` 也有返回值
    Result = if 
        % 必须匹配所有的逻辑，否则会 crash
        X > 0 -> positive;
        X == 0 -> zero;
        % 匹配剩下的所有可能
        true -> negative
    end,
    io:format("if expression result is '~p'~n", [Result]).

% `case` 类似于函数头部，其余部分和 `if` 几乎一样
hi_case(X) ->
    Result = case X of
        X when X > 0 -> positive;
        X when X == 0 -> zero;
        % 匹配剩下的所有可能
        _ -> negative
    end,
    io:format("case expression result is '~p'~n", [Result]).
```

##Record
[Record][] 是一种类似于 C 语言中结构体的数据结构，它会在编译期间被转换成元组。record 定义不能出现在 `erl` 中，但是可以定义在 `.erl` 或 `.hrl` 中，这里我们定义在 `bar.hrl` 中。

[Record]: http://erlang.org/doc/reference_manual/records.html

```Erlang
% bar.hrl
% record 将元组中的元素绑定到特定的名称
-record(point, {x = 0, y}). 
% 本质是元组 `{point, X = 0, Y = undefined}`
```

然后在 `erl` 中使用 record。

```Erlang
% 使用函数 `rr`（read records）导入 record 的定义
rr("bar.hrl").  

% 创建 record
P0 = #point{}.               % #point{x = 0,y = undefined}
P1 = #point{y = 0}.          % #point{x = 0,y = 0}
% 在 `P1` 的基础上创建 record
P2 = P1#point{x = 1}.        % #point{x = 1,y = 0}
% 读取 record 的成员
P2#point.x + P2#point.y.     % 1
```

当然，你也可以在模块中使用。

```Erlang
% bar.erl
-module(bar).
-include("bar.hrl").
-compile(export_all).

distance(P) when is_number(P#point.x), is_number(P#point.y) ->
    math:sqrt(P#point.x*P#point.x + P#point.y*P#point.y).

% record 在 function clause 中的匹配很违背直觉
% 仅匹配 `#point.y == 1`，而不管 `#point.x` 是不是 `0`
test(#point{y = 1}) -> io:fwrite("x=? y=1~n");
% 仅匹配 `#point.x == 1`，而不管 `#point.y` 是什么值
test(#point{x = 1}) -> io:fwrite("x=1 y=?~n").

test() ->
    P1 = #point{x = 1, y = 0},
    P2 = {point, 1, 0},
    case distance(P1) =:= distance(P2) of
        true -> ok;
        false -> error("Oh My God! This is impossible!")
    end,
    test(#point{x = whatever, y = 1}), % x=? y=1
    test(#point{x = 1, y = 1}),        % x=? y=1
    test(#point{x = 1, y = whatever}). % x=1 y=?
```

详见[官方文档](http://erlang.org/doc/reference_manual/records.html)。

##宏定义
宏定义的语法如下：

```Erlang
-define(Const, Replacement).
-define(Func(Var1,...,VarN), Replacement).
```

我们新建一个 `mymath.erl` 文件实验宏定义。

```Erlang
% mymath.erl
-module(mymath).
-compile(export_all).
% 自定义的宏
-define(ONE, 1).
-define(ADD(X, Y), X+Y).

test() ->
    io:format("predefined macros: ~n"), 
    % 预定义的宏
    io:format("~p ~p ~p ~p ~p~n", [?MODULE, ?MODULE_STRING, ?FILE, ?LINE, ?MACHINE]),
    % `?MACRO` 调用宏
    io:format("one=~p add(1,2)=~p~n", [?ONE, ?ADD(1, 2)]).
```

然后在 `erl` 中编译运行。

```Erlang
c(mymath).
mymath:test().
% predefined macros:
% mymath "mymath" "mymath.erl" 8 'BEAM'
% one=1 add(1,2)=3
```

详见[官方文档](http://erlang.org/doc/reference_manual/macros.html)。

##异常
捕获异常的语法如下：

```Erlang
try Expression of
    % guards 是可选的
    SuccessfulPattern1 [Guards] ->
        Expression1;
    SuccessfulPattern2 [Guards] ->
        Expression2
catch
    TypeOfError:ExceptionPattern1 ->
        Expression3;
    TypeOfError:ExceptionPattern2 ->
        Expression4
% after 语句在 `try...catch` 语句之后执行
after 
    Expr3
end.
```

我们新建 `catcher.erl` 文件，对 `try...catch` 语句进行实验。

```Erlang
% catcher.erl
-module(catcher).
-compile(export_all).

% `throw`, `exit`, `error` 三者都能产生异常
do_something(throw) -> throw(lol);      % ** exception throw: lol
do_something(exit) -> exit(lol);        % ** exception exit: lol
do_something(error) -> error(lol);      % ** exception error: lol
do_something(X) -> X.

normal_catcher(X) ->
    try do_something(X) of
        Result -> io:format("do_something(~p) => ~p~n", [X, Result])
    catch
        throw:E -> io:format("catch throw: ~p~n", [E]);
        exit:E  -> io:format("catch exit: ~p~n", [E]);
        error:E -> io:format("catch error: ~p~n", [E])
    end.

all_catcher(X) ->
    try do_something(X) of
        Result -> io:format("do_something(~p) => ~p~n", [X, Result])
    catch
        % 省略错误类型
        % 默认为 throw 类型
        E -> io:format("catch you: ~p~n", [E])
    after
        io:format("after `try...catch`~n")
    end.

simple_catcher(X) ->
    % 将异常转换为一个描述异常的元组
    % 如果没有异常，则返回表达式的值
    catch do_something(X).
```

##进程与消息
Erlang 的每个进程都有一个消息队列保存收到的消息，而 receive 语句是用来从消息队列中提取消息的。receive 会遍历消息队列，直到找到能够匹配的消息，将其从消息队列中移除，并执行相应的 receive 处理逻辑。[^conc_prog]

[^conc_prog]: 详见官方文档 [Concurrent Programming](http://www.erlang.org/doc/getting_started/conc_prog.html)

receive 的语法如下：

```Erlang
receive
    Pattern1 [Guards1] -> Expressions1;
    Pattern2 [Guards2] -> Expressions2
% after 语句是可选的，意为：
% 如果 `Timeout` 毫秒后没收到消息，执行 `Expressions3`
after Timeout ->
    Expressions3
end.
```

发送消息的语法很简单：

```Erlang
Pid ! Message.
```

我们在 `erl` 中直观的感受一下接发消息的过程。

```Erlang
% `self()` 获取当前进程的 pid
% `process_info(Pid)` 用来查看进程运行时信息
% 返回结果中的 `messages` 字段就是消息队列的内容
process_info(self()).

% 向 Erlang shell 进程发送一个消息 `hi`
self() ! {self(), "a_more_complex_case"}.
self() ! hi.
self() ! [i, am, a, list].
% 现在消息队列中有两个消息了
process_info(self()).

receive
    hi -> io:format("get hi~n")
end.
receive
    Msg -> io:format("get: ~p~n", [Msg])
end.
% 被 receive 取完后，消息队列就空了
process_info(self()).
```

下面新建一个 `m.erl` 文件实验一些更复杂的例子。

```Erlang
% m.erl
-module(m).
-export([start_echo/0, start_hurry/0]).

echo() ->
    receive
        {From, Msg} ->
            io:format("~p => ~p: ~p~n", [From, self(), Msg]),
            From ! Msg,
            % 循环接收消息
            echo()
    % 如果10秒内没收到消息，就执行 after 语句
    after 10000 ->
        io:format("quit echo process~n")
    end.

% `after 0` 的逻辑类似于：
% if is_not_empty(message_queue)
%     receive()
% else
%     after()
do_hurry() ->
    receive
        Msg ->
            io:format("message: '~p'~n", [Msg]),
            do_hurry()
    after 0 ->
        io:format("no more message, quit~n")
    end.

% 等待10秒后从消息队列中取出所有消息
hurry(Wait) ->
    timer:sleep(Wait),
    do_hurry().

start_echo() ->
    % 调用 `spawn` 启动新进程，并返回一个pid（进程标识符）
    % 在 `erl` 中调用为 `spawn(Function)`，在模块中为 `spawn(fun Function/0)`
    spawn(fun echo/0).

start_hurry() ->
    spawn(fun() -> hurry(10000) end).
```

然后在 `erl` 中运行。

```Erlang
% 启动新进程，将新进程 pid 与 `E` 绑定
E = m:start_echo().
% Erlang shell 进程发送消息 "hi" 给 `E` 进程
E ! {self(), "hi"}.
% 接收 `echo` 传回的消息
receive 
    Msg -> io:format("received from echo:~p~n", [Msg]) 
end.
% 如果10秒没有再发消息给 `E` 进程，它会执行 after

H = m:start_hurry().
H ! {self(), "hello"}.
H ! yo.
H ! [hi, bro].
```

-------

#参考
* [Learn X in Y minutes: Erlang](http://learnxinyminutes.com/docs/Erlang/)
* [Learn You Some Erlang](http://learnyousomeErlang.com/)
