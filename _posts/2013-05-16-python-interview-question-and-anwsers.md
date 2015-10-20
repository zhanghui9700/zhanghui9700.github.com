---
layout: post
title: python interview question and answers
category: python
tags: [python]
---


最近在招人，招聘pythonista, 和我们一起搞openstack，所以想找几个能考察大家基础的小题目聊聊天，谈谈理想和人生，结果有篇[blog](http://ilian.i-n-i.org/python-interview-question-and-answers/)让人眼前一亮，转来让大家看一看，特别是那些在简历上动辄就精通ABC的同学真该回家面壁思考人生去了。

---
For the last few weeks I have been interviewing several people for Python/Django developers so I thought that it might be helpful to show the questions I am asking together with the answers. The reason is … OK, let me tell you a story first.
I remember when one of my university professors introduced to us his professor – the one who thought him. It was a really short visit but I still remember one if the things he said. “Ignorance is not bad, the bad thing is when you do no want to learn.”
So back to the reason – if you have at least taken care to prepare for the interview, look for a standard questions and their answers and learn them this is a good start. Answering these question may not get you the job you are applying for but learning them will give you some valuable knowledge about Python.
This post will include the questions that are Python specific and I’ll post the Django question separately.

##### 1.How are arguments passed – by reference of by value?
The short answer is “neither”, actually it is called “call by object” or “call by sharing”(you can check [here](http://effbot.org/zone/call-by-object.htm) for more info). The longer one starts with the fact that this terminology is probably not the best one to describe how Python works. In Python everything is an object and all variables hold references to objects. The values of these references are to the functions. As result you can not change the value of the reference but you can modify the object if it is mutable. Remember numbers, strings and tuples are immutable, list and dicts are mutable.

>May be more clear answer will be something like this (there is no short answer): <br />
>Python works differently compared to other languages and there is no such a thing like passing an argument by reference or by value. If we want to compare it it will be closer to passing by reference because the object is not copied into memory instead a new name is assigned to it. I say closer and this does not mean exact because in other languages where you can pass an argument by reference, you can modify the value. In Python you also have the ability to modify the passed object but only if it is mutable type (like lists, dicts, sets, etc.). If the type of the passed object is string or int or tuple or some other kind of immutable type you can not modify it in the function.

##### 2.Do you know what list and dict comprehensions are? Can you give an example?
List/Dict comprehensions are syntax constructions to ease the creation of a list/dict based on existing iterable. According to the 3rd edition of “Learning Python” list comprehensions are generally faster than normal loops but this is something that may change between releases. Examples:
{% highlight python %}
# simple iteration
a = []
for x in range(10):
    a.append(x*2)
# a == [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
 
# list comprehension
a = [x*2 for x in range(10)]
 
# dict comprehension
a = {x: x*2 for x in range(10)}
# a == {0: 0, 1: 2, 2: 4, 3: 6, 4: 8, 5: 10, 6: 12, 7: 14, 8: 16, 9: 18}
{% endhighlight %}

##### 3.What is PEP 8?
PEP 8 is a coding convention(a set of recommendations) how to write your Python code in order to make it more readable and useful for those after you. For more information check [PEP 8](http://www.python.org/dev/peps/pep-0008/).

##### 4.Do you use virtual environments?
I personally and most(by my observation) of the Python developers find the [virtual environment](https://pypi.python.org/pypi/virtualenv) tool extremely useful. Yeah, probably you can live without it but this will make the work and support of multiple projects that requires different package versions a living hell.

##### 5.Can you sum all of the elements in the list, how about to multuply them and get the result?
{% highlight python %}
# the basic way
s = 0
for x in range(10):
    s += x
 
# the right way
s = sum(range(10))
 
 
# the basic way
s = 1
for x in range(1, 10):
    s = s * x
 
# the other way, this cool!!!
from operator import mul
reduce(mul, range(1, 10))
{% endhighlight %}
As for the last example, I know Guido van Rossum is not a fan of reduce, more info [here](http://www.artima.com/weblogs/viewpost.jsp?thread=98196), but still for some simple tasks reduce can come quite handy.

##### 6.Do you know what is the difference between lists and tuples? Can you give me an example for their usage?
First list are mutable while tuples are not, and second tuples can be hashed e.g. to be used as keys for dictionaries. As an example of their usage, tuples are used when the order of the elements in the sequence matters e.g. a geographic coordinates, “list” of points in a path or route, or set of actions that should be executed in specific order. Don’t forget that you can use them a dictionary keys. For everything else use lists.

##### 7.Do you know the difference between range and xrange?
Range returns a list while xrange returns a generator xrange object which takes the same memory no matter of the range size. In the first case you have all items already generated(this can take a lot of time and memory) while in the second you get the elements one by one e.g. only one element is generated and available per iteration. Simple example of generator usage can be find in the [problem 2 of the “homework”](http://ilian.i-n-i.org/functions-in-python-homework/) for my presentation [Functions in Python](http://ilian.i-n-i.org/functions-in-python-presentation/).
>Just doing my duty by noting that xrange is NOT a generator: <br />
> xrange can be indexed (generators cannot) <br />
> xrange has no next method! It is iterable but not an iterator. <br />
> Because of the previous item, xrange objects can be iterated over multiple times (generators cannot) <br />

##### 8.Tell me a few differences between Python 2.x and 3.x
There are many answers here but for me some of the major changes in Python 3.x are: all strings are now Unicode, print is now function not a statement. There is no range, it has been replaced by xrange which is removed. All classes are new style and the division of integers now returns float.

##### 9.What are decorators and what is their usage?
According to Bruce Eckel’s [Introduction to Python Decorators](http://www.artima.com/weblogs/viewpost.jsp?thread=240808) “Decorators allow you to inject or modify code in functions or classes”. In other words decorators allow you to wrap a function or class method call and execute some code before or after the execution of the original code. And also you can nest them e.g. to use more than one decorator for a specific function. Usage examples include – logging the calls to specific method, checking for permission(s), checking and/or modifying the arguments passed to the method etc.

##### 10.The with statement and its usage.
In a few words the with statement allows you to executed code before and/or after a specific set of operations. For example if you open a file for reading and parsing no matter what happens during the parsing you want to be sure that at the end the file is closed. This is normally achieved using the try… finally construction but the with statement simplifies it usin the so called “context management protocol”. To use it with your own objects you just have to define **__enter__** and **__exit__** methods. Some standard objects like the file object automatically support this protocol. For more information you may check [Understanding Python’s “with” statement](http://effbot.org/zone/python-with-statement.htm).

---
