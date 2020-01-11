title: 快速回忆你用过的 Git
date: 2015-07-02 15:22:38
tags: 工具

本文所介绍的内容大部分是 [Pro Git 2nd Edition](https://git-scm.com/doc) 第二、三章中出现的常用命令，如果你有时间，建议将此书看一遍。

<!--- SUMMARY_END -->

[TOC]

#基本原理
Git 管理项目时，文件在三个区域转移：工作区，暂存区，以及本地仓库。

![git areas](https://loggerhead.me/_images/git-areas.png)

简单的说，工作区就是 `.git` 所在目录，暂存区就是 `.git/index` 文件，本地仓库就是 `.git` 目录。实际上，暂存区是一个包含文件索引的目录树，记录了文件的各种信息（文件名、文件长度、修改时间等），而文件内容则存放在 `.git/objects` 目录下。

![git stage](https://loggerhead.me/_images/git-stage.png)

Git 将 commit、文件、目录统统视为对象。对象以 `SHA1` 值作为指纹，与其他对象相区分，Git 命令操作的最小单位是对象。
Git 会将文件的副本存放在 .git 文件夹下，每个文件都根据文件内容进行操作。

![git objects](https://loggerhead.me/_images/git-commit-and-tree.png)

由 Git 管理的文件始终在四种状态之间迁移，分别是：未跟踪（Untracked）、未修改（Unmodified）、已修改（Modified）或已暂存（Staged）。

![git file lifecycle](https://loggerhead.me/_images/git-lifecycle.png)

HEAD、分支（branch）、标签（tag）都是指针，均直接或间接指向相应的 commit。HEAD 始终指向当前分支，分支和标签指向对应的 commit。通过 `git cat-file -p <SHA1>` 可查看 commit 内容。

```shell
$ cat .git/HEAD
ref: refs/heads/master
$ cat refs/heads/master
44181f5600579209649bf30c2dbe9227c68a3a58
$ cat refs/tags/v0.1
0d84e16dc2e19a309865202a4d2d2e267c1f315e
$ git cat-file -p 0d84e16dc2e19a309865202a4d2d2e267c1f315e
tree 7b2366b4fb6aa745d1ad542be660cab47ca6247e
parent 0acf7329fb3dec0a4f4eef2ae0d6c0e376435300
author loggerhead <lloggerhead@gmail.com> 1434017010 +0800
committer loggerhead <lloggerhead@gmail.com> 1434017010 +0800

add ldconfig explain
```

![branch, tag and history](https://loggerhead.me/_images/git-branch-and-history.png)

#.gitignore 文件
.gitignore 文件包含一些模式，用以描述不想跟踪的文件。

##模式规则
* 忽略空行 或 `#` 开头的行
* 标准 glob 模式
* `/` 开头避免递归
* `/` 结尾表示目录
* `!` 开头表示反转该模式.

###Glob 模式
* `*` 匹配大于等于0个字符
* `[abc]` 匹配括号中的任意一个字符
* `?` 匹配1个字符
* `**` 匹配目录，如：`a/**/z` 会匹配 `a/z`、`a/b/z`、`a/b/c/z` 等等

```shell
# 忽略所有的 .a 文件
*.a
# 不忽略 lib.a 文件, 即使上一条规则说了要忽略
!lib.a
# 仅仅忽略当前目录下的 TODO 文件
/TODO
# 忽略所有 build/ 目录下的文件
build/
# 忽略 doc/notes.txt, 但是不忽略 doc/server/arch.txt
doc/*.txt
# 忽略所有位于 doc/ 目录下的 .txt 文件
doc/**/*.txt
```

#查看信息
##列出帮助信息 -- `git help <command>`

##列出文件状态 -- `git status`
列出处于未跟踪、已修改或已暂存状态的文件。

```shell
git status
git status -s
git status --short
```

###`git status -s` 示例
输出分四栏，第一栏表示文件已暂存，第二栏表示文件已修改，第三栏是空格，第四栏是文件路径。

```shell
# git status -s
 M README               # 已修改但未暂存
MM Rakefile             # 已修改且已暂存，然后又被修改了
A  lib/git.rb           # 新文件
M  lib/simplegit.rb     # 已修改且已暂存
?? LICENSE.txt          # 未跟踪
```

##查看提交历史 -- `git log`
* `git log -p`: 查看提交历史和每次提交的详细修改
* `git log -<n>`: 查看最近 n 次提交历史
* `git log --stat`: 查看提交历史和每次提交的修改情况
* `git log --since=1.weeks`: 查看最近一星期的提交历史
* `git log --until=1.weeks`: 查看到上星期为止的提交历史
* `git log --grep=hel.o`: 查看提交信息匹配 `hel.o` 的提交历史
* `git log --author=f.o`: 查看作者名匹配 `f.o` 的提交历史
* `git log -S<string>`: 查看改动过 `<string>` 的提交历史

```shell
git log --oneline --decorate --color --graph
git log -Sfunction_name
```

##查看详细修改 -- `git diff`
查看已修改文件的详细修改。

* `git diff --staged`: 查看已暂存文件和最后一次提交（commit）相比的详细修改（`cached` 是 `staged` 的同义词）

#本地仓库
##创建仓库 -- `git init [directory]`
创建仓库或重置已有仓库。

```shell
git init
git init .
```

##跟踪文件 -- `git add [<pathspec>...]`
跟踪（track）新文件。

```shell
git add .
```

##删除文件 -- `git rm <file>...`
删除已跟踪且已提交的文件，并从工作区删除。

* `git rm -f <file>`: 删除已跟踪的文件，并从工作区删除
* `git rm --cached <file>`: 删除已跟踪的文件，但不从工作区删除

`git rm` 命令接受 glob 模式的参数，只不过 `*` 之前需要一个 `\`，因为 Git 内部会对 `*` 作处理，而没有 `\` 的话，shell 会先将 `*` 展开例如：

```shell
git rm --cached \*\*/\*.log
```

##重命名文件 -- `git mv <source> <destination>`
```shell
git mv README.md README
# 等价于下面三个命令
mv README.md README
git rm README.md
git add README
```

#状态变动
##暂存文件 -- `git stage <pathspec>...`
暂存（stage）修改的文件，与 `add` 是同义词。

* `git stage  .`: 暂存已修改的文件和新文件，不暂存删除变动
* `git stage -u`: 暂存已修改的文件和删除变动，不暂存新文件
* `git stage -A`: 暂存所有文件

##取消暂存 -- `git reset`
* `git reset HEAD <file>...`: 取消暂存（unstage）
* `git reset --hard <file>...`: 丢弃对应文件未提交的修改（**所有修改都会消失，慎用**）
* `git reset --hard HEAD`: 丢弃所有未提交的修改（**所有修改都会消失，慎用**）

##提交修改 -- `git commit`
* `git commit -a`: 暂存所有已跟踪的文件，并提交修改
* `git commit -m <msg>`: 提交修改，并将 `msg` 作为提交信息
* `git commit -v`: 提交修改，并将 `diff` 结果附在提交信息中
* `git commit --amend`: 重新提交修改

```shell
# 暂存并提交
git commit -a -m 'added new benchmarks'
# 暂存漏掉的文件，重新提交
git commit -m 'initial commit'
git add forgotten_file
git commit --amend
```

#远程仓库
##克隆远程仓库 -- `git clone <repository> [<directory>]`
克隆远程仓库并重命名为 `<directory>`。

```shell
git clone https://github.com/libgit2/libgit2
git clone https://github.com/libgit2/libgit2 libgit2
```

##添加、删除、列出远程仓库 -- `git remote`
* `git remote -v`: 显示远程仓库名和对应的 URL
* `git remote show <name>`: 显示远程仓库的详细信息
* `git remote add <name> <url>`: 添加 `<name>` 作为位于 `<url>` 的远程仓库
* `git remote rename <old> <new>`: 重命名远程仓库和远程仓库本地名
* `git remote rm <name>`: 删除远程仓库

```shell
# git remote -v
origin  https://github.com/schacon/ticgit (fetch)
origin  https://github.com/schacon/ticgit (push)
# git remote add <name> <url>
git remote add pb https://github.com/paulboone/ticgit
```

##列出远程仓库的所有引用 -- `git ls-remote [<url>]`
列出远程仓库的所有引用（remote references），包括分支、标签等。

```shell
# git ls-remote
From git@github.com:loggerhead/lhttpd.git
bc5f82b661d5fec273e66a765d23a761b74c6a54    HEAD
22f3f0ec3b612c368b3a8b9aa15012e91e48c4f6    refs/heads/dev
bc5f82b661d5fec273e66a765d23a761b74c6a54    refs/heads/master
0d84e16dc2e19a309865202a4d2d2e267c1f315e    refs/tags/v0.1
22f3f0ec3b612c368b3a8b9aa15012e91e48c4f6    refs/tags/v0.2

# git ls-remote https://github.com/loggerhead/lhttpd.git
bc5f82b661d5fec273e66a765d23a761b74c6a54    HEAD
22f3f0ec3b612c368b3a8b9aa15012e91e48c4f6    refs/heads/dev
bc5f82b661d5fec273e66a765d23a761b74c6a54    refs/heads/master
0d84e16dc2e19a309865202a4d2d2e267c1f315e    refs/tags/v0.1
22f3f0ec3b612c368b3a8b9aa15012e91e48c4f6    refs/tags/v0.2
```

##更新远程仓库 -- `git push`
* `git push origin --tags`: 更新远程仓库的标签
* `git push <remote> <branch>`: 更新 `<branch>` 分支到远程仓库
* `git push <remote> --delete <remote_branch>`: 删除远程仓库上的 `<remote_branch>` 分支

##下载并合并远程仓库的数据 -- `git pull`
下载远程仓库的数据，并进行合并。

```shell
# 大部分情况等价于 `git fetch && git merge`
git pull
```

##下载远程仓库的数据 -- `git fetch [<remote>]`
```shell
git fetch origin
```

##用远程仓库覆盖本地分支
```shell
git fetch --all
git reset --hard origin/YOUR_BRANCH
# 覆盖所有分支
# git reset --hard origin
```

##子模块操作 -- `git submodule`
* `git submodule add <repository>`: 添加子模块
* `git submodule init`: 初始化子模块
* `git submodule update`: 更新子模块

```shell
# 为项目添加子模块
git submodule add https://github.com/chaconinc/DbConnector

# 下载项目的子模块
git clone https://github.com/chaconinc/MainProject
cd MainProject
cd DbConnector
# 初始化本地配置
git submodule init
# 下载子模块数据并 checkout
git submodule update

# clone 并下载所有子模块
git clone --recursive https://github.com/chaconinc/MainProject
```

#分支操作
##创建、删除、列出分支 -- `git branch`
* `git branch <branchname>`: 创建分支
* `git branch -d <branchname>`: 删除分支，分支必须已经被合并到其他分支
* `git branch -D <branchname>`: 强制删除分支
* `git branch`: 列出所有分支
* `git branch -v`: 列出所有分支和最后一次提交
* `git branch --merged`: 列出被合并到当前分支的其他分支
* `git branch --no-merged`: 列出未合并到当前分支的其他分支
* `git branch -u <remote>/<branch>`: 设置当前分支与远程分支 `<remote>/<branch>` 同步（track upstream branch）
* `git branch -vv`: 列出本地分支与远程分支的关系

```shell
# git branch -vv
  iss53     7e424c3 [origin/iss53: ahead 2] forgot something          # 本地分支比远程分支多2次提交
  master    1ae2a45 [origin/master] deploying index fix
* serverfix f8674d9 [teamone/server-fix-good: ahead 3, behind 1] fix  # 当前分支。与远程分支有4次提交未同步
  testing   5ea463a trying something new                              # 没有设置同步的远程分支
```

##切换分支 -- `git checkout`
* `git checkout <branch>`: 切换到分支
* `git checkout -b <new_branch> [<start_point>]`: 创建分支，然后切换到该分支
* `git checkout -- <file>...`: 还原到最后提交的版本/丢弃修改。**WARNING: 文件的任何修改都会丢失**

```shell
# 将 HEAD 指针指向 testing 分支
git checkout testing
# 等价于 `git branch testing && git checkout testing`
git checkout -b testing
# 基于远程仓库 origin 的 master 分支创建分支 testing，并切换到 testing
git checkout -b testing origin/master
```

##创建、删除、列出标签 -- `git tag`
* `git tag`: 按字母序列出所有标签
* `git tag -l <pattern>`: 列出匹配的标签
* `git tag -a <tagname> -m <msg>`: 创建带注释的标签
* `git tag <tagname> [<commit>]`: 对 `<commit>` 创建标签
* `git tag -d <tagname>`: 删除标签
