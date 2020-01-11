title: LaTeX 在 Mac 下的中文环境配置
date: 2015-04-07 22:51
tags: LaTeX, Mac

* 本文的目标是让需要对**中文**论文进行排版的 **OS X** 用户安装配置好中文环境，编译示例得到 foo.pdf。
* 如果只需排版英文，那么中文配置部分可以跳过。
* 如果是 Linux/Unix 或 Windows 用户，将 Skim 换成相应的 pdf阅读器（LaTeXing 默认设置中有提及）后，LaTeXing 部分仍适用，但 MacTeX 部分不再适用。

<!--- SUMMARY_END -->

#安装
MacTeX 是必备的。Skim 和 [LaTeXing](http://www.latexing.com/features.html) 虽说不是必须的，但是强烈推荐安装。后文会介绍它们的作用，先将它们安装好：

* [下载 MacTeX.pkg](http://mirror.ctan.org/systems/mac/mactex/MacTeX.pkg)
* 使用 [Package Control](https://packagecontrol.io/) 安装 LaTeXing 和 LaTeX-cwl，并重启 Sublime
* [下载 Skim](http://skim-app.sourceforge.net/)。LaTeXing 需要与它（或者 _预览_）配合实现跳转到 pdf。

在下载 MacTeX 的这段时间，我们可以先了解一下 LaTeXing。

##LaTeXing
LaTeXing 是 [Sublime](https://www.sublimetext.com/3) 的 LaTeX 插件，与之类似的还有 [LaTeXTools](https://packagecontrol.io/packages/LaTeXTools)。两者功能类似，只不过 LaTeXing 更容易配置和使用，而且某些功能更加出色。它的特点包括：

* LaTeX 命令自动补全

    ![auto complete](https://loggerhead.me/_images/latexing_autocomplete_1.png)

* 丰富的 snippet

    ![snippet](https://loggerhead.me/_images/snippet.png)

* 填充引用、宏包、文档类型等任何东西

    ![fill everything](https://loggerhead.me/_images/fill_everything.png)
    ![fill cite](https://loggerhead.me/_images/latexing_fill_cite.png)

* 快捷键跳转到生成的 pdf

    ![pdf result](https://loggerhead.me/_images/pdf_result.png)

* 可读性更高的出错提示

    ![error](https://loggerhead.me/_images/error.png)

注意：

* 自动补全功能需要安装 LaTeXing 的插件——[LaTeX-cwl](https://packagecontrol.io/packages/LaTeX-cwl)
* 跳转 pdf 需要照下图设置 Skim

    ![skim config](https://loggerhead.me/_images/skim_config.png)

* 双击出错信息可以跳转到出错行

#中文配置
##安装中文字体
[下载 STXihei、STSong、STKaiti、STHeiti、STFangsong](https://coding.net/u/loggerhead/p/fonts/git/archive/master)，双击它们，系统会调用字体册（Font Book）打开它们，点击安装即可。

##配置 MacTeX
在终端输入

```bash
sudo vim `mdfind ctex-xecjk-winfonts.def | egrep "texlive/\d{4}/texmf-dist/tex/latex/ctex/fontset/ctex-xecjk-winfonts.def"`
```

将 _ctex-xecjk-winfonts.def_ 文件修改成：

```latex
% ctex-xecjk-winfonts.def: Windows 的 xeCJK 字体设置，默认为六种中易字体
\setCJKmainfont[BoldFont={STHeiti},ItalicFont=STKaiti]{STSong}
\setCJKsansfont{STHeiti}
\setCJKmonofont{STFangsong}

\setCJKfamilyfont{zhsong}{STSong}
\setCJKfamilyfont{zhhei}{STHeiti}
\setCJKfamilyfont{zhkai}{STKaiti}
\setCJKfamilyfont{zhfs}{STFangsong}
\setCJKfamilyfont{zhli}{LiSu}
\setCJKfamilyfont{zhyou}{YouYuan}

\newcommand*{\songti}{\CJKfamily{zhsong}} % 宋体
\newcommand*{\heiti}{\CJKfamily{zhhei}}   % 黑体
\newcommand*{\kaishu}{\CJKfamily{zhkai}}  % 楷书
\newcommand*{\fangsong}{\CJKfamily{zhfs}} % 仿宋
\newcommand*{\lishu}{\CJKfamily{zhli}}    % 隶书
\newcommand*{\youyuan}{\CJKfamily{zhyou}} % 幼圆

\endinput
```

##配置 LaTeXing
点击

```
Sublime Text => Preferences => Package Settings => LaTeXing => Settings - User
```

打开 LaTeXing.sublime-settings，填入以下内容：

```js
{
    "debug": false,
    "fallback_encoding": "utf_8",
    // 打开.tex的同时打开.pdf文件
    "open_pdf_on_load": false,
    // 某些宏包需要这个参数，如：minted
    "build_arguments": ["-shell-escape"],
    // 使用xelatex而不是pdflatex进行编译
    "quick_build": [
        {
            "name": "Default Build: latexmk",
            "primary": true,
            "cmds": ["xelatex"]
        },
        {
            "name": "Quick Build 1: xelatex + bibtex + xelatex (2x)",
            "cmds": ["xelatex", "bibtex", "xelatex", "xelatex"]
        },
        {
            "name": "Quick Build 2: xelatex + biber + xelatex (2x)",
            "cmds": ["xelatex", "biber", "xelatex", "xelatex"]
        }
    ],
}
```


##测试
用 Sublime 创建 foo.tex，输入以下内容并保存：

```latex
\documentclass{minimal}
\usepackage{xeCJK}
\setCJKmainfont[BoldFont=STHeiti,ItalicFont=STKaiti]{STSong}
\setCJKsansfont[BoldFont=STHeiti]{STXihei}
\setCJKmonofont{STFangsong}
\begin{document}
你好，世界
\end{document}
```

按 ``Cmd+B`` 进行编译（3083以上版本的 sublime 在弹出框中选择 ``LaTeX - Primary Quick Build`` 作为默认编译方式），如果配置成功，控制台的输出应该是这样

![compile result](https://loggerhead.me/_images/compile_result.png)

按 ``Cmd+L Cmd+J`` 跳转到生成的 foo.pdf（红点是 .tex 文件改动的地方）。

![pdf result](https://loggerhead.me/_images/pdf_result.png)

如果没能成功编译出 foo.pdf，那么问题很可能是：

* 没有安装相应的中文字体
* foo.tex 的文件编码不是 UTF-8。如果你不能确定文件编码，点击 _File => Save with Encoding => UTF-8_ 
* LaTeXing 使用 pdflatex 而不是 xelatex 进行编译

为了确定问题的所在，我们在终端输入命令 ``xelatex foo.tex``。

1. 如果能生成 foo.pdf，那么是 LaTeXing 没有配置正确。
2. 如果 xelatex 输出一堆错误信息，那么是中文字体没有安装或配置成功。
3. 如果提示 xelatex 命令不存在，输入： 

    ```bash
    sudo ln -s /Library/TeX/Distributions/Programs/texbin/xelatex /usr/xelatex
    ```

    重启终端，重新输入 ``xelatex foo.tex``

#FAQ
##TeX 与 LaTeX
TeX 不仅是一个排版程序，而且是一种程序语言。LaTeX 就是用这种语言写成的一个"TeX 宏包"，它扩展了 TeX 的功能，使我们很方便的逻辑的进行创作而不是专心于字体，缩进这些烦人的东西。类似 C++ 与 MFC、Ruby 与 Ruby on Rails 的关系。

##LaTeX 与 LaTeX2e
LaTeX2 $\varepsilon$ 是 LaTeX 目前的版本。以前的 LaTeX 叫做 LaTeX 2.09。现在随便下载一个 TeX 系统，里面带的 LaTeX 都是 LaTeX2 $\varepsilon$。

##MacTeX 与 MikTeX
不同的 TeX 发行版本而已，比如 OS X 下有 MacTeX，Windows 下有 MikTeX，Linux/UNIX 下有 teTeX 和 TeX Live。TeX 与它们的关系就像 Linux 内核与 Debian、Redhat、Arch 的关系一样。所以每个 TeX 发行版里都包含了 TeX，LaTeX 等等。

##LaTeX 与 CJK、xeCJK
CJK、xeCJK 都是 LaTeX 的宏包，MacTeX.pkg 里面已经包含了它们，不必再自行安装。
