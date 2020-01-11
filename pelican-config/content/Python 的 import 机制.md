title: Python 的 import 机制  
date: 2016-04-25 14:15:50  
tags: Python, 编程语言

一直对 Python 的 import 机制不甚了解，这次在写 [Easy-Karabiner](https://github.com/loggerhead/Easy-Karabiner) 的时候就踩坑了，顺便了解了一下，发现这玩意儿还不是那么「符合直觉」，遂写篇博客讲讲。

<!--- SUMMARY_END -->

[TOC]

# 模块与包

在了解 import 之前，有两个概念必须提一下：

* 模块: 一个 `.py` **文件**就是一个模块（module）
* 包: `__init__.py` 文件所在**目录**就是包（package）

当然，这只是极简版的概念。实际上包是一种特殊的模块，而任何定义了 `__path__` 属性的模块都被当做包。只不过，咱们日常使用中并不需要知道这些。

# 两种形式的 import

`import` 有两种形式：

* `import ...`
* `from ... import ...`

两者有着很细微的区别，先看几行代码。

```python
from string import ascii_lowercase
import string
import string.ascii_lowercase
```

运行后发现最后一行代码报错：`ImportError: No module named ascii_lowercase`，意思是：“找不到叫 ascii_lowercase 的模块”。第 1 行和第 3 行的区别只在于有没有 `from`，翻翻[语法定义](https://docs.python.org/2/reference/simple_stmts.html#import)发现有这样的规则：

* `import ...` 后面只能是模块或包
* `from ... import ...` 中，`from` 后面只能是模块或包，`import` 后面可以是任何变量

可以简单的记成：*第一个空只能填模块或包，第二个空填啥都行*。

# import 的搜索路径

提问，下面这几行代码的输出结果是多少？

```python
# foo.py
import string
print(string.ascii_lowercase)
```

是小写字母吗？那可不一定，如果目录树是这样的：

```
./
├── foo.py
└── string.py
```

`foo.py` 所在目录有叫 `string.py` 的文件，结果就不确定了。因为你不知道 `import string` 到底是 import 了 `./string.py` 还是标准库的 `string`。为了回答这个问题，我们得了解一下 import 是怎么找到模块的，这个过程比较简单，只有两个步骤：

1. 搜索「内置模块」（built-in module）
2. 搜索 `sys.path` 中的路径

而 `sys.path` 在初始化时，又会按照顺序添加以下路径：

1. **`foo.py` 所在目录**（如果是软链接，那么是真正的 `foo.py` 所在目录）或**当前目录**；
2. **环境变量 `PYTHONPATH`**中列出的目录（类似环境变量 `PATH`，由用户定义，默认为空）；
3. **`site` 模块**被 import 时添加的路径[^import-site]（`site` 会在运行时被自动 import）。

[^import-site]: 官方说法是「Python 安装时设定的默认路径」（The installation-dependent default path），而这玩意儿实际上是通过 `site` 模块来设置的。

`import site` 所添加的路径一般是 `XXX/site-packages`（Ubuntu 上是 `XXX/dist-packages`），比如在我的机器上是 `/usr/local/lib/python2.7/site-packages`。同时，通过 `pip` 安装的包也是保存在这个目录下的。如果懒得记 `sys.path` 的初始化过程，可以简单的认为 import 的查找顺序是：

1. 内置模块
2. `.py` 文件所在目录
3. `pip` 或 `easy_install` 安装的包

回到前面的问题，因为 `import string` 是通过搜寻 `foo.py` 文件所在目录，找到 `string.py` 后 import 的，所以输出取决于 import `string.py` 时执行的代码。

# 相对 import 与 绝对 import
## 相对 import

当项目规模变大，代码复杂度上升的时候，我们通常会把一个一个的 `.py` 文件组织成一个包，让项目结构更加清晰。这时候 import 又会出现一些问题，比如：一个典型包的目录结构是这样的：

```
string/
├── __init__.py
├── find.py
└── foo.py
```

如果 `string/foo.py` 的代码如下：

```python
# string/foo.py
from string import find
print(find)
```

那么 `python string/foo.py` 的运行结果会是下面的哪一个呢？

* `<module 'string.find' from 'string/find.py'>`
* `<function find at 0x123456789>`

按我们前面讲的各种规则来推导，因为 `foo.py` 所在目录 `string/` 没有 `string` 模块（即 `string.py`），所以 import 的是标准库的 `string`，答案是后者。不过，如果你把 `foo` 当成 `string` 包中的模块运行，即 `python -m string.foo`，会发现运行结果是前者。同样的语句，却有着两种不同的语义，这无疑加重了咱们的心智负担，总不能每次咱们调试包里的模块时，都去检查一下执行的命令是 `python string/foo.py` 还是 `python -m string.foo` 吧？

相对 import 就是专为解决「包内导入」（intra-package import）而出现的。它的使用也很简单，`from` 的后面跟个 `.` 就行：

```python
from .XXX import ...
```

比如：

```python
# from string/ import find.py
from . import find
# from string/find.py import *
from .find import *
```

我们再看个复杂点的例子，有个包的目录结构长这样：

```
one/
├── __init__.py
├── foo.py
└── two/
    ├── __init__.py
    ├── bar.py
    └── three/
        ├── __init__.py
        ├── dull.py
        └── run.py
```

`foo.py`、`bar.py`、`dull.py` 中的代码分别是 `print(1)`、`print(2)`、`print(3)`，并且 `run.py` 的代码如下：

```python
from . import dull
from .. import bar
from ... import foo
print('Go, go, go!')
```

我们通过 `python -m one.two.three.run` 运行 `run.py`，可以看到 `run.py` 运行结果如下：

```
3
2
1
Go, go, go!
```

意思就是，`from` 后面出现几个 `.` 就表示往上找第几层的包。也可以将 `run.py` 改写成下面这样，运行结果是一样的：

```python
from .dull import *
from ..bar import *
from ...foo import *
print('Go, go, go!')
```

好啦，相对 import 就介绍到这里，回到最初的问题。如果用相对 import，把 `string/foo.py` 改写成：

```python
# string/foo.py
from . import find
print(find)
```

那么 `python string/foo.py` 和 `python -m string.foo` 的运行结果又是怎样呢？运行一下发现，两者的输出分别是：

```python
Traceback (most recent call last):
  File "string/foo.py", line 1, in <module>
    from . import find
ValueError: Attempted relative import in non-package
```

```python
<module 'string.find' from 'string/find.py'>
```

原因在于 `python string/foo.py` 把 `foo.py` 当成一个单独的脚本来运行，认为 `foo.py` 不属于任何包，所以此时相对 import 就会报错。也就是说，无论命令行是怎么样的，运行时 import 的语义都统一了，不会再出现运行结果不一致的情况。

## 绝对 import

绝对 import 和相对 import 很好区分，因为从行为上来看，绝对 import 会通过搜索 `sys.path` 来查找模块；另一方面，除了相对 import 就只剩绝对 import 了嘛 :) 也就是说：

1. 所有的 `import ...` 都是绝对 import
2. 所有的 `from XXX import ...` 都是绝对 import

不过，第 2 点只对 2.7 及其以上的版本（包括 3.x）成立喔！如果是 2.7 以下的版本，得使用

```python
from __future__ import absolute_import
```

## 两者的差异

首先，绝对 import 是 Python 默认的 import 方式，其原因有两点：

* 绝对 import 比相对 import 使用更频繁
* 绝对 import 能实现相对 import 的所有功能

其次，两者搜索模块的方式不一样：

* 对于相对 import，通过查看 `__name__` 变量，在「包层级」（package hierarchy）中搜索
* 对于绝对 import，当不处于包层级中时，搜索 `sys.path`

前面在介绍 `sys.path` 的初始化的时候，我在有个地方故意模棱两可，即：

> foo.py 所在目录（如果是软链接，那么是真正的 foo.py 所在目录）或 当前目录

官方文档的原文是：

> the directory containing the input script (or the current directory).

这是因为当模块处于包层级中的时候，绝对 import 的行为比较蛋疼，官方的说法是：

> The submodules often need to refer to each other. For example, the surround module might use the echo module. In fact, such references are so common that the import statement first looks in the containing package before looking in the standard module search path. Thus, the surround module can simply use import echo or from echo import echofilter. If the imported module is not found in the current package (the package of which the current module is a submodule), the import statement looks for a top-level module with the given name.

但是在我的测试中发现，其行为可能是下面两者中的任意一种：

* `.py` 文件所在目录
* 当前目录

比如，对于目录结构如下的包：

```
father/
├── __init__.py
├── child/
│   ├── __init__.py
│   ├── foo.py
│   └── string.py
└── string/
    └── __init__.py
```

其中，`foo.py` 代码如下：

```python
import string
print(string)
```

`import string` 真正导入的模块是：

|  version   | `python -m child.foo` | `python child/foo.py` |
|------------|-----------------------|-----------------------|
| __2.7.11__ | `child/string.py`     | `child/string.py`     |
| __3.5.1__  | `string/__init__.py`  | `child/string.py`     |

如果将 `foo.py` 的代码改成（你可以 `print(sys.path)` 看看为什么改成这样）：

```python
import sys
sys.path[0] = ''
import string
print(string)
```

import 的模块就变成了：

|  version   | `python -m child.foo` | `python child/foo.py` |
|------------|-----------------------|-----------------------|
| __2.7.11__ | `child/string.py`     | `string/__init__.py`  |
| __3.5.1__  | `string/__init__.py`  | `string/__init__.py`  |

为了避免踩到这种坑，咱们可以这样子：

* 避免包或模块重名，避免使用 `__main__.py`
* 包内引用尽量使用相对 import

# import 的大致过程

import 的实际过程十分复杂，不过其大致过程可以简化为：

```python
def import(module_name):
    if module_name in sys.modules:
        return sys.modules[module_name]
    else:
        module_path = find(module_name)

        if module_path:
            module = load(module_path)
            sys.modules[module_name] = module
            return module
        else:
            raise ImportError
```

`sys.modules` 用于缓存，避免重复 import 带来的开销；`load` 会将模块执行一次，类似于直接运行。

# Tips

* import 会生成 `.pyc` 文件，`.pyc` 文件的执行速度不比 `.py` 快，但是加载速度更快
* 重复 import 只会执行第一次 import
* 如果在 `ipython` 中 import 的模块发生改动，需要通过 `reload` 函数重新加载
* `import *` 会导入除了以 `_` 开头的所有变量，但是如果定义了 `__all__`，那么会导入 `__all__` 中列出的东西

# 参考

* [\_\_name\_\_ 与 \_\_main\_\_](https://docs.python.org/3/library/__main__.html)
* [sys.path](https://docs.python.org/2/library/sys.html#sys.path)
* [PEP 328](https://www.python.org/dev/peps/pep-0328/)
* [How does python find packages?](https://leemendelowitz.github.io/blog/how-does-python-find-packages.html)
* [site 模块](https://docs.python.org/2/library/site.html)
* [The Module Search Path](https://docs.python.org/2/tutorial/modules.html#the-module-search-path)
* [环境变量 PYTHONPATH](https://docs.python.org/2/using/cmdline.html#envvar-PYTHONPATH)
* [The import system](https://docs.python.org/3/reference/import.html)
* [Traps for the Unwary in Python's Import System](http://python-notes.curiousefficiency.org/en/latest/python_concepts/import_traps.html)
* [The import statement](https://docs.python.org/3/reference/simple_stmts.html#import)
