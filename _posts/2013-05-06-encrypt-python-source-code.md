---
layout: post
title: encrypt python source code
category: python
tags: [python]
---

{% include JB/setup %}

###需求：加密python代码

最近有个需求，是要对我们的openstack代码进行加密，前期我已经使用[pycompile](http://docs.python.org/2/library/py_compile.html)将py代码编译成pyc，并且删除了py源文件。不过众所周知的原因，pyc所适用的业务场景并不是加密，所以我们将py文件编译成pyc文件的方式也只是自娱自乐，pyc还是可以轻易反编译成py文件，见[decompile python2.7 pyc](http://stackoverflow.com/questions/8189352/decompile-python-2-7-pyc)。

程序员在无奈的时候只有一个地方可去，let's go stackoverflow.com, search keywords: python encrypt. 我们查询到这篇问答：

#### How do I protect python code?

question:
>I am developing a piece of software in python that will be distributed to my employer's customers. My employer wants to limit the usage of the software with a time restricted license file. <br />
>If we distribute the .py files or even .pyc files it will be easy to (decompile), and remove the code that checks the license file. <br />
>Another aspect is that my employer does not want the code to be read by our customers, fearing that the code may be stolen or at least the "novel ideas". <br />
>Is there a good way to handle this problem? Preferably with an off-the-shelf solution. <br />
>The software will run on Linux systems (so I don't think py2exe will do the trick)

answer:
>Python, being a byte-code-compiled interpreted language, is very difficult to lock down. Even if you use a exe-packager like py2exe, the layout of the executable is well-known, and the Python byte-codes are well understood. <br />
>Usually in cases like this, you have to make a tradeoff. How important is it really to protect the code? Are there real secrets in there (such as a key for symmetric encryption of bank transfers), or are you just being paranoid? Choose the language that lets you develop the best product quickest, and be realistic about how valuable your novel ideas are. <br />
>If you decide you really need to enforce the license check securely, write it as a small C extension so that the license check code can be extra-hard (but not impossible!) to reverse engineer, and leave the bulk of your code in Python. <br />

通过这个问题我们可以得出，对于python代码的加密并没有一个太好的方法，而且一个脚本语言和一个开源项目做加密更是和开源社区的精神背道而驰。

不过通过大家的回复我们也看到，如果我们的python代码包含核心业务，应该需要把核心业务抽取出来，通过c extension的方式实现，对于c 语言的加密和混淆也是有成熟方案供选择的，这个我们后续再继续研究，不过我可能不会在openstack项目试用这个方法了，原因你懂的。

关于py2exe，有个回复是：py2exe just stores the .pyc byte code files in a .zip archive, so this is definitely not a solution. Still, that can be useful when combined with a suitable starup script to make it run out Linux。 py2exe打包了pyc文件，这个以前还没注意到。

这个问题中还有一个回复也是值得我们好好思考的，引用如下：
>Python is not the tool you need <br/>
>You must use the right tool to do the right thing, and Python was not designed to be obfuscated. 
>It's the contrary; everything is open or easy to reveal or modify in Python because that's the language's philosophy.
>If you want something you can't see through, look for another tool. This is not a bad thing,
>it is important that several different tools exist for different usages.

>Obfuscation is really hard <br />
>Even compiled programs can be reverse-engineered so don't think that you can fully protect any code.
>You can analyze obfuscated PHP, break the flash encryption key, etc. Newer versions of Windows are cracked every time.

>Having a legal requirement is a good way to go <br />
>You cannot prevent somebody from misusing your code, but you can easily discover if someone does. Therefore, it's just a casual legal issue.

>Code protection is overrated <br />
>Nowadays, business models tend to go for selling services instead of products. You cannot copy a service, pirate nor steal it. Maybe it's time to consider to go with the flow...

怎么样，现在你对代码加密有了新的认识吗？

---
\[参考\] <br />
\[1\][pycompile](http://docs.python.org/2/library/py_compile.html) <br />
\[2\][decompile](http://stackoverflow.com/questions/8189352/decompile-python-2-7-pyc) <br />
\[3\][py2exe](http://py2exe.org/) <br />
\[4\][how-do-i-protect-python-code](http://stackoverflow.com/questions/261638/how-do-i-protect-python-code)
