title: 给 GitHub 项目戴上勋章  
date: 2016-03-27 10:20:12  
tags: GitHub, non-tech

如果你常常使用 GitHub，稍微留心就会发现，不少项目都有勋章（badges），那这些勋章有什么用呢？要怎么给自己的项目也「戴上」勋章呢？

<!--- SUMMARY_END -->

|       Travis      |      Coveralls       |        PyPI       |   License    |
|-------------------|----------------------|-------------------|--------------|
| ![Travis badge][] | ![Coveralls badge][] | ![PyPI Version][] | ![License][] |

[Travis badge]: https://img.shields.io/travis/loggerhead/Easy-Karabiner.svg
[Landscape badge]: https://landscape.io/github/loggerhead/Easy-Karabiner/master/landscape.svg
[Coveralls badge]: https://img.shields.io/coveralls/loggerhead/Easy-Karabiner.svg
[PyPI Version]: https://img.shields.io/pypi/v/easy_karabiner.svg
[License]: https://img.shields.io/badge/license-MIT-blue.svg

#勋章的作用
在继续介绍勋章之前，我们先了解什么是持续集成。

##持续集成
有经验的开发者往往对自己写的代码有很强的「信心」，这种「信心」来自于丰富的经验，丰富到对代码的任何一点改动，都能被他们的「大局观」给捕捉到。但是随着代码规模增加，无论开发者的经验如何丰富，也很难继续「掌控」全局。因为开发者对项目其他部分可能一无所知，不知道其他开发者提供的接口是不是足够健壮，不知道对某个文件的修改会不会影响其他函数的调用，所有的这些未知都会让开发者逐渐丧失「信心」。

众所周知，给项目加上充足的测试通常能很好的解决上述问题。不过保持多高的测试频率才适当呢？应当每完成一个模块测试一次，或者每完成一个函数测试一次？一个自然而然的想法是，测试频率越高越好，不过如果项目迭代速度很快，每次都手动测试，等待测试结果出来再继续开发，这个过程就有点繁琐了。因此，有人提出了持续集成[^continuous-integration]的概念。持续集成的核心想法是：如果有代码更新，运行自动化测试，并给出测试结果。持续集成的直接好处就是：如果有 bug，很快就能发现，并能定位到提交者（commiter），那么 bug 就能在更短的周期内被修复。

如果我们在 GitHub 上的开源项目也能做到持续集成，那么项目的质量就有所保证。也因此，无论是开发者，还是使用者都会对项目更加有信心。那么持续集成的结果怎么表达给项目的使用者呢，总不能叫他们去看冗长的分析结果吧？答案就是—勋章。

[^continuous-integration]: 关于持续集成更详细的介绍可以看看这篇博客：[持续集成是什么？](http://www.ruanyifeng.com/blog/2015/09/continuous-integration.html)

##持续集成服务
###Travis CI ![Travis badge][]
[Travis CI][] 是一个免费为开源项目提供持续集成的网站。在与 GitHub 的账号关联以后，只需按一个按钮，写好 `.travis.yml`，就能让它对每一个 commit 或 pull request 按照 `.travis.yml` 中的规则执行脚本。

[Travis CI]: https://travis-ci.org/

它实现的功能看似简单，但却十分强大，前面提到的自动化测试就是通过它实现的。以 [Easy-Karabiner](https://github.com/loggerhead/Easy-Karabiner) 的 `.travis.yml` 为例：

```yaml
language: python
python:
  - "2.7"
  - "3.3"
  - "3.4"
  - "3.5"
install:
  - pip install coveralls
  - pip install lxml click
cache:
  directories:
    - $HOME/.cache/pip
script:
  - python setup.py install
  - nosetests --with-coverage --cover-package=easy_karabiner
after_success:
  - coveralls
```

上面的规则告诉 Travis CI 在四种 Python 环境下分别进行相同的操作：

1. 安装依赖：`pip install`
2. 安装项目：`python setup.py install`
3. 执行测试：`nosetests`
4. 上传测试结果到 Coveralls：`coveralls`

只有所有的操作都执行成功，它才会 passing 。

###Coveralls ![Coveralls badge][]
[Coveralls](https://coveralls.io/) 是一个提供测试覆盖率分析的网站，它能告诉你每个文件的测试覆盖率是多少，甚至代码中哪些行没有被测试用例覆盖到也能在报告中看到。更棒的是，对开源项目永久免费！

![coveralls-example-file.png](https://loggerhead.me/_images/coveralls-example-file.png)
![coveralls-example-detail.png](https://loggerhead.me/_images/coveralls-example-detail.png)

Coveralls 的使用和 Travis CI 略有不同，其步骤如下（详见 Travis CI 中的示例）：

1. 与 GitHub 帐号关联，Turn on 需要分析的 repo
2. 在 Travis CI 中执行测试，并生成 Coveralls 支持的测试报告
3. 执行 `coveralls` 命令上传测试报告

目前 Coveralls 支持的语言和服务如下：

* 语言：Ruby、Python、PHP、Node.js、C/C++、Scala
* CI 服务：Travis CI、Travis Pro、CircleCI、Jenkins、Semaphore、Codeship

如果开发语言是 Python，个人推荐下面这套 Combo：

* [Travis CI][]
* [nosetests](https://nose.readthedocs.org/en/latest/)
* [coveralls-python](https://github.com/coagulant/coveralls-python)

###Landscape ![Landscape badge][]
[Landscape](https://landscape.io/) 是**提供 Python 代码质量分析**的网站，它能帮助你发现代码中的错误或「坏味道」，比如：

![landscape-example-warning.png](https://loggerhead.me/_images/landscape-example-warning.png)
![landscape-example-error.png](https://loggerhead.me/_images/landscape-example-error.png)

同样，它也能给出每个文件的「健康情况」：

![landscape-example-score.png](https://loggerhead.me/_images/landscape-example-score.png)

Landscape 默认使用 [pylint](https://github.com/PyCQA/pylint) 进行分析，也可以创建 `.landscape.yml` 文件，并在里面配置使用其他工具或者 disable 一些检查，比如：

```yaml
pylint:
    disable:
        - unused-argument
        - redefined-builtin
        - arguments-differ
```

#获取勋章
上述持续集成服务自身就有提供勋章，拿 [loggerhead/Easy-Karabiner](https://github.com/loggerhead/Easy-Karabiner) 为例，这些勋章的链接分别是：

* <https://travis-ci.org/loggerhead/Easy-Karabiner.svg>
* <https://coveralls.io/repos/github/loggerhead/Easy-Karabiner/badge.svg>
* <https://landscape.io/github/loggerhead/Easy-Karabiner/master/landscape.svg>

如果想添加其他勋章，可以在 http://shields.io/ 找找看，它提供了很多种类的勋章，比如：

* GitHub: ![Stars badge][] ![Forks badge][] ![Issues badge][]
* PyPI[^How-to-submit-a-package-to-PyPI]: ![PyPI download badge][] ![PyPI version badge][] ![PyPI pyversions badge][]

[Stars badge]: https://img.shields.io/github/stars/django/django.svg
[Forks badge]: https://img.shields.io/github/forks/django/django.svg
[Issues badge]: https://img.shields.io/github/issues/django/django.svg
[PyPI download badge]: https://img.shields.io/pypi/dm/Django.svg
[PyPI version badge]: https://img.shields.io/pypi/v/Django.svg
[PyPI pyversions badge]: https://img.shields.io/pypi/pyversions/Django.svg

不过 [Shields.io](http://shields.io/) 只给出了勋章的示例链接，具体的格式还得靠自己观察……比如：

* <https://img.shields.io/pypi/dm/Django.svg> 的格式是 `https://img.shields.io/pypi/dm/{{PACKAGE_NAME}}.svg`，其中 `dm` 是 `download per month` 的意思。
* <https://img.shields.io/github/stars/badges/shields.svg> 的格式是 `https://img.shields.io/github/stars/{{USER_NAME}}/{{REPO_NAME}}.svg`

[^How-to-submit-a-package-to-PyPI]: PyPI 是 Python Package Index 的缩写，通过 `pip install` 命令下载的包都必须先上传到这里，具体的操作过程参见博客：[How to submit a package to PyPI](http://peterdowns.com/posts/first-time-with-pypi.html)
