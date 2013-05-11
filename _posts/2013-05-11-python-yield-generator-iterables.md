---
layout: post
title: yield, generator and iterable in python
category: python
tags: [python]
---

{% include JB/setup %}

一直想对python里的关键字[yield](http://docs.python.org/2/reference/expressions.html#grammar-token-yield_atom)仔细了解一下。
今天终于沉得住气静的下心写个demo体会一下如何使用这个比较古怪的feature。

>`iter_a = [x*x for x in range(5)]` <br />
>`iter_b = (x*x for x in range(5))` <br />
>a&b 有什么区别? <br />
>type(iter_a) is list <br />
>type(iter_b) is &lt;generator object &lt;genexpr&gt; at 0x00000000&gt; <br />

### yield expressions
The yield expression is only used when defining a **generator** function, and can only be used **in the body of a function definition**.
Using a yield expression in a function definition is sufficient to cause that definition to create a generator function instead of a normal function.

### generator
Generators are a simple and powerful tool for creating **iterators**. They are written like regular functions but use the yield statement whenever they want to return data. Each time next() is called, the generator resumes where it left-off (it remembers all the data values and which statement was last executed). <br />
Gernerators are iterators, but **your can only iterate over them once**. It's because they do not store all the values in memory, **they generate the values on the fly**.

### iterator
Everything you can use "for...in..." on is an iterator: lists, strings, files... These iterables are handy because you can read them as much as you wish, but you store all the values in memory and it's not alwayss what you want when you have a lot of values. <br />
An iterator object that defines the method **next()** which accesses elements in the container one at a time. 
When there are no more elements, next() raises a **StopIteration** exception which tells the for loop to terminate. 

### for...in
The for statement calls **iter()** on the container object. The function returns an **iterator** object that defines the method **next()** which accesses elements in the container one at a time. When there are no more elements, next() raises a StopIteration exception which tells the for loop to terminate.


### example 斐波那契数列

假设我们现在有个一个求解斐波那契数列的函数fab(n)，我的测试用例如下：

{% highlight python%}
    >>> for n in fab(5): 
     ...     print n 
     ... 
     1 
     1 
     2 
     3 
     5 
{% endhighlight %}
我们用最最显而易见的方式实现第一个版本：
{% highlight python%}
    def fab_by_list(n):
        i, a, b = 0, 0, 1
        result = []

        while i < n:
            result.append(b)
            a, b = b, a+b
            i = i + 1

        return result
    fab = fab_by_list
{% endhighlight %}

测试一下：<br />
`for i in fab(1):print i` <br />
`for i in fab(5):print i` <br />
`for i in fab(100):print i` <br />
嗯，运行结果正确，性能十分好，收工。

既然for...in...的调用过程是先对container执行iter()，然后next()，那么使用oop的方式也可以实现，并且输入结果也没有异常，但是不支持多次迭代，需要添加reset函数支持。
{% highlight python %}
    class Fab(object):-

    def __init__(self, max):-
        self.max = max-
        self.n, self.a, self.b = 0, 0, 1-

    def __iter__(self):-
        return self-

    def next(self):-
        if self.n < self.max:-
            r = self.b-
            self.a, self.b = self.b, self.a + self.b-
            self.n = self.n + 1-
            return r-
        raise StopIteration()
{% endhighlight %}

`l = fab(500000)` <br />
我艹，谁手贱，怎么这么慢，慢，慢,看来代码必须要优化了。

尝试yield
{% highlight python %}
    def fab_by_yield(n):
        i, a, b = 0, 0, 1

        while i < n:
            yield b
            a, b = b, a+b
            i = i + 1

        return
    fab = fab_by_yield
{% endhighlight %}
测试一下：<br />
`for i in fab(1):print i` <br />
`for i in fab(5):print i` <br />
`for i in fab(100):print i` <br />
嗯，运行结果正确，性能十分好。 <br />
再试试手贱的测试：`l = fab(500000)`，:-O，秒杀。

简单地讲，yield 的作用就是把一个函数变成一个 generator，带有 yield 的函数不再是一个普通函数，Python 解释器会将其视为一个 generator，调用 fab(5) 不会执行 fab 函数，而是返回一个 iterable 对象！在 for 循环执行时，每次循环都会执行 fab 函数内部的代码，执行到 yield b 时，fab 函数就返回一个迭代值，下次迭代时，代码从 yield b 的下一条语句继续执行，而函数的本地变量看起来和上次中断执行前是完全一样的，于是函数继续执行，直到再次遇到 yield。
也可以手动调用 fab(5) 的 next() 方法（因为 fab(5) 是一个 generator 对象，该对象具有 next() 方法），这样我们就可以更清楚地看到 fab 的执行流程：

{% highlight python %}
    >>> f = fab(5) 
    >>> f.next() 
    1 
    >>> f.next() 
    1 
    >>> f.next() 
    2 
    >>> f.next() 
    3 
    >>> f.next() 
    5 
    >>> f.next() 
    Traceback (most recent call last): 
     File "<stdin>", line 1, in <module> 
    StopIteration 
{% endhighlight %}

一个带有 yield 的函数就是一个 generator，它和普通函数不同，生成一个 generator 看起来像函数调用，但不会执行任何函数代码，直到对其调用 next()（在 for 循环中会自动调用 next()）才开始执行。虽然执行流程仍按函数的流程执行，但每执行到一个 yield 语句就会中断，并返回一个迭代值，下次执行时从 yield 的下一个语句继续执行。看起来就好像一个函数在正常执行的过程中被 yield 中断了数次，每次中断都会通过 yield 返回当前的迭代值。
yield 的好处是显而易见的，把一个函数改写为一个 generator 就获得了迭代能力，比起用类的实例保存状态来计算下一个 next() 的值，不仅代码简洁，而且执行流程异常清晰。
如何判断一个函数是否是一个特殊的 generator 函数？可以利用 isgeneratorfunction 判断：

{% highlight python %}
    >>> from inspect import isgeneratorfunction 
    >>> isgeneratorfunction(fab) 
    True 

    >>> import types 
    >>> isinstance(fab, types.GeneratorType) 
    False 
    >>> isinstance(fab(5), types.GeneratorType) 
    True 

    >>> from collections import Iterable 
    >>> isinstance(fab, Iterable) 
    False 
    >>> isinstance(fab(5), Iterable) 
    True 
{% endhighlight %}

#### exception
>`Python SyntaxError: (“'return' with argument inside generator”,)`
You cannot use return with a value to exit a generator. You need to use yield plus a return without an expression.

#### 应用场景
对于读取大文件，在不可预估内存占用量的情况下，最好利用固定长度的缓冲区来不断读取文件内容，通过 yield，我们不再需要编写读文件的迭代类，就可以轻松实现文件读取：
{% highlight python %}
   def read_file(fpath): 
    BLOCK_SIZE = 1024 
    with open(fpath, 'rb') as f: 
        while True: 
            block = f.read(BLOCK_SIZE) 
            if block: 
                yield block 
            else: 
                return  
{% endhighlight %}

---
\[参考资料\] <br />
[\[The Python yield keyword explained\]](http://stackoverflow.com/questions/231767/the-python-yield-keyword-explained) <br />
[\[Python yield 使用浅析\]](http://www.ibm.com/developerworks/cn/opensource/os-cn-python-yield/) <br />
[\[return with argument inside generator)\]](http://stackoverflow.com/questions/15809296/python-syntaxerror-return-with-argument-inside-generator) <br />
[\[python doc for yield\]](http://docs.python.org/2/reference/expressions.html#grammar-token-yield_atom)
