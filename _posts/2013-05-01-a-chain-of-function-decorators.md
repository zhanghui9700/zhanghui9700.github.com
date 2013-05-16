---
layout: post
category: python
title: a chain of function decorators
tags: [python, decorator]
---

{% include JB/setup %}

### Question:
>How can I make two decorators in Python that would do the following.

{% highlight python %}
    @makebold
    @makeitalic
    def say():
       return "Hello"
{% endhighlight %}

>which should return

   `<b><i>Hello</i></b>`

### Anwser A:


{% highlight python %}
    #!/usr/bin/env python
    #-*-coding=utf-8-*-

    def makeblod(func):
        def wrap():
            return "<b>" + func() + "</b>"
        return wrap

    def makeitalic(func):
        def wrap():
            return "<i>" + func() + "</i>"
        return wrap

    @makeblod
    @makeitalic
    def say():
        return "Hello"

    print say()

    # This is the exact equivalent to 
    def say():
        return "hello"
    say = makebold(makeitalic(say))
{% endhighlight %}

### Anwser B:

{% highlight python %}
    #!/usr/bin/env python
    #-*-coding=utf-8-*-

    def makehtml(tag=None):
        def wrap(func):
            def wrapped(*args, **kwargs):
                return "<%s>" % tag + func() + "</%s>" % tag
            return wrapped
        return wrap

    @makehtml("html")
    @makehtml("body")
    @makehtml("h1")
    def say():
        return "Hello"

    print say()
    print say
{% endhighlight %}

### Anwser C:

{% highlight python %}
    #!/usr/bin/env python
    #-*-coding=utf-8-*-

    from functools import wraps

    def makehtml(tag=None):
        def wrap(func):
            @wraps(func)
            def wrapped(*args, **kwargs):
                return "<%s>" % tag + func() + "</%s>" % tag
            return wrapped
        return wrap

    @makehtml("html")
    @makehtml("body")
    @makehtml("h1")
    def say():
        return "Hello"

    print say()
    print say
{% endhighlight %}

---
\[stackoverflow.com top voted python questions\] <br />
\[1\][how can i make a chain of function decorators](http://stackoverflow.com/questions/739654/how-can-i-make-a-chain-of-function-decorators-in-python) <br />
\[2\][functools.wraps](http://docs.python.org/library/functools.html#functools.wraps)
