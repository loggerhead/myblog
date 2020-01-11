title: LaTeX 排版简介--快速入门
date: 2015-04-18 16:24
tags: LaTeX

本文将介绍以下内容：

* LaTeX 对空格、换行、注释的处理
* LaTeX 命令的基本形式
* 如何进一步学习 LaTeX

但是**不介绍**：

- 如何安装 LaTeX。如果你是 Mac 用户，那么可以参考[这篇文章]({filename}./LaTeX 在 Mac 下的中文环境配置.md)。
- 基本的排版
- 常用的命令和环境

<!--- SUMMARY_END -->

#你好，世界
我们先看一个最简单的示例。

```latex
% 文档类型是 article
\documentclass{article}
% --- 导言区开始 ---
% 使用 xeCJK 宏包，用于排版中日韩文字，CJK 是 China、Japan、Korea 的缩写
\usepackage{xeCJK}
% 设置正文罗马族的 CJK 字体为 STSong，粗体：STHeiti，斜体：STKaiti
\setCJKmainfont[BoldFont=STHeiti,ItalicFont=STKaiti]{STSong}
% 设置正文无衬线族的 CJK 字体为 STXihei，粗体：STHeiti
\setCJKsansfont[BoldFont=STHeiti]{STXihei}
% 设置正文等宽族的 CJK 字体为 STFangsong
\setCJKmonofont{STFangsong}
% --- 导言区结束 ---
\begin{document}
你好，世界
\end{document}
```

相信看完示例，你会有很多疑问，比如：

1. ``%`` 是注释当前行吗？
2. 命令都是以 ``\`` 开头吗？
3. 既然 ``\documentclass`` 有参数，那是不是有别的文档类型？
4. 宏包是什么，有什么用？
5. 导言区是什么？
6. ``\begin{document}`` 和 ``\end{document}`` 的作用是什么？

如果将示例与下面的代码对比，是不是发现一些相似之处？相信看完下文你会得到答案的。

```c
// 导入 stdio.h 头文件
#include <stdio.h>
// main begin
void main()
{
    printf("你好，世界\n");
}
// main end
```


#输入文件
虽说大部分 LaTeX 的规则或命令都有一致的规律，但是也存在一些与直觉相违背的地方，特别是某些特殊的字符。这里先将这些字符列出来，再对某些字符进行说明。

|   显示   |          输入          |
|----------|------------------------|
| 空格 x 1 | 空白字符 x N、换行 x 1 |
| 新段     | 换行 x N (N > 1)       |
| 新行     | \\\\                   |
| \\       | \\textbackslash        |
| #        | \\#                    |
| $        | \\$                    |
| %        | \\%                    |
| ^        | \\^{}                  |
| &        | \\&                    |
| _        | \\_                    |
| {        | \\{                    |
| }        | \\}                    |
| ~        | \\~{}                  |

##导言区
``\documentclass`` 和 ``\begin{document}`` 之间的部分叫做**导言区**（preamble）。我们可以在导言区加载宏包或者设置影响整个文档的样式，比如：

- ``\usepackage{minted}`` 加载 minted 宏包，用于排版代码 
- 用 ``\setCJKxxxxfont{...}`` 设置中文字体
- ``\setlength{\parskip}{1em}`` 设置段间距为 [1em](http://tex.stackexchange.com/questions/8260/what-are-the-various-units-ex-em-in-pt-bp-dd-pc-expressed-in-mm)

LaTeX 文档必须以 ``\documentclass`` 开头。而所有**想要显示的内容**都必须位于 ``\begin{document}`` 和 ``\end{document}`` 之间。 

##空格
LaTeX 第一个与直觉相违背的地方就是空白字符。它既不像C语言全部忽略，也不是有多少就显示多少。而是将**多个空白字符当做一个空格**处理。这里所说的空白字符包括：空格、制表符（tab）或一个换行。

![spaces example](https://loggerhead.me/_images/spaces_example.png)

左边是输入，右边是输出（下文同）。输入是 ``你好，[换行][空格x2]世界`` 。

##换行
虽然换行也是空白字符，但对一个换行和多个换行的处理又有不同：

- 一个换行 = 一个空格
- 多个换行**表示一个段落的结束和另一个段落的开始**（和 Markdown 一样）。

![paragraph example](https://loggerhead.me/_images/paragraph_example.png)

##注释
###单行注释
``%`` 表示注释当前行，同时**忽略换行和下一行开头的空白字符**。

![comment example](https://loggerhead.me/_images/comment_example.png)

###多行注释
先在导言区加入 ``\usepackage{verbatim}`` ，再像下图一样将注释放在 ``\begin{comment}`` 和 ``\end{comment}`` 之间就行了。

![multi-line comment example](https://loggerhead.me/_images/multi-line_comment_example.png)

因为一个换行等价于一个空格，所以上图多出来一个空格。如果不想要，这时候 ``%`` 就派上用场了。

![multi-line comment example](https://loggerhead.me/_images/multi-line_comment_notice_example.png)


#LaTeX 命令
##基本格式
LaTeX 命令的基本格式如下：

```latex
\command[optional]{paramter}
```

对有些命令来说，参数是必须的，放在 ``paramter`` 的位置。可选参数放在 ``optional`` 的位置。其中 ``\command`` 有三种形式：

- 由**对大小写敏感的字母**组成，任何**其他字符**表示结束。如：``\newline``
- 由 ``\`` 紧挨着一个**非字母字符**组成。如：``\\``
- ``\command*[optional]{paramter}`` ，表示命令的变种。如：``\section*{}``

``\command`` 后面的所有空白字符都将被忽略，除非加一对花括号 ``{}`` 。

![command example](https://loggerhead.me/_images/command_example.png)

值得注意的是，[LaTeX 命令并没有一致的作用域](http://tex.stackexchange.com/questions/6497/the-scope-of-latex-commands)。有些命令只影响它的参数，比如：``\emph{foo}``，而有些命令却影响整个段落，比如：``\noindent``。

##环境
环境是一种特殊的命令，它对包裹起来的内容起作用，其基本格式如下：

```latex
\begin{environment-name}
... text
\end{environment-name}
```

环境也能带参数，不过也没什么规律...比如：minipage、figure和picture环境能接受的参数就不尽相同。

```latex
\begin{minipage}[position]{width}
... text
\end{minipage}

\begin{figure}[placement]
  % body of the figure
  \caption{figure title}
\end{figure}

\begin{picture}(width,height)(x offset,y offset)
... picture commands
\end{picture}
```

##documentclass
所有的 LaTeX 文档都必须以 ``\documentclass[options]{class}`` 开头，指明文档类型。

|  class  |                                含义                                |
|---------|--------------------------------------------------------------------|
| article | 排版科学期刊、演示文档、短报告、程序文档、邀请函...                |
| proc    | 一个基于article的会议文集类                                        |
| minimal | 最小的文档类型。只设置了页面尺寸和基本字体。主要用来debug          |
| report  | 排版多章节长报告、短篇书籍、博士论文...                            |
| book    | 排版书籍                                                           |
| slides  | 排版幻灯片。该文档类使用大号sans serif字体。也可以考虑用Beamer类型 |

``options`` 定义文档的行为，多个 option 用英文逗号分隔。最常见的 option 见下表：

|                                options                                 |                                                                      作用                                                                      |
|------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| 10pt / 11pt / 12pt                                                     | 设置文档的主要字体。默认是10pt                                                                                                                 |
| a4paper / letterpaper/ a5paper / b5paper / executivepaper / legalpaper | 定义纸张的大小。默认是letterpaper。a4paper就是A4纸的大小                                                                                       |
| fleqn                                                                  | 设置行间公式为左对齐，而不是居中对齐                                                                                                           |
| leqno                                                                  | 设置行间公式的编号为左对齐，而不是右对齐                                                                                                       |
| titlepage / notitlepage                                                | 指定是否在文档标题后另起一页。article默认不开始新页，report和book则相反                                                                        |
| onecolumn / twocolumn                                                  | 以单栏或双栏的方式来排版文档                                                                                                                   |
| twoside / oneside                                                      | 指定文档为双面或单面打印格式。article和report为单面，book为双面。注意：该选项只是作用于文档样式，而不会通知打印机以双面格式打印文档            |
| landscape                                                              | 将文档的打印输出布局设置为landscape模式                                                                                                        |
| openright / openany                                                    | 指定新的一章仅在奇数页开始还是在下一页开始。该选项对article不起作用，因为article没有“章”。report默认在下一页开始新一章，而book总是在奇数页开始 |

比如：

```latex
\documentclass[11pt,twoside,a4paper]{article}
```

它告诉 LaTeX 以 article 的形式排版文章，设置基本的字体大小为 11pt，布局为适合在 A4 纸上双面打印的形式。

##usepackage
宏包的概念类似于编程语言里边库的概念，如果想包含图片、代码、彩色文字、流程图等等，你都得使用宏包。使用宏包的命令是：

```latex
\usepackage[options]{package}
```

``options`` 与 ``\documentclass`` 的 ``options`` 相似，用于指定宏包的一些特性。

如果想了解某个宏包怎么使用，有哪些参数。你可以在终端输入 ``texdoc`` 查看宏包的文档。也可以通过查看 [The LATEX Companion](http://book.douban.com/subject/1418356/) 来获取需要的信息。

###安装宏包
####自动安装
#####MacTeX
如果你安装了 MacTeX，那么使用 `TeX Live Utility.app` 可以十分方便的安装、更新宏包。

#####TeX Live 或 MacTeX
如果你使用 TeX Live 或 MacTeX，那么你可以使用 tlmgr 方便的安装宏包。

```bash
tlmgr install <package1> <package2> ...
tlmgr remove <package1> <package2> ...
```

####手动安装
**十分麻烦，不建议使用！**如果你手动安装失败了，一般是第4步弄错了。

1. 在 [ctan](http://ctan.org/) 搜索需要的宏包，并下载。
    
    ![download_package_from_ctan](https://loggerhead.me/_images/download_package_from_ctan.png)

2. 解压。通常会得到 .ins 文件、.dtx 文件、INSTALL 和 README。如果不存在 .ins 文件，请查看 INSTALL 和 README。
3. 将 .ins 文件视作普通 LaTeX 文档打开编译 ，LaTeX 会从 .dtx 文件中抽取出 .sty 文件。如果是通过命令行编译，那么命令是：
    
    ```bash
    xelatex -shell-escape xxx.ins
    ```

4. 将 .sty 文件放到 LaTeX 发行版能找到的目录下，通常路径含 ``texmf-local`` 或 ``texmf``（"Tex and MetaFont" 的缩写，指代 Latex 发行版的目录树）。
    
    | 发行版 |                                目录                               |                                              说明                                             |
    |--------|-------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
    | MacTeX | [~/Library/texmf/tex/latex](https://www.tug.org/mactex/faq/#qm05) | 使用 ``mkdir -p`` 自行创建                                                                    |
    | MiKTEX | 任意目录                                                          | 得先[注册为用户管理的 texmf 目录](http://docs.miktex.org/manual/localadditions.html#id573803) |

5. 更新 LaTeX 文件名数据库。

    |     发行版     |            命令            |
    |----------------|----------------------------|
    | TEXlive/MacTeX | ``texhash``                |
    | MiKTEX         | ``initexmf --update-fndb`` |


#如何进一步学习 LaTeX


- 如果遇到问题，上 [StackExchange](http://tex.stackexchange.com/) 搜索，几乎你能遇到的问题都能在上面找到答案。
- [LaTeX - Wikibooks](https://en.wikibooks.org/wiki/LaTeX) 和 [ShareLaTeX guides](https://www.sharelatex.com/learn) 都是在线文档，内容详细，示例很多。
- [The Not So Short Introduction to LaTeX](https://tobi.oetiker.ch/lshort/lshort.pdf) 又叫做 LATEX2ε in 157 minutes，是一本很不错的入门书，内容简短精炼。
- [TeXbook](http://book.douban.com/subject/1418351/) 是 TeX 语言的作者 Knuth 亲自写的介绍 TeX 基本概念的一本书。

------

####参考文献
- [The Not So Short Introduction to LaTeX](https://tobi.oetiker.ch/lshort/lshort.pdf)
- [ShareLaTeX guides](https://www.sharelatex.com/learn)
- [LaTeX - Wikibooks](https://en.wikibooks.org/wiki/LaTeX)
- [xeCJK](http://mirror.utexas.edu/ctan/macros/xetex/latex/xecjk/xeCJK.pdf)
- [The Preamble of the LaTeX Input file](http://www.maths.tcd.ie/~dwilkins/LaTeXPrimer/Preamble.html)
- [汉字中的“斜体”](http://pyroc.at/blog/2013/04/03/cjk-italics/)
