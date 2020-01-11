title: Erlang 和编码风格--对大多数防御性编码风格的思考 
date: 2015-09-20 12:09:00
tags: 翻译, Erlang, 编程语言 

原文：[Erlang and code style--Musings on mostly defensive programming styles][Erlang and code style]

[Erlang and code style]: https://medium.com/@jlouis666/erlang-and-code-style-b5936dceb5e4

<!--- SUMMARY_END -->

-----------

> Correct Erlang usage mandates you do not write any kind of defensive code. This is called *intentional programming*. You write code for the intentional control flow path which you expect the code to take. And you don’t write any code for the paths which you think are not possible. Furthermore, you don’t write code for data flow which was not the intention of the program.

正确的 Erlang 编程方式要求你不写任何防御性代码[^defensive code]，即所谓的*意图编程*[^intentional programming]。你给能够抵达意图且会被执行的控制流路径编写代码，并且不对不可能到达的逻辑编写任何代码。而且，你不会为与程序意图无关的数据流编写代码。

[^defensive code]: 防御性编程强调对错误防范于未然，未雨绸缪，对程序中任何可能出现错误的地方编写处理逻辑。参见[防御性编程][]、[防御性编程与疯狂偏执性编程][]
[^intentional programming]: 意图编程强调把注意力放在能有的，能实现意图的东西上。参见 [Intentional_programming][]、[意图编程][]

[防御性编程]: https://zh.wikipedia.org/wiki/防御性编程
[防御性编程与疯狂偏执性编程]: http://www.codeceo.com/article/defensive-programming-vs-crazy-programming.html
[Intentional_programming]: https://en.wikipedia.org/wiki/Intentional_programming#Programming_Example
[意图编程]: http://book.51cto.com/art/201010/230850.htm

#结果证明防御性编程很蠢[^title1]

> If an Erlang program goes wrong, it crashes. Say we are opening a file. We can *guard* the file open call like so:

如果 Erlang 程序发生错误，它就崩溃。假如我们要打开一个文件，我们能*断言*打开文件的调用，像这样：

```erlang
{ok, Fd} = file:open(Filename, [raw, binary, read, read_ahead]),
```

> What happens if the file doesn’t exist? Well the process crashes. But note we did not have to write any code for that path. The default in Erlang is to crash when a match isn’t valid. We get a badmatch error with a reason as to why we could not open the file.

如果文件不存在，会发生什么？进程崩溃。但是请注意，我们不需要写任何代码来做到这一点。当匹配无效的时候，Erlang 的默认行为就是崩溃。我们会获得一个错误匹配的错误，并给出我们不能打开这个文件的原因。

> A process crashing is not a problem. The *program* is still operating and supervision--An important fault-tolerance concept in Erlang--will make sure that we try again in a little while. Say we have introduced a race condition on the file open, by accident. If it happens rarely, the program would still run, even if the file open fails from time to time.

进程崩溃不是问题，问题是*程序*会继续操作，监视器（一个在 Erlang 中重要的错误容忍概念）会在一小段时间后再次尝试。假如在打开文件时，我们不小心引入了一个竞争条件。如果这种情况很少发生，程序仍会继续运行，即使打开文件的操作一次又一次的失败。

> You will often see code that looks like:

你会经常见到像这样的代码：

```erlang
ok = foo(...),
ok = bar(...),
ok = ...
```

> which then asserts that each of these calls went well, making sure code crashes if the control and data flow is not what is expected.

它断言所有的调用都会成功，确保控制流和数据流如果不是所期望的，代码就崩溃。

> Notice the complete lack of error handling. We don’t write

注意，完全没有错误处理。我们不写这样的代码：

```erlang
case foo(...) of
    ok -> case bar(...) of ... end;
    {error, Reason} -> throw({error, Reason})
end,
```

> Nor do we fall into the trap of the Go programming language and write:

也不会落入 Go 语言的圈套中，写出像这样的代码：

```go
res, err := foo(...)
if err != nil {
    panic(...)
}
res2, err := bar(...)
if err != nil {
    panic(...)
}
```

> because this is also plain silly, tedious and cumbersome to write.

因为这同样很蠢，并且写起来又累赘又乏味。

> The key is that we have a crash-effect in the Erlang interpreter which we can invoke where the *default* is to crash the process if something goes wrong. And have another process clean up. Good Erlang code abuses this fact as much as possible.

关键在于 Erlang 解释器能使进程崩溃，如果发生错误，它*默认*让进程崩溃，并且让另一个进程进行清理。漂亮的 Erlang 代码会尽可能的使用这个作用。

#意图？[^title2]

> Note the word intentional. In some cases, we *do* expect calls to fail. So we just handle it like everyone else would, but since we can emulate sum-types in Erlang, we can do better than languages with no concept of a sum-type:

注意「意图」这个词。在某些情况下，我们*的确*希望函数调用失败。于是我们像其他所有人一样去处理失败的函数调用，但是因为我们在 Erlang 中能模拟 sum-types[^sum-types]，所以我们能比那些没有 sum-type 的语言做得更好：

[^sum-types]: 一种用来表示多种不同类型的数据结构。详见：[Tagged_union][]

[Tagged_union]: https://en.wikipedia.org/wiki/Tagged_union

```erlang
case file:open(Filename, [raw, read, binary]) of
    {ok, Fd} -> ...;
    {error, enoent} -> ...
end,
```

> Here we have written down the intention that the file might not exist. However:

> * We *only* worry about non existence.
> * We crash on *eaccess* which means an access error due to permissions.
> * Likewise for *eisdir, enotdir, enospc*.

我们在上述代码中写下了文件可能不存在的意图。然而：

* 我们*仅仅*关心文件不存在的情况。
* 我们希望在遇到 *eaccess* 时崩溃，表示因为权限的关系，发生了访问错误。
* 我们希望在遇到 *eisdir, enotdir, enospc* 时的行为也和 *eaccess* 一样。

#为什么？

> Leaner code, that’s why.

精炼的代码，这就是为什么。

> We can skip lots of defensive code which often more than halves the code size of projects. There are much less code to maintain so when we refactor, we need to manipulate less code as well.

我们能减少许多防御性代码，这些防御性代码经常超过项目代码量的一半。所以当我们重构时，需要维护的代码少很多，同时，需要我们掌控的代码也更少。

> Our code is not littered with things having nothing to do with the “normal” code flow. This makes it far easier to read code and determine what is going on.

我们的代码不是和“正常”代码流无关的垃圾。这使得代码非常易读，并且非常容易确定发生了什么。

> Erlang process crashes gives lots of information when something dies. For a proper OTP process, we get the State of the process before it died and what message was sent to it that triggered the crash. A dump of this is enough in about 50% of all cases and you can reproduce the error just by looking at the crash dump. In effect, this eliminates a lot of silly logging code.

当什么东西挂了的时候，Erlang 进程的崩溃提供了很多信息。对一个良好的 OTP 进程，在它挂掉之前，我们会得到进程的状态，也会得到发送给它并导致它崩溃的消息。在 50% 的情况下，这个过程的堆能提供足够的信息，并且仅仅通过观察崩溃进程的堆就能重现错误。事实上，这减少了许多蠢蠢的日志记录代码。

#数据流防御性编程[^title3]

> Another common way of messing up Erlang programs is to mangle incoming data through pattern matching. Stuff like the following:

另一种将 Erlang 程序弄成一团糟的常见方法是使用模式匹配把传入的数据弄乱。像下面这样：

```erlang
convert(I) when is_integer(I) -> I;
convert(F) when is_float(F) -> round(F);
convert(L) when is_list(L) -> list_to_integer(L).
```

> The function will convert “anything” to an integer. Then you proceed to use it:

这个函数会把“任何东西”转换成整数。接着你会使用它：

```erlang
process(Anything) -> I = convert(Anything), ...I...
```

> The problem here is not with the **process** function, but with the call-sites of the **process** function. Each call-site has a different opinion on what data is being passed in this code. This leads to a situation where every subsystem handles conversions like these.

问题不在于 **process** 函数，而在于对 **process** 函数的调用。每次调用都得用不同的观点来看待传进这段代码的数据，导致子系统都得像这样对数据进行转换。

> There are several disguises of this anti-pattern. Here is another smell:

这种反模式有几种伪装。下面是另外一种“充满臭味”的代码：

```erlang
convert({X, Y}) -> {X, Y};
convert(B) when is_binary(B) ->
    [X, Y] = binary:split(B, <<"-">>),
    {X, Y}.
```

> This is stringified programming where all data are pushed into a string and then manually deconstructed at each caller. It leads to a lot of ugly code with little provision for extension later.

这叫字符串编程，将所有的数据放入同一个字符串，并且每个调用者都去手动解构该字符串。这种编程方式会产生一大坨丑陋的代码，并且几乎没有扩展性。

> Rather than trying to handle different types, enforce the invariant early on the api:

与其尝试处理不同类型的数据，不如在 API 中尽早的强制数据不可变：

```erlang
process(I) when is_integer(I) -> ...
```

> And then *never* test for correctness inside your subsystem. The dialyzer is good at inferring the use of *I* as an integer. Littering your code with **is_integer** tests is not going to buy you anything. If something is wrong in your subsystem, the code will crash, and you can go handle the error.

并且*绝不要*在子系统中测试数据的正确性，推断出 *I* 作为整数使用是解析器所擅长的工作。代码中杂乱分布的 **is_integer** 测试不会让你付出任何代价，并且如果在你的子系统中什么东西出错了，它会让你的代码崩溃，然后你就能处理这个错误了。

> There is something to be said about static typing here, which will force you out of this unityped world very easily. In a statically typed language, I could still obtain the same thing, but then I would have to define something along the lines of (\* Standard ML code follows \*)

这里需要谈一谈静态类型，静态类型很容易强迫你脱离单一类型。在静态类型语言中，仍能得到同样的东西，但是我必须定义某些与下面几行类似的东西（\* 下面是标准 ML 代码 \*）

```sml
datatype anything = INT of int
                  | STRING of string
                  | REAL of real
```

> and so on. This quickly becomes hard to write pattern matches for, so hence people only defines the *anything* type if they really need it. (Gilad Bracha was partially right when he identified this as a run-time check on the value, but what he omitted was the fact that the programmer has the decision to avoid a costly runtime check all the time—come again, Gilad ☺).

或者更多这种东西。为它编写模式匹配的代码很快就变得困难重重，因此如果有人真的需要模式匹配，他就会只定义一个*任意*类型。（当 Gilad Bracha 把它当做是值的运行时检查时，他只是部分正确，他所忽略的事实是——程序员总是有权避免昂贵的运行时检查。又来了，Gilad ☺）

# undefined 的祸害
> Another important smell is that of the *undefined* value. The story here is that undefined is often used to program a Option/Maybe monad. That is, we have the type

另一种主要的“充满臭味”的代码是那些使用 *undefined* 的代码。这是指 undefined 经常被用来编写可选的或可能的 monad。也就是说，我们有如下的类型

```erlang
-type option(A) :: undefined | {value, A}.
```

> [For the static typists out there: Erlang *does* have a type system based on success types for figuring out errors, and the above is one such type definition]

[对于待在那儿的静态类型们：Erlang*确实*有基于成功类型[^success types]的类型系统来找出错误，上面的代码就是这样一种类型定义]

[^success types]: success types 应该理解为「函数成功执行得到的返回值所具有的类型」，即与返回错误类型相对的类型

> It is straightforward to define reflection/reification into an exception-effect for these. Jakob Sievers `stdlib2` library already does this, as well as define the monadic helper called **do** (Though the monad is of the Error-type rather than Option).

给这些静态类型将反射[^reflection]或具体化定义到一个异常作用中很简单。Jakob Sievers 的 `stdlib2` 库已经实现了这一点，并定义了一个叫做 **do** 的 monadic helper（虽然这个 monad 是错误类型而不是 Option[^option type]）。

[^option type]: 这里的 Option 不是「可选」的意思，而是指 [option type][]
[^reflection]: 反射是指程序在运行时可以访问、检测和修改它本身状态或行为的一种能力。详见 [reflection][]

[reflection]: https://zh.wikipedia.org/wiki/反射_(计算机科学)
[option type]: https://en.wikipedia.org/wiki/Option_type

> But I’ve seen:

但是我看到了这样的代码：

```erlang
-spec do_x(X) -> ty() | undefined
  when X :: undefined | integer().
do_x(undefined) -> undefined;
do_x(I) -> ...I....
```

> Which leads to complicated code. You need to be 100% in control of what values can fail and what values can not. Constructions like the above silently passes undefined on. This has its uses--but be wary when you see code like this. The *undefined* value is essentially a *NULL*. And those were C.A.R Hoare’s billion dollar mistake.

这种方式导致代码变得复杂。你需要 100% 的控制哪些值能够失败，哪些不能。与上述结构类似的结构会悄悄的传递 undefined。虽然这种方式有适用之处，但是看到这样的代码的时候要小心。*undefined* 本质上是一种 *NULL*，而 NULL 又是「C.A.R Hoare 的百万美元错误」[^C.A.R Hoare’s billion dollar mistake]

[^C.A.R Hoare’s billion dollar mistake]: 详见 [Tony Hoare][] 和 [他的演讲][]

[Tony Hoare]: https://en.wikipedia.org/wiki/Tony_Hoare#Apologies_and_retractions
[他的演讲]: http://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare

> The problem is that the above code is *nullable*. The default in Erlang is that you never have NULL-like values. Introducing them again should be used sparingly. You will have to think long and hard because once a value is nullable, it is up to you to check this all the time. This tend to make code convoluted and complicated. It is better to test such things up front and then leave it out of the main parts of the code base as much as possible.

问题是上述代码是 *类 NULL 的*。Erlang 默认绝不出现类似 NULL 的值，所以应该小心翼翼的再次引入它们。你必须仔细并慎重的考虑要不要引入它们，因为一旦一个值是类 NULL 的，那你就得从始至终的检查它。这种做法很容易让代码变得错综复杂。最好是在一开始就测试这些值，然后让它尽可能的远离代码的主要部分。

#「开放」数据表示法

> Whenever you have a data structure, there is a set of modules which knows about and operates on that data structure. If there is only a single module, you can emulate a common pattern from Standard ML or OCaml where the concrete data structure representation is abstract for most of the program and only a single module can operate on the abstract type.

无论什么时候，只要有数据结构存在，就一定有一系列模块知道这个数据结构的存在并在它上面进行操作。如果只有一个模块，你可以参照标准 ML 或 OCaml[^ML_OCaml] 模拟一个通用模式，这两种语言的数据结构表达对于大部分程序都是抽象的，并且只存在单一模块能操作这些抽象类型。

[^ML_OCaml]: 两种函数式语言

> This is not entirely true in Erlang, where anyone can introspect any data. But keeping the illusion is handy for maintainability.

Erlang 不完全是这样，任何人都能内省[^introspect]到任何数据，但是保持这一点让程序更容易维护。

[^introspect]: 内省就是运行时类型检查。详见 [内省][]、[type introspection][] 和 [program introspection][]

[内省]: https://zh.wikipedia.org/wiki/内省_(计算机科学)
[type introspection]: https://en.wikipedia.org/wiki/Type_introspection
[program introspection]: https://www.opengl.org/wiki/Program_Introspection

> The more modules that can manipulate a data structure, the harder it is to alter that data structure. Consider this when putting a record in a header file. There are two levels of possible creeping insanity:

> * You put the record definition in a header file in **src**. In this case only the application itself can see the records, so they don’t leak out.
> * You put the record definition in a header file in **include**. In this case the record can leak out of the application and often will.

可以操作一个数据结构的模块越多，替换这个数据结构的难度就越大。考虑将记录定义在头文件中的方式，有两种可能让人慢慢抓狂的做法：

* 你把记录定义在 **src** 文件夹下的一个头文件中。在这种情况下，只有该应用能看到这些记录，所以它们不会泄露。
* 你把记录定义在 **include** 文件夹下的一个头文件中。在这种情况下，记录可能从该应用中泄露出去，并且这种情况经常发生。

> A good example is the HTTP server *cowboy* where its request object is manipulated through the **cowboy_req** module. This means the internal representation can change while keeping the rest of the world stable on the module API.

HTTP 服务器 *cowboy* 是个很好的例子，它通过 **cowboy_req** 模块操作 request 对象。这意味着即使内部数据结构的表示发生改变，基于 cowboy_req 模块的 API 的其它代码不受影响。

> There are cases where it makes sense to export records. But think before doing so. If a record is manipulated by several modules, chances are that you can win a lot by re-thinking the structure of the program.

有时候导出记录是有用的，但是请仔细考虑后，再决定要不要这么做。如果同一个记录被多个模块所使用，可能重新考虑程序结构会更好。

#“true” 和 “false” 是 atom() 类型

> As a final little nod, I see too much code looking like

最后一小点，我看到很多像这样的代码：

```erlang
f(X, Y, true, false, true, true),
```

> Which is hard to read. Since this is Erlang, you can just use a better name for the true and false values. Just pick an atom which makes sense and then produce that atom. It also has the advantage to catch more bugs early on if arguments get swapped by accident. Also note you can bind information to the result, by passing tuples. There is much to be said about the concept of *boolean blindness* which in typical programs means to rely too much on boolean() values. The problem is that if you get a *true* say, you don’t know why it was true. You want *evidence* as to its truth. And this can be had by passing this evidence in a tuple. As an example, we can have a function like this:

这种代码的可读性很低。因为这是 Erlang 代码，所以可以采用更恰当的命名来表示 true 和 false。选一个有意义的 atom，把它用在那儿。这样做的另一个好处是，如果不小心交换了参数的位置，你能尽早的捕捉到更多的 bug。还要注意，通过传递元组，你可以绑定信息到函数返回值中。关于 *boolean 盲目*有很多可说的，它意味着在典型程序中过分依赖于 boolean() 值。问题在于如果你表示了一个 *true* 值，你不知道为什么它是真，你需要*迹象*来表露这一点[^true_or_false]。可以通过在元组中传递这个迹象来表明为什么是 true。比如，我们有个函数像这样：

[^true_or_false]: 作者的意思是 true 和 false 是对称的，用 true 的地方也能用 false 替代，那么为什么要用 true 而不是 false 呢？所以需要上下文提供额外的信息来说明为什么用 true。

```erlang
case api:resource_exists(ID) of
    true -> Resource = api:fetch_resource(ID), ...;
    false -> ...
end.
```

> But we could also write it in a more direct style:

但是我们可以用更直接了当的方式写出来：

```erlang
case api:fetch_resource(ID) of
    {ok, Resource} -> ...;
    not_found -> ...
end.
```

> (**Edit:** I originally used the function name `resource_exists` above but Richard Carlsson correctly points out this is a misleading name. So I changed it to something with a better name)

（**修改：** 我原本是在上述例子中使用 `resource_exists` 作为函数名，但是 Richard Carlsson 指出它具有误导性。因此我改了个更好的函数名）

> which in the long run is less error prone. We can’t by accident call the *fetch_resource* call and if we look up the resource, we also get hold of the evidence of what the resource is. If we don’t really want to use the resource, we can just throw it away.

这种方式在长远看来更少出错。我们不会意外的调用 *fetch_resource* 函数，并且如果查找资源，我们能同时获得迹象，表明资源是什么。如果不是真的打算使用这个资源，可以简单的丢弃它。

#结束语

> Rules of thumb exists to be broken. So once in a while they must be broken. However, I hope you learnt something or had to stop and reflect on something if you happened to get here (unless you scrolled past all the interesting stuff).

经验规则就是用来被打破的。所以，偶尔必须打破这些规则。然而，我希望你学到一些东西，或者卡在某个地方的时候仔细思考（除非你跳过了[^scrolled past]所有这些有意思的东西）

[^scrolled past]: scrolled past 意为「在浏览器中往下滚动，从而跳过了某些内容」

> I am also interested in Pet-peeves of yours, if I am missing some. The way to become a better programmer is to study the style of others.

我对文章中让你反感的东西[^Pet-peeves]也感兴趣，如果我没注意到它们，请告诉我。成为一个优秀程序员的方法是学习其他优秀程序员的风格[^style]。

[^Pet-peeves]: Pet-peeves 是指「厌恶的东西」。作者可能是指某些编程风格的派系之争，类似与「PHP 是世界上最好的语言 :)」
[^style]: 这里的 style 可能是指「优秀程序员的编码风格」，也可能是指「优秀程序员的编码风格和做事方式」

[^title1]: 原文：It is an effect, silly
[^title2]: 原文：Intentional?
[^title3]: 原文：Data flow defensive programming
[^title4]: 原文：The scourge of undefined
[^title5]: 原文：“Open” data representations
[^title6]: 原文：The values ‘true’ and ‘false’ are of type atom()
[^title7]: 原文：Closing remarks
